import { Category } from '../models/Entities';
import { CategoryDao } from '../data/db/CategoryDao';
import { TxnDao } from '../data/db/TxnDao';

export class CategoryService {
  static async listFrequent(limit: number, sinceMs: number): Promise<Category[]> {
    const frequent: Category[] = await CategoryDao.listFrequent(limit, sinceMs);
    const all: Category[] = await CategoryService.listActive();
    const result: Category[] = [];
    const used: string[] = [];
    for (const category of frequent) {
      result.push(category);
      used.push(category.id);
    }
    for (const category of all) {
      if (result.length >= limit) {
        break;
      }
      if (used.indexOf(category.id) < 0) {
        result.push(category);
      }
    }
    return result;
  }

  static async listActive(): Promise<Category[]> {
    const groups = await CategoryDao.listGroups();
    const all: Category[] = [];
    for (const group of groups) {
      const categories: Category[] = await CategoryDao.listByGroup(group.id);
      for (const category of categories) {
        if (!category.archived) {
          all.push(category);
        }
      }
    }
    all.sort((a: Category, b: Category): number => a.pinyin.localeCompare(b.pinyin));
    return all;
  }

  static async countReferences(categoryId: string): Promise<number> {
    return TxnDao.countByCategory(categoryId);
  }
}
