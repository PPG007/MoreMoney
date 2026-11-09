import { relationalStore } from '@kit.ArkData';
import { Budget } from '../../models/Entities';
import { DbManager } from './DbManager';
import { DbMapper } from './DbMapper';

export class BudgetDao {
  static async get(bookId: string, period: string): Promise<Budget | null> {
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT * FROM budget WHERE book_id = ? AND period = ?', [bookId, period]
    );
    try {
      if (rs.goToNextRow()) {
        return DbMapper.toBudget(rs);
      }
    } finally {
      rs.close();
    }
    return null;
  }

  static async upsert(bookId: string, period: string, amountCents: number): Promise<void> {
    const existing: Budget | null = await BudgetDao.get(bookId, period);
    const id: string = existing === null ? 'budget_'.concat(bookId).concat('_').concat(period) : existing.id;
    await DbManager.store.executeSql(
      'INSERT OR REPLACE INTO budget (id, book_id, period, amount_cents, updated_at) VALUES (?, ?, ?, ?, ?)',
      [id, bookId, period, amountCents, Date.now()]
    );
  }

  static async list(period: string): Promise<Budget[]> {
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT * FROM budget WHERE period = ? ORDER BY updated_at DESC', [period]
    );
    const list: Budget[] = [];
    try {
      while (rs.goToNextRow()) {
        list.push(DbMapper.toBudget(rs));
      }
    } finally {
      rs.close();
    }
    return list;
  }

  static async listAll(): Promise<Budget[]> {
    const rs: relationalStore.ResultSet = await DbManager.store.querySql('SELECT * FROM budget');
    const list: Budget[] = [];
    try {
      while (rs.goToNextRow()) {
        list.push(DbMapper.toBudget(rs));
      }
    } finally {
      rs.close();
    }
    return list;
  }

  static async remove(bookId: string, period: string): Promise<void> {
    await DbManager.store.executeSql('DELETE FROM budget WHERE book_id = ? AND period = ?', [bookId, period]);
  }
}
