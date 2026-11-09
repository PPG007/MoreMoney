import { relationalStore } from '@kit.ArkData';
import { Txn, TxnFilter } from '../../models/Entities';
import { DbManager } from './DbManager';
import { DbMapper } from './DbMapper';

const RETENTION_MS: number = 30 * 24 * 60 * 60 * 1000;

export class TxnDao {
  static async insert(txn: Txn): Promise<void> {
    await DbManager.store.executeSql(
      'INSERT INTO txn (id, book_id, category_id, member_id, amount_cents, occurred_at, day_key, note, ' +
        'created_at, updated_at, deleted_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [txn.id, txn.bookId, txn.categoryId, txn.memberId, txn.amountCents, txn.occurredAt, txn.dayKey,
        txn.note, txn.createdAt, txn.updatedAt, txn.deletedAt]
    );
  }

  static async update(txn: Txn): Promise<void> {
    await DbManager.store.executeSql(
      'UPDATE txn SET book_id = ?, category_id = ?, member_id = ?, amount_cents = ?, occurred_at = ?, ' +
        'day_key = ?, note = ?, updated_at = ? WHERE id = ?',
      [txn.bookId, txn.categoryId, txn.memberId, txn.amountCents, txn.occurredAt, txn.dayKey, txn.note,
        txn.updatedAt, txn.id]
    );
  }

  static async softDelete(id: string): Promise<void> {
    const now: number = Date.now();
    await DbManager.store.executeSql('UPDATE txn SET deleted_at = ?, updated_at = ? WHERE id = ?', [now, now, id]);
  }

  static async restore(id: string): Promise<void> {
    await DbManager.store.executeSql('UPDATE txn SET deleted_at = NULL, updated_at = ? WHERE id = ?',
      [Date.now(), id]);
  }

  static async hardDeleteExpired(): Promise<void> {
    await DbManager.store.executeSql('DELETE FROM txn WHERE deleted_at IS NOT NULL AND deleted_at < ?',
      [Date.now() - RETENTION_MS]);
  }

  static async listByDay(bookIds: string[], dayKey: string): Promise<Txn[]> {
    const args: Array<relationalStore.ValueType> = [dayKey];
    let where: string = 'deleted_at IS NULL AND day_key = ?';
    if (bookIds.length > 0) {
      where += ' AND book_id IN (' + TxnDao.marks(bookIds.length) + ')';
      for (const id of bookIds) {
        args.push(id);
      }
    }
    return TxnDao.queryList('SELECT * FROM txn WHERE ' + where + ' ORDER BY occurred_at DESC, created_at DESC', args);
  }

  static async listRange(filter: TxnFilter): Promise<Txn[]> {
    const args: Array<relationalStore.ValueType> = [];
    const where: string = TxnDao.buildWhere(filter, args);
    return TxnDao.queryList('SELECT * FROM txn WHERE ' + where + ' ORDER BY occurred_at DESC, created_at DESC', args);
  }

  static async listRecent(limit: number): Promise<Txn[]> {
    return TxnDao.queryList(
      'SELECT * FROM txn WHERE deleted_at IS NULL ORDER BY occurred_at DESC, created_at DESC LIMIT ?', [limit]
    );
  }

  static async listDeleted(limit: number): Promise<Txn[]> {
    return TxnDao.queryList(
      'SELECT * FROM txn WHERE deleted_at IS NOT NULL ORDER BY deleted_at DESC LIMIT ?', [limit]
    );
  }

  static async moveToBook(fromBookId: string, toBookId: string): Promise<void> {
    await DbManager.store.executeSql(
      'UPDATE txn SET book_id = ?, updated_at = ? WHERE book_id = ? AND deleted_at IS NULL',
      [toBookId, Date.now(), fromBookId]
    );
  }

  static async sumRange(filter: TxnFilter): Promise<number> {
    const args: Array<relationalStore.ValueType> = [];
    const where: string = TxnDao.buildWhere(filter, args);
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT COALESCE(SUM(amount_cents), 0) AS total FROM txn WHERE ' + where, args
    );
    try {
      if (rs.goToFirstRow()) {
        return rs.getLong(rs.getColumnIndex('total'));
      }
    } finally {
      rs.close();
    }
    return 0;
  }

  static async countByBook(bookId: string): Promise<number> {
    return TxnDao.countWhere('book_id = ? AND deleted_at IS NULL', [bookId]);
  }

  static async countByMember(memberId: string): Promise<number> {
    return TxnDao.countWhere('member_id = ? AND deleted_at IS NULL', [memberId]);
  }

  static async countByCategory(categoryId: string): Promise<number> {
    return TxnDao.countWhere('category_id = ? AND deleted_at IS NULL', [categoryId]);
  }

  private static buildWhere(filter: TxnFilter, args: Array<relationalStore.ValueType>): string {
    let where: string = 'deleted_at IS NULL';
    if (filter.bookIds.length > 0) {
      where += ' AND book_id IN (' + TxnDao.marks(filter.bookIds.length) + ')';
      for (const id of filter.bookIds) {
        args.push(id);
      }
    }
    if (filter.memberIds.length > 0) {
      where += ' AND member_id IN (' + TxnDao.marks(filter.memberIds.length) + ')';
      for (const id of filter.memberIds) {
        args.push(id);
      }
    }
    if (filter.startMs > 0) {
      where += ' AND occurred_at >= ?';
      args.push(filter.startMs);
    }
    if (filter.endMs > 0) {
      where += ' AND occurred_at <= ?';
      args.push(filter.endMs);
    }
    return where;
  }

  private static marks(count: number): string {
    const marks: string[] = [];
    for (let i = 0; i < count; i++) {
      marks.push('?');
    }
    return marks.join(', ');
  }

  private static async queryList(sql: string, args: Array<relationalStore.ValueType>): Promise<Txn[]> {
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(sql, args);
    const list: Txn[] = [];
    try {
      while (rs.goToNextRow()) {
        list.push(DbMapper.toTxn(rs));
      }
    } finally {
      rs.close();
    }
    return list;
  }

  private static async countWhere(where: string, args: Array<relationalStore.ValueType>): Promise<number> {
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT COUNT(*) AS c FROM txn WHERE ' + where, args
    );
    try {
      if (rs.goToFirstRow()) {
        return rs.getLong(rs.getColumnIndex('c'));
      }
    } finally {
      rs.close();
    }
    return 0;
  }
}
