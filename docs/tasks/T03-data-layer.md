# T03 · 数据模型与 RDB 数据层

> 状态：已完成 ｜ 优先级：P0 ｜ 依赖：T01 ｜ 预估：2.0 人日
> 设计依据：`设计规范.md` §10.1、§10.2、§10.3、§11

## 1. 目标

建立本地 SQLite 数据层：表结构、迁移、种子数据、DAO。上层页面只依赖 DAO，不出现任何 SQL 字符串。

## 2. 交付物

| 路径 | 内容 |
|---|---|
| `entry/src/main/ets/models/Entities.ets` | `Book`、`Member`、`CategoryGroup`、`Category`、`Txn`、`Budget` 实体 |
| `entry/src/main/ets/data/db/DbManager.ets` | 打开数据库、建表、版本迁移、单例 |
| `entry/src/main/ets/data/db/Schema.ets` | 建表/索引 SQL 常量 |
| `entry/src/main/ets/data/db/SeedData.ets` | 基线数据（账本/成员/分类） |
| `entry/src/main/ets/service/DebugSeedService.ets` | 演示数据（仅调试可达） |
| `entry/src/main/ets/data/db/BookDao.ets` | 账本 CRUD |
| `entry/src/main/ets/data/db/MemberDao.ets` | 成员 CRUD |
| `entry/src/main/ets/data/db/CategoryDao.ets` | 分组/分类 CRUD、常用计算 |
| `entry/src/main/ets/data/db/TxnDao.ets` | 流水 CRUD、分页、按日查询 |
| `entry/src/main/ets/data/db/BudgetDao.ets` | 预算读写 |
| `entry/src/main/ets/data/db/DbMapper.ets` | ResultSet → 实体，禁止 `as` |

## 3. 表结构

```sql
CREATE TABLE IF NOT EXISTS book (
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
);

CREATE TABLE IF NOT EXISTS member (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  initial TEXT NOT NULL,
  color TEXT NOT NULL,
  is_default INTEGER NOT NULL DEFAULT 0,
  sort INTEGER NOT NULL DEFAULT 0,
  archived INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS category_group (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  sort INTEGER NOT NULL DEFAULT 0,
  is_system INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS category (
  id TEXT PRIMARY KEY,
  group_id TEXT NOT NULL,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  color TEXT NOT NULL,
  pinyin TEXT NOT NULL DEFAULT '',
  sort INTEGER NOT NULL DEFAULT 0,
  archived INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS txn (
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
);

CREATE TABLE IF NOT EXISTS budget (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  period TEXT NOT NULL,
  amount_cents INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS app_meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

索引与约束：

```sql
CREATE INDEX IF NOT EXISTS idx_txn_book_day ON txn(book_id, day_key);
CREATE INDEX IF NOT EXISTS idx_txn_day ON txn(day_key);
CREATE INDEX IF NOT EXISTS idx_txn_category ON txn(category_id);
CREATE INDEX IF NOT EXISTS idx_txn_member ON txn(member_id);
CREATE INDEX IF NOT EXISTS idx_category_group ON category(group_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_book_default ON book(is_default) WHERE is_default = 1;
CREATE UNIQUE INDEX IF NOT EXISTS idx_budget_book_period ON budget(book_id, period);
```

## 4. 实现要求

导入：`relationalStore` 来自 `@kit.ArkData`。

### 4.1 初始化

```ts
class DbManager {
  static async init(context: Context): Promise<void>
  static get store(): relationalStore.RdbStore   // init 完成后可用，未初始化抛错
}
```

- `StoreConfig`：`name: 'moremoney.db'`，`securityLevel: relationalStore.SecurityLevel.S1`。
- 在 `Index.aboutToAppear` 中 `await DbManager.init(getContext(this))`，初始化完成前显示懒加载占位。
- 初始化顺序：打开库 → 读 `store.version` → 迁移 → 基线种子（幂等）。
- 版本号写在 `store.version`；同时把 `schema_version` 写入 `app_meta` 便于备份校验。
- 迁移函数按 `version < N` 逐级执行，每一步用事务包裹。

### 4.2 实体规则

- 所有实体是 `interface`，字段名与列名一一对应（列名转小驼峰），禁止嵌套对象。
- 金额字段：`amountCents: number`。账本预算只存在 `budget` 表，不在 `book` 表冗余，避免双写。
- 布尔列：`isPrivate: boolean`、`isDefault: boolean`、`archived: boolean`；数据库存 0/1，Mapper 转换。
- 时间：`createdAt`/`updatedAt`/`occurredAt`: epoch ms；`deletedAt: number | null`。
- `Txn.dayKey`：`YYYY-MM-DD`（本地时区），写入时由 `DateUtil.dayKey(date)` 生成；**所有按日统计只用 dayKey**。

### 4.3 DAO 约定

- 全部为 `static async` 方法，返回 `Promise<T>`，失败向上抛。
- 列表查询必须显式 `ORDER BY`：
  - `BookDao.list()`：`archived ASC, sort ASC, created_at ASC`
  - `CategoryDao.listByGroup(groupId)`：`archived ASC, pinyin ASC, sort ASC`
  - `TxnDao.listByDay(bookIds, dayKey)`：`occurred_at DESC, created_at DESC`
  - `TxnDao.listRecent(limit)`：`occurred_at DESC, created_at DESC`
- 所有查询默认加 `deleted_at IS NULL`（`TxnDao.listDeleted` 除外）。
- 批量写入使用 `store.createTransaction()`；CSV 导入和备份恢复由上层调用事务版 DAO。

必须提供的方法（签名可微调，语义不得变）：

```ts
BookDao: list(), get(id), insert(book), update(book), setDefault(id),
         archive(id), delete(id)
MemberDao: list(), get(id), insert(member), update(member), archive(id), delete(id)
CategoryDao: listGroups(), listByGroup(groupId), get(id), insert(category), update(category),
             archive(id), delete(id), listFrequent(limit, sinceMs),
             insertGroup(group), renameGroup(id, name), deleteGroup(id)
TxnDao: insert(txn), update(txn), softDelete(id), restore(id), hardDeleteExpired(),
        listByDay(bookIds, dayKey), listRange(filter), listRecent(limit),
        moveToBook(fromBookId, toBookId), sumRange(filter),
        countByBook(bookId), countByMember(memberId), countByCategory(categoryId)
BudgetDao: get(bookId, period), upsert(bookId, period, amountCents), list(period), remove(bookId, period)
```

`filter` 定义为 `class TxnFilter { bookIds: string[] = []; memberIds: string[] = []; startMs: number = 0; endMs: number = 0; }`。

### 4.4 默认账本唯一

- `BookDao.setDefault(id)` 在一个事务里：先把所有 `is_default` 置 0，再把目标置 1。
- 删除默认账本：若还有其他未归档账本，必须先指定新默认；否则拒绝删除并返回明确错误。

### 4.5 基线种子（幂等）

仅在 `app_meta.seed_version` 为空或小于当前值时执行：

- 账本：`日常账本`（默认，icon `ic_book_daily`，color `#2A78D6`）；`旅行`（`ic_book_travel`，`#EB6834`）；`装修`（`ic_book_repair`，`#1BAF7A`，无预算）。
- 成员：`自己`（默认，`#2A78D6`）、`家人`（`#C94B7B`）、`孩子`（`#137A57`）。
- 分组：餐饮、出行、居家、购物、休闲、其他（`is_system=1`）。
- 分类（10 个）：餐饮/交通/居家/购物/娱乐/医疗/学习/水电/通讯/其他，图标与颜色见设计规范 §4.4。
- **不写入预算与流水。**

种子执行后写 `seed_version=1`。

### 4.6 演示数据

`DebugSeedService.seedDemo(context)`：

- 清空业务表后写入 4 个账本（日常/旅行/家庭/装修，家庭为私密但密码为空，仅供 UI 演示打码）、30 笔本月流水、日常 ¥3000 与旅行 ¥8000 预算。
- 仅被 `GalleryPage` 的调试按钮调用，不接入任何正式入口。
- 方法内先判断 `BuildProfile.DEBUG`（`BuildProfile` 由 SDK 生成），非 debug 直接返回。

### 4.7 Mapper

```ts
static toBook(rs: relationalStore.ResultSet): Book {
  return {
    id: rs.getString(rs.getColumnIndex('id')),
    // ...
    isPrivate: rs.getLong(rs.getColumnIndex('is_private')) === 1
  };
}
```

- 禁止 `as`、禁止按索引硬编码（必须 `getColumnIndex`）。
- `getString` 对可空列返回 `''`，Mapper 需用 `rs.isColumnNull(index)` 判断后转 `null`。

## 5. 验收标准

| 编号 | 验收项 | 验证方式 |
|---|---|---|
| AC-1 | 冷启动完成建表，`hilog` 输出 `DB ready, version=1` | 真机日志 |
| AC-2 | 连续启动 3 次，账本仍为 3 条、分类仍为 10 条，无重复种子 | 查询日志 / 调试页计数 |
| AC-3 | 账本/成员/分类/流水/预算五类 CRUD 均可用，软删后列表不返回、`restore` 后恢复 | 临时调试调用 + 日志 |
| AC-4 | 默认账本全局唯一（直接查库验证 `SUM(is_default)=1`） | 调试页执行 `setDefault` 两次后查库 |
| AC-5 | 金额以整数分存储：写入 1234 读出 1234，无浮点误差 | 调试用例 |
| AC-6 | 按 `dayKey` 查询当天流水正确（跨时区边界用 00:00 与 23:59 各插一条验证） | 调试用例 |
| AC-7 | `Archive` 账本后不出现在默认列表；有流水的账本删除被拒绝并提示归档 | 调试操作 |
| AC-8 | 演示数据可生成且不污染正式入口 | 打开 Gallery 执行 seedDemo |
| AC-9 | 构建通过 | `devecocli build` |

## 6. 注意事项

- RdbStore 线程安全但**不支持 Worker**，不要尝试把 DAO 放进 taskPool。
- 全部金额使用 `INTEGER`；SQLite 的 `REAL` 一律禁止出现在金额列。
- 分类被流水引用时只能归档，不能硬删除；`CategoryDao.delete` 内部先检查引用数。
- 删除账本有流水的场景：v1 只允许归档（设计 §10.3）。
- 不要引入 ORM 或第三方数据库库。
