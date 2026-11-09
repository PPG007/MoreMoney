import { relationalStore } from '@kit.ArkData';
import { Category, Member } from '../models/Entities';
import { DbManager } from '../data/db/DbManager';

export class DebugSeedService {
  static readonly demoBookDaily: string = 'demo_book_daily';
  static readonly demoBookTravel: string = 'demo_book_travel';
  static readonly demoBookFamily: string = 'demo_book_family';
  static readonly demoBookRepair: string = 'demo_book_repair';

  static async seedDemo(context: Context): Promise<void> {
    if (!context.applicationInfo.debug) {
      return;
    }
    await DbManager.init(context);
    const store: relationalStore.RdbStore = DbManager.store;
    await store.executeSql('DELETE FROM txn');
    await store.executeSql('DELETE FROM budget');
    await store.executeSql('DELETE FROM book');
    await DebugSeedService.insertBooks(store);
    await DebugSeedService.insertBudgets(store);
    await DebugSeedService.insertTxns(store);
  }

  private static async insertBooks(store: relationalStore.RdbStore): Promise<void> {
    const now: number = Date.now();
    await DebugSeedService.insertBook(store, DebugSeedService.demoBookDaily, '日常账本', 'ic_book_daily',
      '#2A78D6', 0, 1, 0, now);
    await DebugSeedService.insertBook(store, DebugSeedService.demoBookTravel, '旅行', 'ic_book_travel',
      '#EB6834', 0, 0, 1, now);
    await DebugSeedService.insertBook(store, DebugSeedService.demoBookFamily, '家庭', 'ic_book_family',
      '#6250D6', 1, 0, 2, now);
    await DebugSeedService.insertBook(store, DebugSeedService.demoBookRepair, '装修', 'ic_book_repair',
      '#1BAF7A', 0, 0, 3, now);
  }

  private static async insertBook(store: relationalStore.RdbStore, id: string, name: string, icon: string,
    color: string, isPrivate: number, isDefault: number, sort: number, now: number): Promise<void> {
    await store.executeSql(
      'INSERT OR REPLACE INTO book (id, name, icon, color, is_private, pwd_hash, pwd_salt, pwd_iter, ' +
        'is_default, sort, archived, created_at, updated_at) VALUES (?, ?, ?, ?, ?, NULL, NULL, 10000, ?, ?, 0, ?, ?)',
      [id, name, icon, color, isPrivate, isDefault, sort, now, now]
    );
  }

  private static async insertBudgets(store: relationalStore.RdbStore): Promise<void> {
    const period: string = DebugSeedService.monthKey(new Date());
    await store.executeSql(
      'INSERT OR REPLACE INTO budget (id, book_id, period, amount_cents, updated_at) VALUES (?, ?, ?, ?, ?)',
      ['demo_budget_daily', DebugSeedService.demoBookDaily, period, 300000, Date.now()]
    );
    await store.executeSql(
      'INSERT OR REPLACE INTO budget (id, book_id, period, amount_cents, updated_at) VALUES (?, ?, ?, ?, ?)',
      ['demo_budget_travel', DebugSeedService.demoBookTravel, period, 800000, Date.now()]
    );
  }

  private static async insertTxns(store: relationalStore.RdbStore): Promise<void> {
    const categories: Category[] = await DebugSeedService.loadCategories(store);
    const members: Member[] = await DebugSeedService.loadMembers(store);
    if (categories.length === 0 || members.length === 0) {
      return;
    }
    const now: Date = new Date();
    const year: number = now.getFullYear();
    const month: number = now.getMonth();
    const today: number = now.getDate();
    for (let i = 0; i < 30; i++) {
      const day: number = Math.max(1, today - (i % Math.max(1, today)));
      const date: Date = new Date(year, month, day, 8 + (i % 12), (i * 7) % 60, 0, 0);
      const amount: number = 800 + ((i * 1373) % 22000);
      const category: Category = categories[i % categories.length];
      const member: Member = members[i % members.length];
      const bookId: string = i % 7 === 0 ? DebugSeedService.demoBookTravel : DebugSeedService.demoBookDaily;
      const id: string = 'demo_txn_'.concat(i.toString());
      await store.executeSql(
        'INSERT OR REPLACE INTO txn (id, book_id, category_id, member_id, amount_cents, occurred_at, day_key, ' +
          'note, created_at, updated_at, deleted_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)',
        [id, bookId, category.id, member.id, amount, date.getTime(), DebugSeedService.dayKey(date),
          category.name, now.getTime(), now.getTime()]
      );
    }
  }

  private static async loadCategories(store: relationalStore.RdbStore): Promise<Category[]> {
    const rs: relationalStore.ResultSet = await store.querySql(
      'SELECT * FROM category WHERE archived = 0 ORDER BY sort ASC, pinyin ASC'
    );
    const list: Category[] = [];
    try {
      while (rs.goToNextRow()) {
        const category: Category = {
          id: rs.getString(rs.getColumnIndex('id')),
          groupId: rs.getString(rs.getColumnIndex('group_id')),
          name: rs.getString(rs.getColumnIndex('name')),
          icon: rs.getString(rs.getColumnIndex('icon')),
          color: rs.getString(rs.getColumnIndex('color')),
          pinyin: rs.getString(rs.getColumnIndex('pinyin')),
          sort: rs.getLong(rs.getColumnIndex('sort')),
          archived: rs.getLong(rs.getColumnIndex('archived')) === 1,
          createdAt: rs.getLong(rs.getColumnIndex('created_at'))
        };
        list.push(category);
      }
    } finally {
      rs.close();
    }
    return list;
  }

  private static async loadMembers(store: relationalStore.RdbStore): Promise<Member[]> {
    const rs: relationalStore.ResultSet = await store.querySql(
      'SELECT * FROM member WHERE archived = 0 ORDER BY sort ASC'
    );
    const list: Member[] = [];
    try {
      while (rs.goToNextRow()) {
        const member: Member = {
          id: rs.getString(rs.getColumnIndex('id')),
          name: rs.getString(rs.getColumnIndex('name')),
          initial: rs.getString(rs.getColumnIndex('initial')),
          color: rs.getString(rs.getColumnIndex('color')),
          isDefault: rs.getLong(rs.getColumnIndex('is_default')) === 1,
          sort: rs.getLong(rs.getColumnIndex('sort')),
          archived: rs.getLong(rs.getColumnIndex('archived')) === 1
        };
        list.push(member);
      }
    } finally {
      rs.close();
    }
    return list;
  }

  private static dayKey(date: Date): string {
    const m: string = (date.getMonth() + 1).toString().padStart(2, '0');
    const d: string = date.getDate().toString().padStart(2, '0');
    return date.getFullYear().toString().concat('-').concat(m).concat('-').concat(d);
  }

  private static monthKey(date: Date): string {
    const m: string = (date.getMonth() + 1).toString().padStart(2, '0');
    return date.getFullYear().toString().concat('-').concat(m);
  }
}
