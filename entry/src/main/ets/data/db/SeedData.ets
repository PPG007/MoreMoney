import { relationalStore } from '@kit.ArkData';
import { SeedColors } from '../../theme/Palette';

class SeedBook {
  id: string = '';
  name: string = '';
  icon: string = '';
  color: string = '';
  isDefault: number = 0;
  sort: number = 0;
}

class SeedMember {
  id: string = '';
  name: string = '';
  initial: string = '';
  color: string = '';
  isDefault: number = 0;
  sort: number = 0;
}

class SeedGroup {
  id: string = '';
  name: string = '';
  sort: number = 0;
}

class SeedCategory {
  id: string = '';
  groupId: string = '';
  name: string = '';
  icon: string = '';
  color: string = '';
  pinyin: string = '';
  sort: number = 0;
}

export class SeedData {
  static readonly seedVersion: number = 1;

  static async ensureSeeded(store: relationalStore.RdbStore): Promise<void> {
    const current: number = await SeedData.readMetaNumber(store, 'seed_version');
    if (current >= SeedData.seedVersion) {
      return;
    }
    const now: number = Date.now();
    await SeedData.insertBooks(store, now);
    await SeedData.insertMembers(store);
    await SeedData.insertGroups(store);
    await SeedData.insertCategories(store, now);
    await SeedData.writeMeta(store, 'seed_version', SeedData.seedVersion.toString());
  }

  private static async insertBooks(store: relationalStore.RdbStore, now: number): Promise<void> {
    const books: SeedBook[] = [];
    const daily: SeedBook = new SeedBook();
    daily.id = 'book_daily';
    daily.name = '日常账本';
    daily.icon = 'ic_book_daily';
    daily.color = SeedColors.c1;
    daily.isDefault = 1;
    daily.sort = 0;
    books.push(daily);
    const travel: SeedBook = new SeedBook();
    travel.id = 'book_travel';
    travel.name = '旅行';
    travel.icon = 'ic_book_travel';
    travel.color = SeedColors.c2;
    travel.sort = 1;
    books.push(travel);
    const repair: SeedBook = new SeedBook();
    repair.id = 'book_repair';
    repair.name = '装修';
    repair.icon = 'ic_book_repair';
    repair.color = SeedColors.c3;
    repair.sort = 2;
    books.push(repair);
    for (const book of books) {
      await store.executeSql(
        'INSERT OR IGNORE INTO book (id, name, icon, color, is_private, pwd_hash, pwd_salt, pwd_iter, ' +
          'is_default, sort, archived, created_at, updated_at) VALUES (?, ?, ?, ?, 0, NULL, NULL, 10000, ?, ?, 0, ?, ?)',
        [book.id, book.name, book.icon, book.color, book.isDefault, book.sort, now, now]
      );
    }
  }

  private static async insertMembers(store: relationalStore.RdbStore): Promise<void> {
    const members: SeedMember[] = [];
    const self: SeedMember = new SeedMember();
    self.id = 'member_self';
    self.name = '自己';
    self.initial = '自';
    self.color = SeedColors.c1;
    self.isDefault = 1;
    self.sort = 0;
    members.push(self);
    const family: SeedMember = new SeedMember();
    family.id = 'member_family';
    family.name = '家人';
    family.initial = '家';
    family.color = SeedColors.memberFamily;
    family.sort = 1;
    members.push(family);
    const child: SeedMember = new SeedMember();
    child.id = 'member_child';
    child.name = '孩子';
    child.initial = '孩';
    child.color = SeedColors.memberChild;
    child.sort = 2;
    members.push(child);
    for (const member of members) {
      await store.executeSql(
        'INSERT OR IGNORE INTO member (id, name, initial, color, is_default, sort, archived) VALUES (?, ?, ?, ?, ?, ?, 0)',
        [member.id, member.name, member.initial, member.color, member.isDefault, member.sort]
      );
    }
  }

  private static async insertGroups(store: relationalStore.RdbStore): Promise<void> {
    const groups: SeedGroup[] = [];
    const names: string[] = ['餐饮', '出行', '居家', '购物', '休闲', '其他'];
    const ids: string[] = ['group_food', 'group_travel', 'group_home', 'group_shop', 'group_leisure', 'group_other'];
    for (let i = 0; i < names.length; i++) {
      const group: SeedGroup = new SeedGroup();
      group.id = ids[i];
      group.name = names[i];
      group.sort = i;
      groups.push(group);
    }
    for (const group of groups) {
      await store.executeSql(
        'INSERT OR IGNORE INTO category_group (id, name, sort, is_system) VALUES (?, ?, ?, 1)',
        [group.id, group.name, group.sort]
      );
    }
  }

  private static async insertCategories(store: relationalStore.RdbStore, now: number): Promise<void> {
    const categories: SeedCategory[] = [];
    SeedData.addCategory(categories, 'cat_food', 'group_food', '餐饮', 'ic_cat_food', SeedColors.c2, 'canyin', 0);
    SeedData.addCategory(categories, 'cat_transport', 'group_travel', '交通', 'ic_cat_transport', SeedColors.c1, 'jiaotong', 0);
    SeedData.addCategory(categories, 'cat_home', 'group_home', '居家', 'ic_cat_home', SeedColors.c3, 'jujia', 0);
    SeedData.addCategory(categories, 'cat_shopping', 'group_shop', '购物', 'ic_cat_shopping', SeedColors.c5, 'gouwu', 0);
    SeedData.addCategory(categories, 'cat_entertain', 'group_leisure', '娱乐', 'ic_cat_entertain', SeedColors.c4, 'yule', 0);
    SeedData.addCategory(categories, 'cat_medical', 'group_other', '医疗', 'ic_cat_medical', SeedColors.c8, 'yiliao', 0);
    SeedData.addCategory(categories, 'cat_study', 'group_other', '学习', 'ic_cat_study', SeedColors.c6, 'xuexi', 1);
    SeedData.addCategory(categories, 'cat_water', 'group_home', '水电', 'ic_cat_water', SeedColors.c7, 'shuidian', 1);
    SeedData.addCategory(categories, 'cat_phone', 'group_other', '通讯', 'ic_cat_phone', SeedColors.neutral, 'tongxun', 2);
    SeedData.addCategory(categories, 'cat_other', 'group_other', '其他', 'ic_cat_other', SeedColors.neutral, 'qita', 3);
    for (const category of categories) {
      await store.executeSql(
        'INSERT OR IGNORE INTO category (id, group_id, name, icon, color, pinyin, sort, archived, created_at) ' +
          'VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?)',
        [category.id, category.groupId, category.name, category.icon, category.color, category.pinyin,
          category.sort, now]
      );
    }
  }

  private static addCategory(list: SeedCategory[], id: string, groupId: string, name: string, icon: string,
    color: string, pinyin: string, sort: number): void {
    const category: SeedCategory = new SeedCategory();
    category.id = id;
    category.groupId = groupId;
    category.name = name;
    category.icon = icon;
    category.color = color;
    category.pinyin = pinyin;
    category.sort = sort;
    list.push(category);
  }

  private static async readMetaNumber(store: relationalStore.RdbStore, key: string): Promise<number> {
    const rs: relationalStore.ResultSet = await store.querySql('SELECT value FROM app_meta WHERE key = ?', [key]);
    try {
      if (rs.goToFirstRow()) {
        const text: string = rs.getString(rs.getColumnIndex('value'));
        const parsed: number = Number(text);
        return Number.isNaN(parsed) ? 0 : parsed;
      }
    } finally {
      rs.close();
    }
    return 0;
  }

  static async writeMeta(store: relationalStore.RdbStore, key: string, value: string): Promise<void> {
    await store.executeSql('INSERT OR REPLACE INTO app_meta (key, value) VALUES (?, ?)', [key, value]);
  }
}
