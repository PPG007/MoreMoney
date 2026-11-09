import { relationalStore } from '@kit.ArkData';
import { Book } from '../../models/Entities';
import { DbManager } from './DbManager';
import { DbMapper } from './DbMapper';

export class BookDao {
  static async list(): Promise<Book[]> {
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT * FROM book ORDER BY archived ASC, sort ASC, created_at ASC'
    );
    const list: Book[] = [];
    try {
      while (rs.goToNextRow()) {
        list.push(DbMapper.toBook(rs));
      }
    } finally {
      rs.close();
    }
    return list;
  }

  static async get(id: string): Promise<Book | null> {
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT * FROM book WHERE id = ?', [id]
    );
    try {
      if (rs.goToNextRow()) {
        return DbMapper.toBook(rs);
      }
    } finally {
      rs.close();
    }
    return null;
  }

  static async insert(book: Book): Promise<void> {
    await DbManager.store.executeSql(
      'INSERT INTO book (id, name, icon, color, is_private, pwd_hash, pwd_salt, pwd_iter, is_default, sort, ' +
        'archived, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [book.id, book.name, book.icon, book.color, book.isPrivate ? 1 : 0, book.pwdHash, book.pwdSalt,
        book.pwdIter, book.isDefault ? 1 : 0, book.sort, book.archived ? 1 : 0, book.createdAt, book.updatedAt]
    );
  }

  static async update(book: Book): Promise<void> {
    await DbManager.store.executeSql(
      'UPDATE book SET name = ?, icon = ?, color = ?, is_private = ?, pwd_hash = ?, pwd_salt = ?, pwd_iter = ?, ' +
        'sort = ?, archived = ?, updated_at = ? WHERE id = ?',
      [book.name, book.icon, book.color, book.isPrivate ? 1 : 0, book.pwdHash, book.pwdSalt, book.pwdIter,
        book.sort, book.archived ? 1 : 0, book.updatedAt, book.id]
    );
  }

  static async setDefault(id: string): Promise<void> {
    const now: number = Date.now();
    const tx: relationalStore.Transaction = await DbManager.store.createTransaction();
    try {
      await tx.execute('UPDATE book SET is_default = 0, updated_at = ? WHERE is_default = 1', [now]);
      await tx.execute('UPDATE book SET is_default = 1, updated_at = ? WHERE id = ?', [now, id]);
      await tx.commit();
    } catch (error) {
      await tx.rollback();
      throw new Error('设置默认账本失败: ' + String(error));
    }
  }

  static async archive(id: string): Promise<void> {
    await DbManager.store.executeSql('UPDATE book SET archived = 1, updated_at = ? WHERE id = ?', [Date.now(), id]);
  }

  static async delete(id: string): Promise<void> {
    const book: Book | null = await BookDao.get(id);
    if (book === null) {
      return;
    }
    const txnCount: number = await BookDao.countTxns(id);
    if (txnCount > 0) {
      throw new Error('该账本已有流水，请使用归档');
    }
    if (book.isDefault) {
      const otherCount: number = await BookDao.countOtherActive(id);
      if (otherCount > 0) {
        throw new Error('请先指定新的默认账本');
      }
    }
    await DbManager.store.executeSql('DELETE FROM book WHERE id = ?', [id]);
  }

  private static async countTxns(bookId: string): Promise<number> {
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT COUNT(*) AS c FROM txn WHERE book_id = ?', [bookId]
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

  private static async countOtherActive(id: string): Promise<number> {
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT COUNT(*) AS c FROM book WHERE archived = 0 AND id <> ?', [id]
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
