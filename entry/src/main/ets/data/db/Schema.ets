export class TableNames {
  static readonly book: string = 'book';
  static readonly member: string = 'member';
  static readonly categoryGroup: string = 'category_group';
  static readonly category: string = 'category';
  static readonly txn: string = 'txn';
  static readonly budget: string = 'budget';
  static readonly appMeta: string = 'app_meta';
}

export const SQL_CREATE_TABLES: string[] = [
  `CREATE TABLE IF NOT EXISTS book (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    icon TEXT NOT NULL,
    color TEXT NOT NULL,
    is_private INTEGER NOT NULL DEFAULT 0,
    pwd_hash TEXT,
    pwd_salt TEXT,
    pwd_iter INTEGER NOT NULL DEFAULT 10000,
    is_default INTEGER NOT NULL DEFAULT 0,
    sort INTEGER NOT NULL DEFAULT 0,
    archived INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )`,
  `CREATE TABLE IF NOT EXISTS member (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    initial TEXT NOT NULL,
    color TEXT NOT NULL,
    is_default INTEGER NOT NULL DEFAULT 0,
    sort INTEGER NOT NULL DEFAULT 0,
    archived INTEGER NOT NULL DEFAULT 0
  )`,
  `CREATE TABLE IF NOT EXISTS category_group (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    sort INTEGER NOT NULL DEFAULT 0,
    is_system INTEGER NOT NULL DEFAULT 0
  )`,
  `CREATE TABLE IF NOT EXISTS category (
    id TEXT PRIMARY KEY,
    group_id TEXT NOT NULL,
    name TEXT NOT NULL,
    icon TEXT NOT NULL,
    color TEXT NOT NULL,
    pinyin TEXT NOT NULL DEFAULT '',
    sort INTEGER NOT NULL DEFAULT 0,
    archived INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL
  )`,
  `CREATE TABLE IF NOT EXISTS txn (
    id TEXT PRIMARY KEY,
    book_id TEXT NOT NULL,
    category_id TEXT NOT NULL,
    member_id TEXT NOT NULL,
    amount_cents INTEGER NOT NULL,
    occurred_at INTEGER NOT NULL,
    day_key TEXT NOT NULL,
    note TEXT NOT NULL DEFAULT '',
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER
  )`,
  `CREATE TABLE IF NOT EXISTS budget (
    id TEXT PRIMARY KEY,
    book_id TEXT NOT NULL,
    period TEXT NOT NULL,
    amount_cents INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )`,
  `CREATE TABLE IF NOT EXISTS app_meta (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
  )`
];

export const SQL_CREATE_INDEXES: string[] = [
  'CREATE INDEX IF NOT EXISTS idx_txn_book_day ON txn(book_id, day_key)',
  'CREATE INDEX IF NOT EXISTS idx_txn_day ON txn(day_key)',
  'CREATE INDEX IF NOT EXISTS idx_txn_category ON txn(category_id)',
  'CREATE INDEX IF NOT EXISTS idx_txn_member ON txn(member_id)',
  'CREATE INDEX IF NOT EXISTS idx_category_group ON category(group_id)',
  'CREATE UNIQUE INDEX IF NOT EXISTS idx_book_default ON book(is_default) WHERE is_default = 1',
  'CREATE UNIQUE INDEX IF NOT EXISTS idx_budget_book_period ON budget(book_id, period)'
];
