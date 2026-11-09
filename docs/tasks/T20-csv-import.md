# T20 · CSV 导入

> 状态：待开始 ｜ 优先级：P3 ｜ 依赖：T03、T19 ｜ 预估：2.0 人日
> 设计依据：`设计规范.md` §10.6、§8.8

## 1. 目标

导入设计约定格式的 CSV：先全量校验、再事务写入；错误带行号，重复数据按 `id` 跳过；缺失的账本/分类/成员自动创建。

## 2. 交付物

| 路径 | 内容 |
|---|---|
| `entry/src/main/ets/service/CsvParser.ets` | RFC4180 解析（引号、转义、换行） |
| `entry/src/main/ets/service/CsvImportService.ets` | 校验、预览、事务写入 |
| `entry/src/main/ets/components/sheet/ImportPreviewSheet.ets` | 预览与错误列表 |
| `entry/src/test/CsvParser.test.ets` | 解析单测 |

## 3. 输入格式

表头必须完全一致，顺序固定：

```csv
date,time,type,book,group,category,member,amount,note,id
```

- 编码：UTF-8，允许带 BOM（读取后剥离）。
- 换行：`\r\n` 或 `\n` 均可。
- 字段可带引号；引号内可含逗号、换行；`""` 表示一个 `"`。
- 空行跳过。
- 文件上限 5 MB、20000 行；超出直接拒绝并提示。

## 4. 解析实现

```ts
export class CsvRow { cells: string[] = []; lineNumber: number = 0; }
export class CsvParser {
  static parse(text: string): CsvRow[];   // 抛 CsvSyntaxError（带行号）
}
```

- 手写状态机，支持 quoted field 跨行；不得用 `split(',')`。
- 行号按物理行计数，报错时指向起始行。
- 引号未闭合、引号后出现非分隔字符 → 语法错误。

## 5. 校验规则

`CsvImportService.preview(text)` 返回：

```ts
export class ImportError { line: number = 0; message: string = ''; }
export class ImportPreview {
  total: number = 0;
  toInsert: number = 0;
  duplicates: number = 0;
  newBooks: string[] = [];
  newCategories: string[] = [];
  newMembers: string[] = [];
  errors: ImportError[] = [];
  rows: Txn[] = [];
}
export class ImportResult { inserted: number = 0; skipped: number = 0; }
```

逐行校验：

| 字段 | 规则 |
|---|---|
| date | `YYYY-MM-DD`，必须是真实日期 |
| time | `HH:mm`，0–23 / 0–59 |
| type | 必须为 `expense`，否则报错（保留字段） |
| book | 非空；不存在则创建（非私密、非默认、无预算） |
| group | 非空；不存在则创建（`is_system=0`） |
| category | 非空；不存在则创建，挂到对应分组，图标 `ic_cat_other`，颜色按调色板轮转 |
| member | 非空；不存在则创建，颜色按调色板轮转 |
| amount | 正则 `^\d+(\.\d{1,2})?$`，> 0，≤ ¥99,999,999.99 |
| note | 可空，≤ 100 字；若以 `'` 开头且第二字符为 `= + - @`，去掉前导 `'`（还原导出时的转义） |
| id | 可空；为空生成 UUID；非空且库中已存在 → 跳过（计入 duplicates，不报错） |

- 同一文件内重复 `id`：保留第一条，后续计为重复。
- 任何一行校验失败 → `errors` 累积；**有错误时禁止导入**（整体原子）。
- 自动创建项在预览中列出名称，用户确认后创建。

## 6. 写入

1. 用户点击“确认导入”：
   - 重新执行一次预览校验（防止文件被改）；
   - `store.createTransaction()` 包裹：创建缺失的账本/分组/分类/成员 → 批量插入流水；
   - 任一步失败 → 回滚，提示“导入失败，未写入任何数据”。
2. 写入完成后：
   - 刷新分类/成员缓存；
   - `SnackBar`“导入 128 笔，跳过 2 笔重复”；
   - 返回数据页。
3. 私密账本相关：CSV 不区分私密；导入时缺失账本一律创建为非私密。若同名私密账本已存在，则写入该账本，但**需要该账本已解锁**；未解锁则报错并阻止导入。
4. 导入不修改已有流水的分类/成员引用。

## 7. 预览弹层

- 标题“导入预览”；统计：总行数、可导入、重复、错误。
- 自动创建项：三行胶囊列表（新账本 / 新分类 / 新成员）。
- 错误列表：最多显示 10 条，格式 `第 12 行：金额格式不正确`，可滚动；超过显示“还有 N 条”。
- 按钮：取消 / 确认导入（有错误时禁用）。

## 8. 验收标准

| 编号 | 验收项 | 验证方式 |
|---|---|---|
| AC-1 | 导出文件原样导入，条数与金额完全一致（往返一致） | 真机导出→导入 |
| AC-2 | 含逗号、引号、换行的备注解析正确 | 单测 + 真机 |
| AC-3 | 未闭合引号报语法错误并给出行号 | 单测 |
| AC-4 | 未知账本/分组/分类/成员自动创建，预览中列出 | 真机 |
| AC-5 | 重复 `id` 跳过且不报错，计数正确 | 真机 |
| AC-6 | 任一行金额非法时整体不写入，错误行号正确 | 真机 |
| AC-7 | 写入过程失败会回滚（可用只读库模拟） | 代码审查/异常注入 |
| AC-8 | 20000 行上限与 5MB 上限生效 | 造大文件 |
| AC-9 | 导入后首页/分类/成员立即可见 | 真机 |
| AC-10 | 构建通过 | `devecocli build` |

## 9. 注意事项

- 必须整文件校验后再写，禁止边解析边插入。
- 自动创建实体会改变“常用分类”排序，导入后刷新即可，不需特殊处理。
- 不要复用导出时的日期时间字符串做毫秒拼接；用 `DateUtil` 明确构造本地时间。
- 解析器是纯函数，禁止依赖 Context/DAO，方便单测。
