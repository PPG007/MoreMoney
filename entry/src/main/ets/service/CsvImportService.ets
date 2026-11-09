import { relationalStore } from '@kit.ArkData';
import { Book, Category, CategoryGroup, Member, Txn } from '../models/Entities';
import { DbManager } from '../data/db/DbManager';
import { BookDao } from '../data/db/BookDao';
import { CategoryDao } from '../data/db/CategoryDao';
import { MemberDao } from '../data/db/MemberDao';
import { CsvParser, CsvRow, CsvSyntaxError } from './CsvParser';
import { CsvFormat } from './CsvFormat';
import { IdUtil } from '../utils/IdUtil';
import { pinyinKey } from '../utils/PinyinUtil';
import { PrivateBookService } from './PrivateBookService';
import { SeedColors } from '../theme/Palette';
import { DateUtil } from '../utils/DateUtil';

const MAX_BYTES: number = 5 * 1024 * 1024;
const MAX_ROWS: number = 20000;
const MAX_AMOUNT_CENTS: number = 9999999999;

export class ImportError {
  line: number = 0;
  message: string = '';
}

export class ImportPreview {
  total: number = 0;
  toInsert: number = 0;
  duplicates: number = 0;
  newBooks: string[] = [];
  newCategories: string[] = [];
  newMembers: string[] = [];
  errors: ImportError[] = [];
  rows: Txn[] = [];
  bookNames: string[] = [];
  groupNames: string[] = [];
  categoryNames: string[] = [];
  memberNames: string[] = [];
}

export class ImportResult {
  inserted: number = 0;
  skipped: number = 0;
}

class ExistingMaps {
  books: Map<string, string> = new Map<string, string>();
  groups: Map<string, string> = new Map<string, string>();
  categories: Map<string, string> = new Map<string, string>();
  members: Map<string, string> = new Map<string, string>();
  txnIds: Set<string> = new Set<string>();
}

export class CsvImportService {
  static async preview(text: string): Promise<ImportPreview> {
    const preview: ImportPreview = new ImportPreview();
    if (text.length > MAX_BYTES) {
      CsvImportService.addError(preview, 0, '文件超过 5MB 上限');
      return preview;
    }
    const clean: string = text.startsWith('\uFEFF') ? text.substring(1) : text;
    let parsed: CsvRow[] = [];
    try {
      parsed = CsvParser.parse(clean);
    } catch (error) {
      if (error instanceof CsvSyntaxError) {
        CsvImportService.addError(preview, error.line, error.message);
      } else {
        CsvImportService.addError(preview, 0, '文件解析失败');
      }
      return preview;
    }
    if (parsed.length === 0) {
      CsvImportService.addError(preview, 0, '文件为空');
      return preview;
    }
    const header: string = parsed[0].cells.join(',');
    if (header !== CsvFormat.header) {
      CsvImportService.addError(preview, parsed[0].lineNumber, '表头与模板不一致');
      return preview;
    }
    if (parsed.length - 1 > MAX_ROWS) {
      CsvImportService.addError(preview, 0, '超过 20000 行上限');
      return preview;
    }

    const maps: ExistingMaps = await CsvImportService.loadMaps();
    const locked: string[] = await PrivateBookService.lockedBookIds();
    const newBookSet: string[] = [];
    const newCategorySet: string[] = [];
    const newMemberSet: string[] = [];
    let duplicates: number = 0;

    for (let i = 1; i < parsed.length; i++) {
      const row: CsvRow = parsed[i];
      preview.total += 1;
      if (row.cells.length < 10) {
        CsvImportService.addError(preview, row.lineNumber, '字段数量不足');
        continue;
      }
      const date: string = row.cells[0].trim();
      const time: string = row.cells[1].trim();
      const type: string = row.cells[2].trim();
      const bookName: string = row.cells[3].trim();
      const groupName: string = row.cells[4].trim();
      const categoryName: string = row.cells[5].trim();
      const memberName: string = row.cells[6].trim();
      const amountText: string = row.cells[7].trim();
      const note: string = CsvImportService.unescapeNote(row.cells[8]);
      const rawId: string = row.cells[9].trim();

      let message: string = '';
      if (!CsvImportService.validDate(date)) {
        message = '日期格式不正确';
      } else if (!CsvImportService.validTime(time)) {
        message = '时间格式不正确';
      } else if (type !== 'expense') {
        message = 'type 必须为 expense';
      } else if (bookName.length === 0) {
        message = '账本不能为空';
      } else if (groupName.length === 0) {
        message = '分组不能为空';
      } else if (categoryName.length === 0) {
        message = '分类不能为空';
      } else if (memberName.length === 0) {
        message = '成员不能为空';
      } else if (note.length > 100) {
        message = '备注超过 100 字';
      }
      const amountCents: number = CsvImportService.parseAmount(amountText);
      if (message.length === 0 && amountCents < 0) {
        message = '金额格式不正确';
      }
      if (message.length === 0 && amountCents <= 0) {
        message = '金额需大于 0';
      }
      if (message.length === 0 && amountCents > MAX_AMOUNT_CENTS) {
        message = '金额超出上限';
      }
      if (message.length === 0) {
        const existingBook: string | undefined = maps.books.get(bookName);
        if (existingBook !== undefined && locked.indexOf(existingBook) >= 0) {
          message = '账本「'.concat(bookName).concat('」已锁定，请先解锁');
        }
      }
      if (message.length > 0) {
        CsvImportService.addError(preview, row.lineNumber, message);
        continue;
      }

      let id: string = rawId;
      if (id.length === 0) {
        id = IdUtil.next();
      } else if (maps.txnIds.has(id)) {
        duplicates += 1;
        continue;
      }
      maps.txnIds.add(id);

      const existingBookId: string | undefined = maps.books.get(bookName);
      if (existingBookId === undefined && newBookSet.indexOf(bookName) < 0) {
        newBookSet.push(bookName);
      }
      const existingCategoryId: string | undefined = maps.categories.get(categoryName);
      if (existingCategoryId === undefined && newCategorySet.indexOf(categoryName) < 0) {
        newCategorySet.push(categoryName);
      }
      const existingMemberId: string | undefined = maps.members.get(memberName);
      if (existingMemberId === undefined && newMemberSet.indexOf(memberName) < 0) {
        newMemberSet.push(memberName);
      }

      const txn: Txn = {
        id: id,
        bookId: existingBookId === undefined ? '' : existingBookId,
        categoryId: existingCategoryId === undefined ? '' : existingCategoryId,
        memberId: existingMemberId === undefined ? '' : existingMemberId,
        amountCents: amountCents,
        occurredAt: CsvImportService.occurredAt(date, time),
        dayKey: date,
        note: note,
        createdAt: Date.now(),
        updatedAt: Date.now(),
        deletedAt: null
      };
      preview.rows.push(txn);
      preview.bookNames.push(bookName);
      preview.groupNames.push(groupName);
      preview.categoryNames.push(categoryName);
      preview.memberNames.push(memberName);
    }

    preview.duplicates = duplicates;
    preview.toInsert = preview.rows.length;
    preview.newBooks = newBookSet;
    preview.newCategories = newCategorySet;
    preview.newMembers = newMemberSet;
    return preview;
  }

  static async execute(preview: ImportPreview): Promise<ImportResult> {
    if (preview.errors.length > 0) {
      throw new Error('存在校验错误，未写入任何数据');
    }
    const store: relationalStore.RdbStore = DbManager.store;
    const tx: relationalStore.Transaction = await store.createTransaction();
    const result: ImportResult = new ImportResult();
    result.skipped = preview.duplicates;
    try {
      const maps: ExistingMaps = await CsvImportService.loadMaps();
      const now: number = Date.now();
      const books: Book[] = await BookDao.list();
      const groups: CategoryGroup[] = await CategoryDao.listGroups();
      const members: Member[] = await MemberDao.list();
      let bookSort: number = books.length;
      let groupSort: number = groups.length;
      let memberSort: number = members.length;
      let colorIndex: number = books.length + members.length;

      for (const name of preview.newBooks) {
        const id: string = 'book_'.concat(IdUtil.next());
        await tx.execute(
          'INSERT INTO book (id, name, icon, color, is_private, pwd_hash, pwd_salt, pwd_iter, is_default, ' +
            'sort, archived, created_at, updated_at) VALUES (?, ?, ?, ?, 0, NULL, NULL, 10000, 0, ?, 0, ?, ?)',
          [id, name, 'ic_book_daily', SeedColors.c1, bookSort, now, now]
        );
        maps.books.set(name, id);
        bookSort += 1;
      }

      for (const name of preview.groupNames) {
        if (maps.groups.get(name) === undefined) {
          const id: string = 'group_'.concat(IdUtil.next());
          await tx.execute(
            'INSERT INTO category_group (id, name, sort, is_system) VALUES (?, ?, ?, 0)',
            [id, name, groupSort]
          );
          maps.groups.set(name, id);
          groupSort += 1;
        }
      }

      for (let i = 0; i < preview.newCategories.length; i++) {
        const name: string = preview.newCategories[i];
        const groupName: string = CsvImportService.groupForCategory(preview, name);
        let groupId: string | undefined = maps.groups.get(groupName);
        if (groupId === undefined) {
          const id: string = 'group_'.concat(IdUtil.next());
          await tx.execute(
            'INSERT INTO category_group (id, name, sort, is_system) VALUES (?, ?, ?, 0)',
            [id, groupName, groupSort]
          );
          maps.groups.set(groupName, id);
          groupId = id;
          groupSort += 1;
        }
        const id: string = 'cat_'.concat(IdUtil.next());
        const color: string = CsvImportService.colorAt(colorIndex);
        await tx.execute(
          'INSERT INTO category (id, group_id, name, icon, color, pinyin, sort, archived, created_at) ' +
            'VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?)',
          [id, groupId, name, 'ic_cat_other', color, pinyinKey(name), i, now]
        );
        maps.categories.set(name, id);
        colorIndex += 1;
      }

      for (const name of preview.newMembers) {
        const id: string = 'member_'.concat(IdUtil.next());
        const color: string = CsvImportService.colorAt(colorIndex);
        await tx.execute(
          'INSERT INTO member (id, name, initial, color, is_default, sort, archived) VALUES (?, ?, ?, ?, 0, ?, 0)',
          [id, name, name.substring(0, 1), color, memberSort]
        );
        maps.members.set(name, id);
        memberSort += 1;
        colorIndex += 1;
      }

      for (let i = 0; i < preview.rows.length; i++) {
        const row: Txn = preview.rows[i];
        const bookId: string | undefined = maps.books.get(preview.bookNames[i]);
        const categoryId: string | undefined = maps.categories.get(preview.categoryNames[i]);
        const memberId: string | undefined = maps.members.get(preview.memberNames[i]);
        if (bookId === undefined || categoryId === undefined || memberId === undefined) {
          throw new Error('自动创建实体失败');
        }
        await tx.execute(
          'INSERT INTO txn (id, book_id, category_id, member_id, amount_cents, occurred_at, day_key, note, ' +
            'created_at, updated_at, deleted_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)',
          [row.id, bookId, categoryId, memberId, row.amountCents, row.occurredAt, row.dayKey, row.note,
            row.createdAt, row.updatedAt]
        );
        result.inserted += 1;
      }
      await tx.commit();
    } catch (error) {
      await tx.rollback();
      throw new Error('导入失败，未写入任何数据');
    }
    return result;
  }

  private static groupForCategory(preview: ImportPreview, categoryName: string): string {
    for (let i = 0; i < preview.categoryNames.length; i++) {
      if (preview.categoryNames[i] === categoryName) {
        return preview.groupNames[i];
      }
    }
    return '其他';
  }

  private static colorAt(index: number): string {
    const colors: string[] = [SeedColors.c1, SeedColors.c2, SeedColors.c3, SeedColors.c4, SeedColors.c5,
      SeedColors.c6, SeedColors.c7, SeedColors.c8, SeedColors.neutral];
    return colors[index % colors.length];
  }

  private static async loadMaps(): Promise<ExistingMaps> {
    const maps: ExistingMaps = new ExistingMaps();
    const books: Book[] = await BookDao.list();
    for (const book of books) {
      maps.books.set(book.name, book.id);
    }
    const groups: CategoryGroup[] = await CategoryDao.listGroups();
    for (const group of groups) {
      maps.groups.set(group.name, group.id);
      const categories: Category[] = await CategoryDao.listByGroup(group.id);
      for (const category of categories) {
        if (!maps.categories.has(category.name)) {
          maps.categories.set(category.name, category.id);
        }
      }
    }
    const members: Member[] = await MemberDao.list();
    for (const member of members) {
      maps.members.set(member.name, member.id);
    }
    const rs: relationalStore.ResultSet = await DbManager.store.querySql('SELECT id FROM txn');
    try {
      while (rs.goToNextRow()) {
        maps.txnIds.add(rs.getString(rs.getColumnIndex('id')));
      }
    } finally {
      rs.close();
    }
    return maps;
  }

  private static addError(preview: ImportPreview, line: number, message: string): void {
    const error: ImportError = new ImportError();
    error.line = line;
    error.message = message;
    preview.errors.push(error);
  }

  private static validDate(text: string): boolean {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(text)) {
      return false;
    }
    const parts: string[] = text.split('-');
    const year: number = Number(parts[0]);
    const month: number = Number(parts[1]);
    const day: number = Number(parts[2]);
    if (month < 1 || month > 12 || day < 1) {
      return false;
    }
    return day <= DateUtil.daysInMonth(year, month);
  }

  private static validTime(text: string): boolean {
    if (!/^\d{2}:\d{2}$/.test(text)) {
      return false;
    }
    const parts: string[] = text.split(':');
    const hour: number = Number(parts[0]);
    const minute: number = Number(parts[1]);
    return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
  }

  private static occurredAt(date: string, time: string): number {
    const dateParts: string[] = date.split('-');
    const timeParts: string[] = time.split(':');
    return new Date(Number(dateParts[0]), Number(dateParts[1]) - 1, Number(dateParts[2]),
      Number(timeParts[0]), Number(timeParts[1]), 0, 0).getTime();
  }

  private static parseAmount(text: string): number {
    if (!/^\d+(\.\d{1,2})?$/.test(text)) {
      return -1;
    }
    const parts: string[] = text.split('.');
    const yuan: number = Number(parts[0]);
    if (Number.isNaN(yuan)) {
      return -1;
    }
    let cents: number = 0;
    if (parts.length > 1) {
      cents = Number(parts[1].padEnd(2, '0'));
    }
    return yuan * 100 + cents;
  }

  private static unescapeNote(note: string): string {
    if (note.length >= 2 && note.substring(0, 1) === '\'') {
      const second: string = note.substring(1, 2);
      if (second === '=' || second === '+' || second === '-' || second === '@') {
        return note.substring(1);
      }
    }
    return note;
  }
}
