# T19 · CSV 导出

> 状态：已完成 ｜ 优先级：P3 ｜ 依赖：T03、T11 ｜ 预估：1.5 人日
> 设计依据：`设计规范.md` §10.6、§8.8

## 1. 目标

按设计约定的 CSV 格式导出流水，用户通过系统文件选择器保存到本地或网盘目录。锁定私密账本不导出。

## 2. 交付物

| 路径 | 内容 |
|---|---|
| `entry/src/main/ets/service/CsvExportService.ets` | 查询、序列化、写文件 |
| `entry/src/main/ets/service/CsvFormat.ets` | 转义、BOM、行拼接（纯函数） |
| `entry/src/main/ets/components/sheet/ExportFilterSheet.ets` | 日期/账本/成员筛选弹层 |
| `entry/src/test/CsvFormat.test.ets` | 转义单测 |

## 3. 格式

```csv
date,time,type,book,group,category,member,amount,note,id
2026-11-09,12:30,expense,日常账本,餐饮,餐饮,自己,32.00,午餐,uuid
```

规则：

1. 编码 UTF-8 **带 BOM**（`EF BB BF`）；换行 `CRLF`。
2. 逗号分隔；字段包含逗号、双引号、换行时用双引号包裹，内部双引号写成 `""`。
3. 日期 `YYYY-MM-DD`；时间 `HH:mm`（24 小时，本地时区）。
4. `type` 固定 `expense`。
5. 金额两位小数、无千分位、无货币符号。
6. 公式注入转义：字段以 `= + - @` 开头时，在前面加单引号 `'`（在加引号之前处理）。
7. 表头固定顺序，不随筛选变化。
8. 文件名：`MoreMoney_YYYYMMDD_HHmm.csv`。

## 4. 实现要求

导入来源：`picker`、`fileIo` 来自 `@kit.CoreFileKit`，`util` 来自 `@kit.ArkTS`。

### 4.1 筛选

`ExportFilterSheet`：

- 日期范围：默认本月；快捷项 本月/本年/全部/自定义；自定义用两个 `DatePickerDialog`，起 ≤ 止。
- 账本：多选列表（默认全选未归档且未锁定）；锁定私密账本置灰并标注“需先解锁”，或直接隐藏（与 T13 一致，推荐隐藏）。
- 成员：多选（默认全选）。
- 底部主按钮“导出”，显示预计笔数（`count` 查询）。

### 4.2 查询

- 复用 `TxnDao.listRange(filter)`，联表取 `book.name`、`category_group.name`、`category.name`、`member.name`。
- 只导出 `deleted_at IS NULL`、账本未归档、未锁定私密账本。
- 按 `occurred_at ASC` 输出（便于阅读），与界面排序无关。

### 4.3 写文件

```ts
const context: Context = getContext(this);
const picker = new picker.DocumentViewPicker(context);
const uris = await picker.save({ newFileNames: [fileName] });
const file = fileIo.openSync(uris[0], fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
fileIo.writeSync(file.fd, bytes);
fileIo.closeSync(file);
```

- 用户取消选择器：不提示错误，静默返回。
- 写入失败：`SnackBar` 提示“导出失败，请重试”，并在 hilog 记录。
- 导出期间显示加载态（按钮转圈、禁用），防止重复点击。
- 数据量大时按 500 行分批拼接字符串，避免一次性大字符串；写入仍可单次完成（v1 上限 20000 行）。

### 4.4 结果

- 成功：`SnackBar`“已导出 128 笔记录”，并记录最近导出时间（可选）。
- 失败/取消：对应提示或静默。

## 5. 验收标准

| 编号 | 验收项 | 验证方式 |
|---|---|---|
| AC-1 | 导出文件可用 Excel/WPS 打开，中文无乱码 | 真机导出后在电脑打开 |
| AC-2 | 首行表头与第 3 节完全一致 | 文本检查 |
| AC-3 | 含逗号、引号、换行的备注往返正确 | 单测 + Excel 检查 |
| AC-4 | 以 `=SUM(A1)` 开头的备注导出后为 `'=SUM(A1)` | 单测 |
| AC-5 | 金额 `32.00`、日期/时间格式正确 | 文本检查 |
| AC-6 | 筛选日期/账本/成员后，导出条数与界面预计一致 | 真机比对 |
| AC-7 | 锁定私密账本数据不在导出结果中 | 真机 + T13 |
| AC-8 | 1000 条数据导出耗时 < 2 秒（真机中端机） | 计时 |
| AC-9 | 用户取消保存不报错 | 真机 |
| AC-10 | 构建通过 | `devecocli build` |

## 6. 注意事项

- 必须写 BOM，否则 Excel 打开中文乱码。
- 不要用 `fileIo.write` 写 `string` 的默认编码假设；显式 `TextEncoder` 转 `Uint8Array`。
- 导出走异步，不阻塞 UI；不要在 `build()` 中触发。
- 公式注入转义只作用于文本字段（book/group/category/member/note），数字字段不受影响。
