export interface Book {
  id: string;
  name: string;
  icon: string;
  color: string;
  isPrivate: boolean;
  pwdHash: string | null;
  pwdSalt: string | null;
  pwdIter: number;
  isDefault: boolean;
  sort: number;
  archived: boolean;
  createdAt: number;
  updatedAt: number;
}

export interface Member {
  id: string;
  name: string;
  initial: string;
  color: string;
  isDefault: boolean;
  sort: number;
  archived: boolean;
}

export interface CategoryGroup {
  id: string;
  name: string;
  sort: number;
  isSystem: boolean;
}

export interface Category {
  id: string;
  groupId: string;
  name: string;
  icon: string;
  color: string;
  pinyin: string;
  sort: number;
  archived: boolean;
  createdAt: number;
}

export interface Txn {
  id: string;
  bookId: string;
  categoryId: string;
  memberId: string;
  amountCents: number;
  occurredAt: number;
  dayKey: string;
  note: string;
  createdAt: number;
  updatedAt: number;
  deletedAt: number | null;
}

export interface Budget {
  id: string;
  bookId: string;
  period: string;
  amountCents: number;
  updatedAt: number;
}

export class TxnFilter {
  bookIds: string[] = [];
  memberIds: string[] = [];
  startMs: number = 0;
  endMs: number = 0;
}
