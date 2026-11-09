import { relationalStore } from '@kit.ArkData';
import { Book, Budget, Category, CategoryGroup, Member, Txn } from '../../models/Entities';

export class DbMapper {
  static toBook(rs: relationalStore.ResultSet): Book {
    const book: Book = {
      id: rs.getString(rs.getColumnIndex('id')),
      name: rs.getString(rs.getColumnIndex('name')),
      icon: rs.getString(rs.getColumnIndex('icon')),
      color: rs.getString(rs.getColumnIndex('color')),
      isPrivate: rs.getLong(rs.getColumnIndex('is_private')) === 1,
      pwdHash: DbMapper.nullableString(rs, 'pwd_hash'),
      pwdSalt: DbMapper.nullableString(rs, 'pwd_salt'),
      pwdIter: rs.getLong(rs.getColumnIndex('pwd_iter')),
      isDefault: rs.getLong(rs.getColumnIndex('is_default')) === 1,
      sort: rs.getLong(rs.getColumnIndex('sort')),
      archived: rs.getLong(rs.getColumnIndex('archived')) === 1,
      createdAt: rs.getLong(rs.getColumnIndex('created_at')),
      updatedAt: rs.getLong(rs.getColumnIndex('updated_at'))
    };
    return book;
  }

  static toMember(rs: relationalStore.ResultSet): Member {
    const member: Member = {
      id: rs.getString(rs.getColumnIndex('id')),
      name: rs.getString(rs.getColumnIndex('name')),
      initial: rs.getString(rs.getColumnIndex('initial')),
      color: rs.getString(rs.getColumnIndex('color')),
      isDefault: rs.getLong(rs.getColumnIndex('is_default')) === 1,
      sort: rs.getLong(rs.getColumnIndex('sort')),
      archived: rs.getLong(rs.getColumnIndex('archived')) === 1
    };
    return member;
  }

  static toCategoryGroup(rs: relationalStore.ResultSet): CategoryGroup {
    const group: CategoryGroup = {
      id: rs.getString(rs.getColumnIndex('id')),
      name: rs.getString(rs.getColumnIndex('name')),
      sort: rs.getLong(rs.getColumnIndex('sort')),
      isSystem: rs.getLong(rs.getColumnIndex('is_system')) === 1
    };
    return group;
  }

  static toCategory(rs: relationalStore.ResultSet): Category {
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
    return category;
  }

  static toTxn(rs: relationalStore.ResultSet): Txn {
    const txn: Txn = {
      id: rs.getString(rs.getColumnIndex('id')),
      bookId: rs.getString(rs.getColumnIndex('book_id')),
      categoryId: rs.getString(rs.getColumnIndex('category_id')),
      memberId: rs.getString(rs.getColumnIndex('member_id')),
      amountCents: rs.getLong(rs.getColumnIndex('amount_cents')),
      occurredAt: rs.getLong(rs.getColumnIndex('occurred_at')),
      dayKey: rs.getString(rs.getColumnIndex('day_key')),
      note: rs.getString(rs.getColumnIndex('note')),
      createdAt: rs.getLong(rs.getColumnIndex('created_at')),
      updatedAt: rs.getLong(rs.getColumnIndex('updated_at')),
      deletedAt: DbMapper.nullableLong(rs, 'deleted_at')
    };
    return txn;
  }

  static toBudget(rs: relationalStore.ResultSet): Budget {
    const budget: Budget = {
      id: rs.getString(rs.getColumnIndex('id')),
      bookId: rs.getString(rs.getColumnIndex('book_id')),
      period: rs.getString(rs.getColumnIndex('period')),
      amountCents: rs.getLong(rs.getColumnIndex('amount_cents')),
      updatedAt: rs.getLong(rs.getColumnIndex('updated_at'))
    };
    return budget;
  }

  static nullableString(rs: relationalStore.ResultSet, column: string): string | null {
    const index: number = rs.getColumnIndex(column);
    if (index < 0 || rs.isColumnNull(index)) {
      return null;
    }
    return rs.getString(index);
  }

  static nullableLong(rs: relationalStore.ResultSet, column: string): number | null {
    const index: number = rs.getColumnIndex(column);
    if (index < 0 || rs.isColumnNull(index)) {
      return null;
    }
    return rs.getLong(index);
  }
}
