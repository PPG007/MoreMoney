import { picker } from '@kit.CoreFileKit';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { Book, Category, CategoryGroup, Member, Txn, TxnFilter } from '../models/Entities';
import { BookDao } from '../data/db/BookDao';
import { CategoryDao } from '../data/db/CategoryDao';
import { MemberDao } from '../data/db/MemberDao';
import { TxnDao } from '../data/db/TxnDao';
import { CsvExportRow, CsvFormat } from './CsvFormat';

class NameMaps {
  books: Map<string, string> = new Map<string, string>();
  groups: Map<string, string> = new Map<string, string>();
  categories: Map<string, Category> = new Map<string, Category>();
  members: Map<string, string> = new Map<string, string>();
}

export class CsvExportService {
  private static async loadNames(): Promise<NameMaps> {
    const maps: NameMaps = new NameMaps();
    const books: Book[] = await BookDao.list();
    for (const book of books) {
      maps.books.set(book.id, book.name);
    }
    const groups: CategoryGroup[] = await CategoryDao.listGroups();
    for (const group of groups) {
      maps.groups.set(group.id, group.name);
      const categories: Category[] = await CategoryDao.listByGroup(group.id);
      for (const category of categories) {
        maps.categories.set(category.id, category);
      }
    }
    const members: Member[] = await MemberDao.list();
    for (const member of members) {
      maps.members.set(member.id, member.name);
    }
    return maps;
  }

  static async prepareRows(filter: TxnFilter, excludeBookIds: string[]): Promise<CsvExportRow[]> {
    const maps: NameMaps = await CsvExportService.loadNames();
    const txns: Txn[] = await TxnDao.listRange(filter);
    const sorted: Txn[] = txns.filter(
      (txn: Txn): boolean => excludeBookIds.indexOf(txn.bookId) < 0
    );
    sorted.sort((a: Txn, b: Txn): number => a.occurredAt - b.occurredAt);
    const rows: CsvExportRow[] = [];
    for (const txn of sorted) {
      const row: CsvExportRow = new CsvExportRow();
      row.date = CsvFormat.dateText(txn.occurredAt);
      row.time = CsvFormat.timeText(txn.occurredAt);
      row.type = 'expense';
      const bookName: string | undefined = maps.books.get(txn.bookId);
      row.book = bookName === undefined ? '' : bookName;
      const category: Category | undefined = maps.categories.get(txn.categoryId);
      row.category = category === undefined ? '' : category.name;
      const groupName: string | undefined = category === undefined ? undefined : maps.groups.get(category.groupId);
      row.group = groupName === undefined ? '' : groupName;
      const memberName: string | undefined = maps.members.get(txn.memberId);
      row.member = memberName === undefined ? '' : memberName;
      row.amount = CsvFormat.formatAmount(txn.amountCents);
      row.note = txn.note;
      row.id = txn.id;
      rows.push(row);
    }
    return rows;
  }

  static async estimate(filter: TxnFilter, excludeBookIds: string[]): Promise<number> {
    const rows: CsvExportRow[] = await CsvExportService.prepareRows(filter, excludeBookIds);
    return rows.length;
  }

  static async exportCsv(context: Context, filter: TxnFilter, excludeBookIds: string[]): Promise<number> {
    const rows: CsvExportRow[] = await CsvExportService.prepareRows(filter, excludeBookIds);
    if (rows.length === 0) {
      throw new Error('没有可导出的记录');
    }
    const text: string = CsvFormat.build(rows);
    const bytes: Uint8Array = new util.TextEncoder().encodeInto(text);
    const fileName: string = CsvFormat.fileName(Date.now());
    const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
    const options: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
    options.newFileNames = [fileName];
    const uris: string[] = await documentPicker.save(options);
    if (uris.length === 0) {
      return -1;
    }
    const file = fileIo.openSync(uris[0], fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
    try {
      fileIo.writeSync(file.fd, bytes.buffer);
    } finally {
      fileIo.closeSync(file);
    }
    return rows.length;
  }
}
