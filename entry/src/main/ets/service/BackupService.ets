import { picker } from '@kit.CoreFileKit';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { relationalStore } from '@kit.ArkData';
import { Book, Budget, Category, CategoryGroup, Member, Txn, TxnFilter } from '../models/Entities';
import { BookDao } from '../data/db/BookDao';
import { BudgetDao } from '../data/db/BudgetDao';
import { CategoryDao } from '../data/db/CategoryDao';
import { MemberDao } from '../data/db/MemberDao';
import { TxnDao } from '../data/db/TxnDao';
import { DbManager } from '../data/db/DbManager';
import { BackupCounts, BackupDocument, BackupFormat, BackupLine } from './BackupFormat';
import { CryptoUtil } from '../utils/CryptoUtil';
import { CsvFormat } from './CsvFormat';
import { SettingsService } from './SettingsService';
import { UiStore } from '../state/UiStore';
import { PrivateBookService } from './PrivateBookService';

const BACKUP_ITERATIONS: number = 10000;
const APP_VERSION: string = '1.0.0';

export class PrivatePrompt {
  bookId: string = '';
  name: string = '';
}

export class RestoreSummary {
  createdAt: number = 0;
  books: number = 0;
  members: number = 0;
  categories: number = 0;
  txns: number = 0;
  budgets: number = 0;
  prompts: PrivatePrompt[] = [];
}

class ParsedBackup {
  books: Book[] = [];
  members: Member[] = [];
  groups: CategoryGroup[] = [];
  categories: Category[] = [];
  txns: Txn[] = [];
  budgets: Budget[] = [];
}

export class BackupService {
  static async exportToFile(context: Context, passwords: Record<string, string>): Promise<number> {
    const text: string = await BackupService.buildText(passwords);
    const timestamp: number = Date.now();
    const fileName: string = 'MoreMoney_'.concat(CsvFormat.dateText(timestamp).replace(/-/g, ''))
      .concat('_').concat(CsvFormat.timeText(timestamp).replace(':', '')).concat('.mmbk');
    const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
    const options: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
    options.newFileNames = [fileName];
    const uris: string[] = await documentPicker.save(options);
    if (uris.length === 0) {
      return -1;
    }
    const file = fileIo.openSync(uris[0], fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
    try {
      fileIo.writeSync(file.fd, new util.TextEncoder().encodeInto(text).buffer);
    } finally {
      fileIo.closeSync(file);
    }
    const doc: BackupDocument = BackupFormat.parse(text);
    await SettingsService.setLastBackup(timestamp, fileName);
    return doc.counts.txns;
  }

  static async buildText(passwords: Record<string, string>): Promise<string> {
    const books: Book[] = await BookDao.list();
    const members: Member[] = await MemberDao.list();
    const groups: CategoryGroup[] = await CategoryDao.listGroups();
    const categories: Category[] = [];
    for (const group of groups) {
      const list: Category[] = await CategoryDao.listByGroup(group.id);
      for (const category of list) {
        categories.push(category);
      }
    }
    const budgets: Budget[] = await BudgetDao.listAll();
    const filter: TxnFilter = new TxnFilter();
    const txns: Txn[] = await TxnDao.listRange(filter);
    const lines: BackupLine[] = [];
    for (const book of books) {
      lines.push(BackupService.bookLine(book));
    }
    for (const member of members) {
      lines.push(BackupService.memberLine(member));
    }
    for (const group of groups) {
      const line: BackupLine = new BackupLine();
      line.type = 'GROUP';
      line.cells = [BackupService.enc(group.id), BackupService.enc(group.name), group.sort.toString(),
        group.isSystem ? '1' : '0'];
      lines.push(line);
    }
    for (const category of categories) {
      const line: BackupLine = new BackupLine();
      line.type = 'CATEGORY';
      line.cells = [BackupService.enc(category.id), BackupService.enc(category.groupId),
        BackupService.enc(category.name), BackupService.enc(category.icon), BackupService.enc(category.color),
        BackupService.enc(category.pinyin), category.sort.toString(), category.archived ? '1' : '0',
        category.createdAt.toString()];
      lines.push(line);
    }
    for (const txn of txns) {
      if (!BackupService.isPrivateBook(books, txn.bookId)) {
        lines.push(BackupService.txnLine(txn));
      }
    }
    for (const budget of budgets) {
      const line: BackupLine = new BackupLine();
      line.type = 'BUDGET';
      line.cells = [BackupService.enc(budget.id), BackupService.enc(budget.bookId),
        BackupService.enc(budget.period), budget.amountCents.toString(), budget.updatedAt.toString()];
      lines.push(line);
    }
    let privateCount: number = 0;
    for (const book of books) {
      if (!book.isPrivate) {
        continue;
      }
      const own: Txn[] = txns.filter((txn: Txn): boolean => txn.bookId === book.id);
      if (own.length === 0) {
        continue;
      }
      const password: string | undefined = passwords[book.id];
      if (password === undefined || password.length === 0) {
        throw new Error('需要输入私密账本「'.concat(book.name).concat('」的密码'));
      }
      const valid: boolean = await PrivateBookService.verify(book.id, password);
      if (!valid) {
        throw new Error('私密账本「'.concat(book.name).concat('」密码错误'));
      }
      const text: string = BackupService.txnLinesText(own);
      const salt: Uint8Array = CryptoUtil.randomBytes(16);
      const key: Uint8Array = await CryptoUtil.deriveKey(password, salt, BACKUP_ITERATIONS);
      const encrypted = await CryptoUtil.aesGcmEncrypt(key, CryptoUtil.utf8(text));
      const line: BackupLine = new BackupLine();
      line.type = 'PRIVATE';
      line.cells = [BackupService.enc(book.id), CryptoUtil.base64(salt), CryptoUtil.base64(encrypted.iv),
        CryptoUtil.base64(encrypted.tag), CryptoUtil.base64(encrypted.cipher)];
      lines.push(line);
      privateCount += 1;
    }
    const body: string = BackupFormat.buildBody(lines);
    const checksum: string = await CryptoUtil.sha256(body);
    const counts: BackupCounts = new BackupCounts();
    counts.books = books.length;
    counts.members = members.length;
    counts.categories = categories.length;
    counts.txns = txns.length;
    counts.budgets = budgets.length;
    counts.privateBooks = privateCount;
    return BackupFormat.wrap(body, checksum, counts, Date.now(), APP_VERSION);
  }

  static async pickAndParse(context: Context): Promise<BackupDocument | null> {
    const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
    const options: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
    options.maxSelectNumber = 1;
    options.fileSuffixFilters = ['.mmbk'];
    const uris: string[] = await documentPicker.select(options);
    if (uris.length === 0) {
      return null;
    }
    const text: string = fileIo.readTextSync(uris[0]);
    const doc: BackupDocument = BackupFormat.parse(text);
    const actual: string = await CryptoUtil.sha256(doc.body);
    if (actual !== doc.checksum) {
      throw new Error('备份文件已损坏或被修改');
    }
    return doc;
  }

  static summary(doc: BackupDocument): RestoreSummary {
    const summary: RestoreSummary = new RestoreSummary();
    summary.createdAt = doc.createdAt;
    summary.books = doc.counts.books;
    summary.members = doc.counts.members;
    summary.categories = doc.counts.categories;
    summary.txns = doc.counts.txns;
    summary.budgets = doc.counts.budgets;
    const names: Map<string, string> = new Map<string, string>();
    for (const line of doc.lines) {
      if (line.type !== 'BOOK' || line.cells.length < 13) {
        continue;
      }
      const id: string = BackupService.dec(line.cells[0]);
      names.set(id, BackupService.dec(line.cells[1]));
      const isPrivate: boolean = line.cells[4] === '1';
      if (isPrivate) {
        const prompt: PrivatePrompt = new PrivatePrompt();
        prompt.bookId = id;
        const stored: string | undefined = names.get(id);
        prompt.name = stored === undefined ? '' : stored;
        summary.prompts.push(prompt);
      }
    }
    return summary;
  }

  static async restore(doc: BackupDocument, passwords: Record<string, string>): Promise<number> {
    const actual: string = await CryptoUtil.sha256(doc.body);
    if (actual !== doc.checksum) {
      throw new Error('备份文件已损坏或被修改');
    }
    const parsed: ParsedBackup = await BackupService.parse(doc, passwords);
    if (parsed.books.length > 0) {
      const hasDefault: boolean = parsed.books.some((book: Book): boolean => book.isDefault);
      if (!hasDefault) {
        parsed.books[0].isDefault = true;
      }
    }
    const store: relationalStore.RdbStore = DbManager.store;
    const tx: relationalStore.Transaction = await store.createTransaction();
    try {
      await tx.execute('DELETE FROM txn');
      await tx.execute('DELETE FROM budget');
      await tx.execute('DELETE FROM category');
      await tx.execute('DELETE FROM category_group');
      await tx.execute('DELETE FROM member');
      await tx.execute('DELETE FROM book');
      for (const book of parsed.books) {
        await tx.execute(
          'INSERT OR REPLACE INTO book (id, name, icon, color, is_private, pwd_hash, pwd_salt, pwd_iter, ' +
            'is_default, sort, archived, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [book.id, book.name, book.icon, book.color, book.isPrivate ? 1 : 0, book.pwdHash, book.pwdSalt,
            book.pwdIter, book.isDefault ? 1 : 0, book.sort, book.archived ? 1 : 0, book.createdAt, book.updatedAt]
        );
      }
      for (const member of parsed.members) {
        await tx.execute(
          'INSERT OR REPLACE INTO member (id, name, initial, color, is_default, sort, archived) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [member.id, member.name, member.initial, member.color, member.isDefault ? 1 : 0, member.sort,
            member.archived ? 1 : 0]
        );
      }
      for (const group of parsed.groups) {
        await tx.execute(
          'INSERT OR REPLACE INTO category_group (id, name, sort, is_system) VALUES (?, ?, ?, ?)',
          [group.id, group.name, group.sort, group.isSystem ? 1 : 0]
        );
      }
      for (const category of parsed.categories) {
        await tx.execute(
          'INSERT OR REPLACE INTO category (id, group_id, name, icon, color, pinyin, sort, archived, created_at) ' +
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [category.id, category.groupId, category.name, category.icon, category.color, category.pinyin,
            category.sort, category.archived ? 1 : 0, category.createdAt]
        );
      }
      for (const txn of parsed.txns) {
        await tx.execute(
          'INSERT OR REPLACE INTO txn (id, book_id, category_id, member_id, amount_cents, occurred_at, day_key, ' +
            'note, created_at, updated_at, deleted_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)',
          [txn.id, txn.bookId, txn.categoryId, txn.memberId, txn.amountCents, txn.occurredAt, txn.dayKey,
            txn.note, txn.createdAt, txn.updatedAt]
        );
      }
      for (const budget of parsed.budgets) {
        await tx.execute(
          'INSERT OR REPLACE INTO budget (id, book_id, period, amount_cents, updated_at) VALUES (?, ?, ?, ?, ?)',
          [budget.id, budget.bookId, budget.period, budget.amountCents, budget.updatedAt]
        );
      }
      await tx.commit();
    } catch (error) {
      await tx.rollback();
      throw new Error('恢复失败，未写入任何数据');
    }
    UiStore.instance().lockAllPrivate();
    return parsed.txns.length;
  }

  private static async parse(doc: BackupDocument, passwords: Record<string, string>): Promise<ParsedBackup> {
    const parsed: ParsedBackup = new ParsedBackup();
    for (const line of doc.lines) {
      if (line.type === 'BOOK' && line.cells.length >= 13) {
        parsed.books.push(BackupService.readBook(line));
      } else if (line.type === 'MEMBER' && line.cells.length >= 7) {
        parsed.members.push(BackupService.readMember(line));
      } else if (line.type === 'GROUP' && line.cells.length >= 4) {
        parsed.groups.push(BackupService.readGroup(line));
      } else if (line.type === 'CATEGORY' && line.cells.length >= 9) {
        parsed.categories.push(BackupService.readCategory(line));
      } else if (line.type === 'TXN' && line.cells.length >= 10) {
        parsed.txns.push(BackupService.readTxn(line.cells));
      } else if (line.type === 'BUDGET' && line.cells.length >= 5) {
        parsed.budgets.push(BackupService.readBudget(line));
      } else if (line.type === 'PRIVATE' && line.cells.length >= 5) {
        const bookId: string = BackupService.dec(line.cells[0]);
        const password: string | undefined = passwords[bookId];
        if (password === undefined || password.length === 0) {
          throw new Error('需要输入私密账本密码');
        }
        const salt: Uint8Array = CryptoUtil.fromBase64(line.cells[1]);
        const iv: Uint8Array = CryptoUtil.fromBase64(line.cells[2]);
        const tag: Uint8Array = CryptoUtil.fromBase64(line.cells[3]);
        const cipher: Uint8Array = CryptoUtil.fromBase64(line.cells[4]);
        const key: Uint8Array = await CryptoUtil.deriveKey(password, salt, BACKUP_ITERATIONS);
        let text: string = '';
        try {
          const plain: Uint8Array = await CryptoUtil.aesGcmDecrypt(key, iv, cipher, tag);
          text = CryptoUtil.text(plain);
        } catch (error) {
          throw new Error('私密账本密码错误');
        }
        const txnLines: BackupLine[] = BackupFormat.parseBody(text);
        for (const txnLine of txnLines) {
          if (txnLine.type === 'TXN' && txnLine.cells.length >= 10) {
            parsed.txns.push(BackupService.readTxn(txnLine.cells));
          }
        }
      }
    }
    return parsed;
  }

  private static readBook(line: BackupLine): Book {
    const book: Book = {
      id: BackupService.dec(line.cells[0]),
      name: BackupService.dec(line.cells[1]),
      icon: BackupService.dec(line.cells[2]),
      color: BackupService.dec(line.cells[3]),
      isPrivate: line.cells[4] === '1',
      pwdHash: line.cells[5].length > 0 ? BackupService.dec(line.cells[5]) : null,
      pwdSalt: line.cells[6].length > 0 ? BackupService.dec(line.cells[6]) : null,
      pwdIter: Number(line.cells[7]),
      isDefault: line.cells[8] === '1',
      sort: Number(line.cells[9]),
      archived: line.cells[10] === '1',
      createdAt: Number(line.cells[11]),
      updatedAt: Number(line.cells[12])
    };
    return book;
  }

  private static readMember(line: BackupLine): Member {
    const member: Member = {
      id: BackupService.dec(line.cells[0]),
      name: BackupService.dec(line.cells[1]),
      initial: BackupService.dec(line.cells[2]),
      color: BackupService.dec(line.cells[3]),
      isDefault: line.cells[4] === '1',
      sort: Number(line.cells[5]),
      archived: line.cells[6] === '1'
    };
    return member;
  }

  private static readGroup(line: BackupLine): CategoryGroup {
    const group: CategoryGroup = {
      id: BackupService.dec(line.cells[0]),
      name: BackupService.dec(line.cells[1]),
      sort: Number(line.cells[2]),
      isSystem: line.cells[3] === '1'
    };
    return group;
  }

  private static readCategory(line: BackupLine): Category {
    const category: Category = {
      id: BackupService.dec(line.cells[0]),
      groupId: BackupService.dec(line.cells[1]),
      name: BackupService.dec(line.cells[2]),
      icon: BackupService.dec(line.cells[3]),
      color: BackupService.dec(line.cells[4]),
      pinyin: BackupService.dec(line.cells[5]),
      sort: Number(line.cells[6]),
      archived: line.cells[7] === '1',
      createdAt: Number(line.cells[8])
    };
    return category;
  }

  private static readTxn(cells: string[]): Txn {
    const txn: Txn = {
      id: BackupService.dec(cells[0]),
      bookId: BackupService.dec(cells[1]),
      categoryId: BackupService.dec(cells[2]),
      memberId: BackupService.dec(cells[3]),
      amountCents: Number(cells[4]),
      occurredAt: Number(cells[5]),
      dayKey: BackupService.dec(cells[6]),
      note: BackupService.dec(cells[7]),
      createdAt: Number(cells[8]),
      updatedAt: Number(cells[9]),
      deletedAt: null
    };
    return txn;
  }

  private static readBudget(line: BackupLine): Budget {
    const budget: Budget = {
      id: BackupService.dec(line.cells[0]),
      bookId: BackupService.dec(line.cells[1]),
      period: BackupService.normalizePeriod(BackupService.dec(line.cells[2])),
      amountCents: Number(line.cells[3]),
      updatedAt: Number(line.cells[4])
    };
    return budget;
  }

  private static normalizePeriod(raw: string): string {
    if (raw === 'week' || raw === 'month' || raw === 'year') {
      return raw;
    }
    if (raw.startsWith('W')) {
      return 'week';
    }
    if (raw.startsWith('Y')) {
      return 'year';
    }
    return 'month';
  }

  private static bookLine(book: Book): BackupLine {
    const line: BackupLine = new BackupLine();
    line.type = 'BOOK';
    line.cells = [BackupService.enc(book.id), BackupService.enc(book.name), BackupService.enc(book.icon),
      BackupService.enc(book.color), book.isPrivate ? '1' : '0',
      book.pwdHash === null ? '' : BackupService.enc(book.pwdHash),
      book.pwdSalt === null ? '' : BackupService.enc(book.pwdSalt),
      book.pwdIter.toString(), book.isDefault ? '1' : '0', book.sort.toString(), book.archived ? '1' : '0',
      book.createdAt.toString(), book.updatedAt.toString()];
    return line;
  }

  private static memberLine(member: Member): BackupLine {
    const line: BackupLine = new BackupLine();
    line.type = 'MEMBER';
    line.cells = [BackupService.enc(member.id), BackupService.enc(member.name), BackupService.enc(member.initial),
      BackupService.enc(member.color), member.isDefault ? '1' : '0', member.sort.toString(),
      member.archived ? '1' : '0'];
    return line;
  }

  private static txnLine(txn: Txn): BackupLine {
    const line: BackupLine = new BackupLine();
    line.type = 'TXN';
    line.cells = [BackupService.enc(txn.id), BackupService.enc(txn.bookId), BackupService.enc(txn.categoryId),
      BackupService.enc(txn.memberId), txn.amountCents.toString(), txn.occurredAt.toString(),
      BackupService.enc(txn.dayKey), BackupService.enc(txn.note), txn.createdAt.toString(),
      txn.updatedAt.toString()];
    return line;
  }

  private static txnLinesText(txns: Txn[]): string {
    const lines: string[] = [];
    for (const txn of txns) {
      lines.push(BackupFormat.buildBody([BackupService.txnLine(txn)]));
    }
    return lines.join('\n');
  }

  private static enc(text: string): string {
    return CryptoUtil.base64(CryptoUtil.utf8(text));
  }

  private static dec(text: string): string {
    if (text.length === 0) {
      return '';
    }
    return CryptoUtil.text(CryptoUtil.fromBase64(text));
  }

  private static isPrivateBook(books: Book[], bookId: string): boolean {
    for (const book of books) {
      if (book.id === bookId) {
        return book.isPrivate;
      }
    }
    return false;
  }

}
