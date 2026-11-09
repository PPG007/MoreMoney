import { relationalStore } from '@kit.ArkData';
import { Member } from '../../models/Entities';
import { DbManager } from './DbManager';
import { DbMapper } from './DbMapper';

export class MemberDao {
  static async list(): Promise<Member[]> {
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT * FROM member ORDER BY archived ASC, sort ASC, name ASC'
    );
    const list: Member[] = [];
    try {
      while (rs.goToNextRow()) {
        list.push(DbMapper.toMember(rs));
      }
    } finally {
      rs.close();
    }
    return list;
  }

  static async get(id: string): Promise<Member | null> {
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT * FROM member WHERE id = ?', [id]
    );
    try {
      if (rs.goToNextRow()) {
        return DbMapper.toMember(rs);
      }
    } finally {
      rs.close();
    }
    return null;
  }

  static async insert(member: Member): Promise<void> {
    await DbManager.store.executeSql(
      'INSERT INTO member (id, name, initial, color, is_default, sort, archived) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [member.id, member.name, member.initial, member.color, member.isDefault ? 1 : 0, member.sort,
        member.archived ? 1 : 0]
    );
  }

  static async update(member: Member): Promise<void> {
    await DbManager.store.executeSql(
      'UPDATE member SET name = ?, initial = ?, color = ?, is_default = ?, sort = ?, archived = ? WHERE id = ?',
      [member.name, member.initial, member.color, member.isDefault ? 1 : 0, member.sort,
        member.archived ? 1 : 0, member.id]
    );
  }

  static async setDefault(id: string): Promise<void> {
    const tx: relationalStore.Transaction = await DbManager.store.createTransaction();
    try {
      await tx.execute('UPDATE member SET is_default = 0 WHERE is_default = 1');
      await tx.execute('UPDATE member SET is_default = 1 WHERE id = ?', [id]);
      await tx.commit();
    } catch (error) {
      await tx.rollback();
      throw new Error('设置默认成员失败: ' + String(error));
    }
  }

  static async countActive(): Promise<number> {
    return MemberDao.countWhere('archived = 0', []);
  }

  static async countTxnsById(memberId: string): Promise<number> {
    return MemberDao.countTxns(memberId);
  }

  static async unarchive(id: string): Promise<void> {
    await DbManager.store.executeSql('UPDATE member SET archived = 0 WHERE id = ?', [id]);
  }

  static async archive(id: string): Promise<void> {
    await DbManager.store.executeSql('UPDATE member SET archived = 1 WHERE id = ?', [id]);
  }

  static async delete(id: string): Promise<void> {
    const count: number = await MemberDao.countTxns(id);
    if (count > 0) {
      throw new Error('该成员已有流水，请使用归档');
    }
    await DbManager.store.executeSql('DELETE FROM member WHERE id = ?', [id]);
  }

  private static async countWhere(where: string, args: Array<relationalStore.ValueType>): Promise<number> {
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT COUNT(*) AS c FROM member WHERE ' + where, args
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

  private static async countTxns(memberId: string): Promise<number> {
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT COUNT(*) AS c FROM txn WHERE member_id = ?', [memberId]
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
