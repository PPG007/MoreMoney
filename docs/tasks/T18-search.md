# T18 · 全局搜索

> 状态：待开始 ｜ 优先级：P3 ｜ 依赖：T03、T05、T13 ｜ 预估：1.0 人日
> 设计依据：`设计规范.md` §8.9；截图 `18-search-light.png`

## 1. 目标

实现二级页“搜索”：按备注、分类、成员搜索流水，展示带日期的结果，支持最近搜索；锁定私密账本不参与。

## 2. 交付物

| 路径 | 内容 |
|---|---|
| `entry/src/main/ets/pages/search/SearchPage.ets` | 页面 |
| `entry/src/main/ets/components/sheet/TxnDetailSheet.ets` | 结果详情弹层 |
| `entry/src/main/ets/data/db/TxnDao.ets` | 新增 `search(keyword, limit)` |

## 3. 页面结构

```text
NavDestination
├── 头部：返回 34 / 搜索框 36（圆角 999）/ EyeButton 34
├── 最近搜索：标题 10/600 + chips（最多 10 个）
└── 结果区：
    ├── 计数 “找到 12 笔”
    └── 结果行（复用 TxnRow，副行带日期）
```

## 4. 实现要求

### 4.1 搜索

- 输入防抖 300ms；空关键词显示最近搜索，不查询。
- 关键词去首尾空格；长度 ≥ 1 才查询。
- 匹配范围：`txn.note LIKE %kw%`、`category.name LIKE %kw%`、`member.name LIKE %kw%`（三者 OR）。
- 排除：`deleted_at IS NOT NULL`、归档账本、锁定私密账本（`excludeBookIds`）。
- 排序：`occurred_at DESC, created_at DESC`；最多 200 条，超出提示“结果过多，请细化关键词”。
- 结果行：副行显示 `11月9日 · 餐饮 · 自己`；金额由 `MoneyText` 渲染（带 `locked` 以便私密账本打码）。
- SQL 使用 `bindArgs` 传 `%kw%`，不要拼接字符串。

### 4.2 最近搜索

- 搜索提交（输入停顿且有关键词）后写入 `SettingsService.recentSearches`：去重、最新在前、最多 10 个。
- chips：padding `5 9`、圆角 999、`surface_2` 底、10/500；点击填入搜索框并立即查询。
- 右上角“清空”10/600 `brand_ink`，点击清空并刷新。

### 4.3 详情

- 点击结果行打开 `TxnDetailSheet`（底部弹层，圆角 28）：
  - 分类图标 42 + 分类名 13/700 + 金额 20/700
  - 账本、成员、日期、备注（完整，可滚动）
  - 底部“关闭”次级按钮
- v1 不提供编辑/删除入口（避免与撤销机制冲突）；如需删除，回到首页长按流水（T23）。

### 4.4 空态

- 无结果：图标 `ic_search` + “没有找到相关记录” + “试试备注、分类或成员名”。
- 无最近搜索：不显示该区块。

## 5. 验收标准

| 编号 | 验收项 | 验证方式 |
|---|---|---|
| AC-1 | 视觉与 `18-search-light.png` 对齐 | 截图比对 |
| AC-2 | 备注、分类名、成员名三种关键词都能命中 | 真机 |
| AC-3 | 结果按时间降序，副行包含日期/分类/成员 | 真机 |
| AC-4 | 锁定私密账本的记录不出现在结果中 | 真机 + T13 |
| AC-5 | 最近搜索最多 10 条、去重、重启后保留 | 真机 |
| AC-6 | 清空最近搜索生效 | 真机 |
| AC-7 | 点击结果打开详情，金额受全局隐藏影响 | 真机 |
| AC-8 | 无结果/无最近搜索状态正确 | 真机 |
| AC-9 | 构建通过 | `devecocli build` |

## 6. 注意事项

- 不要每次按键都查库；必须防抖。
- `LIKE` 对中文有效，但大小写对英文不敏感需 `COLLATE NOCASE`（SQLite LIKE 默认对 ASCII 不区分大小写）。
- 结果不显示账本名时可点击详情查看；若需要，可在副行追加账本名（不超过一行）。
