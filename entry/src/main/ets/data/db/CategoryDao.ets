import { relationalStore } from '@kit.ArkData';
import { Category, CategoryGroup } from '../../models/Entities';
import { DbManager } from './DbManager';
import { DbMapper } from './DbMapper';

export class CategoryDao {
  static async listGroups(): Promise<CategoryGroup[]> {
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT * FROM category_group ORDER BY sort ASC, name ASC'
    );
    const list: CategoryGroup[] = [];
    try {
      while (rs.goToNextRow()) {
        list.push(DbMapper.toCategoryGroup(rs));
      }
    } finally {
      rs.close();
    }
    return list;
  }

  static async listByGroup(groupId: string): Promise<Category[]> {
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT * FROM category WHERE group_id = ? ORDER BY archived ASC, pinyin ASC, sort ASC', [groupId]
    );
    const list: Category[] = [];
    try {
      while (rs.goToNextRow()) {
        list.push(DbMapper.toCategory(rs));
      }
    } finally {
      rs.close();
    }
    return list;
  }

  static async get(id: string): Promise<Category | null> {
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT * FROM category WHERE id = ?', [id]
    );
    try {
      if (rs.goToNextRow()) {
        return DbMapper.toCategory(rs);
      }
    } finally {
      rs.close();
    }
    return null;
  }

  static async insert(category: Category): Promise<void> {
    await DbManager.store.executeSql(
      'INSERT INTO category (id, group_id, name, icon, color, pinyin, sort, archived, created_at) ' +
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [category.id, category.groupId, category.name, category.icon, category.color, category.pinyin,
        category.sort, category.archived ? 1 : 0, category.createdAt]
    );
  }

  static async update(category: Category): Promise<void> {
    await DbManager.store.executeSql(
      'UPDATE category SET group_id = ?, name = ?, icon = ?, color = ?, pinyin = ?, sort = ?, archived = ? ' +
        'WHERE id = ?',
      [category.groupId, category.name, category.icon, category.color, category.pinyin, category.sort,
        category.archived ? 1 : 0, category.id]
    );
  }

  static async archive(id: string): Promise<void> {
    await DbManager.store.executeSql('UPDATE category SET archived = 1 WHERE id = ?', [id]);
  }

  static async delete(id: string): Promise<void> {
    const count: number = await CategoryDao.countTxns(id);
    if (count > 0) {
      throw new Error('该分类已有流水，请使用归档');
    }
    await DbManager.store.executeSql('DELETE FROM category WHERE id = ?', [id]);
  }

  static async listFrequent(limit: number, sinceMs: number): Promise<Category[]> {
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT c.*, COUNT(t.id) AS use_count FROM category c INNER JOIN txn t ON t.category_id = c.id ' +
        'WHERE t.deleted_at IS NULL AND t.occurred_at >= ? AND c.archived = 0 ' +
        'GROUP BY c.id ORDER BY use_count DESC, c.sort ASC LIMIT ?',
      [sinceMs, limit]
    );
    const list: Category[] = [];
    try {
      while (rs.goToNextRow()) {
        list.push(DbMapper.toCategory(rs));
      }
    } finally {
      rs.close();
    }
    return list;
  }

  static async insertGroup(group: CategoryGroup): Promise<void> {
    await DbManager.store.executeSql(
      'INSERT INTO category_group (id, name, sort, is_system) VALUES (?, ?, ?, ?)',
      [group.id, group.name, group.sort, group.isSystem ? 1 : 0]
    );
  }

  static async renameGroup(id: string, name: string): Promise<void> {
    await DbManager.store.executeSql('UPDATE category_group SET name = ? WHERE id = ?', [name, id]);
  }

  static async deleteGroup(id: string): Promise<void> {
    const group: CategoryGroup | null = await CategoryDao.getGroup(id);
    if (group === null) {
      return;
    }
    if (group.isSystem) {
      throw new Error('系统分组不可删除');
    }
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT COUNT(*) AS c FROM category WHERE group_id = ?', [id]
    );
    let count: number = 0;
    try {
      if (rs.goToFirstRow()) {
        count = rs.getLong(rs.getColumnIndex('c'));
      }
    } finally {
      rs.close();
    }
    if (count > 0) {
      throw new Error('分组下还有分类，无法删除');
    }
    await DbManager.store.executeSql('DELETE FROM category_group WHERE id = ?', [id]);
  }

  private static async getGroup(id: string): Promise<CategoryGroup | null> {
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT * FROM category_group WHERE id = ?', [id]
    );
    try {
      if (rs.goToNextRow()) {
        return DbMapper.toCategoryGroup(rs);
      }
    } finally {
      rs.close();
    }
    return null;
  }

  private static async countTxns(categoryId: string): Promise<number> {
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT COUNT(*) AS c FROM txn WHERE category_id = ?', [categoryId]
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
