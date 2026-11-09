# T06 · 记账本首页

> 状态：已完成 ｜ 优先级：P1 ｜ 依赖：T03、T05 ｜ 预估：2.0 人日
> 设计依据：`设计规范.md` §8.1、§9.3、§9.6；截图 `01-home-light.png`、`02-home-dark.png`、`20-home-hide-light.png`

## 1. 目标

实现一级页“记账本”：Hero 渐变头、账本切换、月份切换、本月支出摘要卡、成员筛选、按天分组流水、FAB。这是用户打开 App 的第一屏，视觉还原度要求最高。

## 2. 交付物

| 路径 | 内容 |
|---|---|
| `entry/src/main/ets/pages/home/HomePage.ets` | 页面容器与数据加载 |
| `entry/src/main/ets/pages/home/HomeHero.ets` | Hero 区（标题、月份、账本 chips） |
| `entry/src/main/ets/pages/home/SummaryCard.ets` | 本月支出摘要卡 |
| `entry/src/main/ets/pages/home/TxnRow.ets` | 通用流水行（后续预算/搜索复用） |
| `entry/src/main/ets/pages/home/DayHeader.ets` | 按天分组头 |
| `entry/src/main/ets/components/base/BookChip.ets` | 账本切换胶囊 |

## 3. 页面结构

```text
Stack(Alignment.TopEnd)
├── List
│   ├── ListItem
│   │   └── Column
│   │       ├── HomeHero                // 延伸到状态栏下
│   │       └── SummaryCard             // margin-top: -54
│   ├── ListItem                        // “最近记录”标题 + 成员筛选 chips
│   ├── ForEach(days)
│   │   └── ListItemGroup(header: DayHeader)   // sticky
│   │       └── ForEach(txns) → TxnRow
│   └── ListItem                        // 底部留白 150
└── 新增 FAB (70, right 16, bottom bottomInset+76)
```

## 4. 实现要求

### 4.1 数据加载

`reload()` 读取：

1. `BookDao.list()`（未归档）；
2. 当前选中账本（默认 = `isDefault` 的账本；可选 `all`）；
3. 当前月份 `monthKey` 的流水：`TxnDao.listRange(filter)`；
4. 摘要：本月 `SUM(amount_cents)`；预算口径：
   - 选中单个账本 → 该账本本月预算；
   - 选中“全部” → 所有“已设置预算且未锁定”的账本预算之和（未设置预算的账本不参与）；
   - 无预算 → 显示“未设置预算”。

- 私密且未解锁的账本：流水金额不参与摘要合计，行内金额由 `MoneyText` 打码；账本可在列表中显示名称。
- 成员筛选项来自 `MemberDao.list()`，`全部` + 每个成员，单选。
- 账本切换、月份切换、成员筛选只影响本地列表与摘要，不重新建库查询整表。

### 4.2 Hero

- 渐变：`linearGradient({ angle: 152, colors: [[$r('app.color.hero_a'), 0], [$r('app.color.hero_b'), 0.52], [$r('app.color.hero_c'), 1]] })`。
- padding：`topInset + 10`、左右 20、底部 78；底部圆角 30。
- 第一行：标题“记账本”25/700 `on_hero`；右侧 EyeButton（Hero 风格，36 圆，`hero_glass` 底 + `hero_line` 边）。
- 第二行：月份 `32/700`（`11月`）+ 左右箭头（Hero 按钮 36），点击切换月份并调用 `reload()`。
- 第三行：横向 `Scroll` 的账本 chips：`全部` + 每个账本。
  - 未选中：透明底 + `hero_line` 边；选中：`hero_glass` 底。
  - 结构：封面 22（圆角 7）+ 名称 10/600 + 私密锁图标 12。
  - 高度 34，padding `6 10 6 6`，圆角 12，间距 6。
- 状态栏文字白色（`SystemBarService.setStatusBarDarkText(false)`）。

### 4.3 摘要卡

- `AppCard`：padding 19、圆角 24，`margin: { left: 16, right: 16, top: -54 }`，背景 `surface`。
- 第一行：标签“本月支出”10/400 `ink_3` + 金额 `MoneyText` 42/700 `expense`，`signed` 为 true（显示 `−¥1,286.40`）。
- 第二行：预算进度条，高 8、圆角 999、轨道 `surface_2`、填充 `brand → brand_ink` 渐变；末端白点 12 + 3vp `brand_ink` 描边。百分比 = 已用/预算，夹在 0–1；无预算时不显示进度条，改显示“未设置预算”+ 迷你“去设置”按钮（跳预算页）。
- 第三行：3 列等分，数字 16/700、标签 10/400 `ink_3`：
  - 预算（`budgetCents`，无预算显示 `—`）
  - 每天可用（`max(0, (budget - spent) / 本月剩余天数)`，保留 2 位）
  - 剩余（`budget - spent`，负数用 `expense` 色）
- 金额隐藏时：大金额变 `¥••••`，进度条填充隐藏（轨道保留），三列数字打码。

### 4.4 流水列表

- “最近记录”区块标题 14/700，右侧成员筛选 chips（横向滚动，高度 28，圆角 999，选中 `brand_wash`/`brand_ink`）。
- 按 `dayKey` 分组，组头 sticky：
  - 左侧 5vp 圆点 `brand` + 日期文案 10/600 `ink_2`（`11月9日 周一`）；
  - 右侧当天合计 `MoneyText` 10/600 `ink_2`。
- `TxnRow`：`Row { 图标 42×42(圆角 14, 分类色 13% 底, 图标 21) ; Column{标题 13/600 单行省略; 副行 10/400 ink_3：成员首字圆点 15 + 备注或分类名} ; 金额 14/700 expense }`，padding `11 13`，行间 1vp `line`，整行卡片圆角 20（每组首尾圆角）。
- 同一天最多显示 20 条，超出显示“其余 N 笔”，点击展开当天全部（不跳转页面）。

### 4.5 交互

- FAB 点击：`pathStack.pushPathByName('AddTxn', new AddTxnParam(selectedBookId), onPop → reload)`。
- 秒开体验：首帧先渲染骨架（Hero + 卡片灰块），数据回来再替换。
- 下拉刷新：`Refresh` 包裹 List，`onRefreshing` 调 `reload()`。
- 空列表：`EmptyState`（图标 `ic_cat_other`、标题“本月还没有记账”、说明“点右下角 + 记一笔”），不显示空卡片。
- 切换 Tab 离开再回来：保持月份与账本选择（页面实例不销毁）。

## 5. 导航参数

新增：

```ts
export class AddTxnParam {
  bookId: string = '';
  dayKey: string = '';
}
```

`AddTxnParam` 放在 `models/NavParams.ets`，由 T07 使用。

## 6. 验收标准

| 编号 | 验收项 | 验证方式 |
|---|---|---|
| AC-1 | 视觉与 `01-home-light.png` 对齐：Hero 渐变、负 margin 摘要卡、分组流水、FAB 位置 | 真机截图逐项比对 |
| AC-2 | 深色模式与 `02-home-dark.png` 对齐 | 系统深色截图比对 |
| AC-3 | 点击眼睛按钮，摘要金额、进度条、三列数字、每日小计、流水金额全部打码，图形不变形 | 对照 `20-home-hide-light.png` |
| AC-4 | 切换月份，列表与摘要同步变化；1 月/12 月边界可正常前后切换 | 真机操作 |
| AC-5 | 切换账本 chip，摘要与流水只显示该账本；选“全部”显示所有未锁定账本 | 真机 + 种子数据 |
| AC-6 | 成员筛选生效，结果计数与列表一致 | 真机 |
| AC-7 | 从 FAB 进入记一笔，保存后返回首页自动刷新，新记录出现在对应日期分组 | 真机 |
| AC-8 | 无预算账本显示“未设置预算”，点击跳转预算页 | 真机 |
| AC-9 | 私密账本未解锁时金额打码且不计入摘要 | DebugSeed 后验证 |
| AC-10 | 构建通过 | `devecocli build` |

## 7. 注意事项

- Hero 不要放进单独的 `Scroll` 再套 `List`（嵌套滚动会卡顿）；按 3 节结构用单个 `List`。
- 摘要卡负 margin 用 `Column` 内布局实现，不要用绝对定位。
- 金额计算只用 `TxnDao.sumRange` + `MoneyUtil`，不要在页面循环累加浮点数。
- 状态栏图标颜色在进入页面时切换，离开时由目标页负责切换。
