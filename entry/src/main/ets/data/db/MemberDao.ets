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
