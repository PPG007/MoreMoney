# T12 · 预算页

> 状态：已完成 ｜ 优先级：P1 ｜ 依赖：T05、T11 ｜ 预估：2.0 人日
> 设计依据：`设计规范.md` §8.3、§9.5、§9.3；截图 `07-budget-light.png`、`08-budget-dark.png`

## 1. 目标

实现一级页“预算”：预算合计三列、主预算环形卡、待设置预算空状态、其他账本预算行，并严格落地“只统计已设预算且已解锁账本”的口径。

## 2. 交付物

| 路径 | 内容 |
|---|---|
| `entry/src/main/ets/pages/budget/BudgetPage.ets` | 页面与数据 |
| `entry/src/main/ets/pages/budget/BudgetSummary.ets` | 三列摘要 |
| `entry/src/main/ets/pages/budget/MainBudgetCard.ets` | 主预算卡 + 环 |
| `entry/src/main/ets/pages/budget/BudgetBookRow.ets` | 其他账本行 |
| `entry/src/main/ets/pages/budget/UnsetBudgetCard.ets` | 待设置预算空状态卡 |
| `entry/src/main/ets/pages/budget/BudgetEditDialog.ets` | 设置本月预算（T08 复用） |
| `entry/src/main/ets/components/chart/RingProgress.ets` | Canvas 环形进度（116，stroke 11） |
| `entry/src/main/ets/service/BudgetService.ets` | 预算口径计算 |

## 3. 页面结构

```text
Column
├── 头部：标题“预算”25/700 + 月份切换 + EyeButton
├── 三列摘要卡：预算合计 / 已用 / 剩余
├── 主预算卡：RingProgress 116 + 三项数字 + 每天可用
├── “待设置预算”区块：标题 + 计数 + 空状态卡（每个无预算账本一张）
├── “其他账本”区块：BudgetBookRow × N
└── 底部口径说明 10/400 ink_3
```

## 4. 实现要求

### 4.1 数据口径（BudgetService）

```ts
export class BudgetService {
  static async getOverview(monthKey: string): Promise<BudgetOverview>
  static async setBudget(bookId: string, period: string, cents: number): Promise<void>
  static async removeBudget(bookId: string, period: string): Promise<void>
}

export class BudgetBookView {
  bookId: string = '';
  name: string = '';
  color: string = '';
  budgetCents: number = 0;
  spentCents: number = 0;
  remainingCents: number = 0;
  percent: number = 0;        // 0–∞，UI 夹在 0–1 绘制
  isPrivate: boolean = false;
  isLocked: boolean = false;
}

export class BudgetOverview {
  totalCents: number = 0;
  spentCents: number = 0;
  remainingCents: number = 0;
  perDayCents: number = 0;
  mainBook: BudgetBookView | null = null;   // 默认账本
  others: BudgetBookView[] = [];
  unset: BudgetBookView[] = [];             // 未设置预算
}
```

规则：

1. 只统计 `budget` 表存在当前月记录、且账本未归档、且（非私密或已解锁）的账本。
2. 锁定的私密账本：不出现在合计，也不出现在“其他账本”；如需展示，只在“未解锁”提示中计数（v1 直接隐藏该行）。
3. 未设置预算的账本进入 `unset`，不计入任何合计。
4. `spentCents` 用 `StatsService.sum`（`bookIds=[bookId]`，当月范围）。
5. `remainingCents = total - spent`，可为负；`perDayCents = max(0, remaining) / 本月剩余天数`，剩余天数含今天且至少 1。
6. `mainBook` = 默认账本且已设预算；若默认账本未设预算，则取“第一个已设预算账本”；都没有则为 null。

### 4.2 三列摘要

- `AppCard` padding `13 0`、圆角 20；三列等分，列间 1vp `line` 竖线（可用 `Divider`）。
- 数字 17/700（预算合计 `ink`，已用 `expense`，剩余 `good`；剩余为负时 `expense`）。
- 标签 10/400 `ink_3`。
- 隐藏金额时三个数字全部打码。

### 4.3 主预算卡

- padding 17、圆角 24、`margin-top 13`，背景 `surface`。
- 左：`RingProgress` 116×116，stroke 11，轨道 `surface_2`，填充渐变 `brand → brand_ink`；中心 24/700 显示百分比（四舍五入，>999% 显示 `999%+`）。
- 右：三行数字 13/700：`预算 ¥3,000.00`、`已用 ¥1,286.40`、`剩余 ¥1,713.60`，行距 8；标签 10/400。
- 底部：`每天可用 ¥57.11` 胶囊，padding `9 11`、圆角 11、`brand_wash` 底、`brand_ink` 字 10/600。
- 超支：环填满并变 `expense`，百分比文字 `expense`，剩余显示负数。
- 隐藏金额：中心百分比保留（设计允许比例可见），三项数字与每天可用打码；环填充隐藏（只留轨道）。

### 4.4 待设置预算

- 区块头：标题 12/700 + 计数 10/400 `ink_3`。
- 每个无预算账本一张卡：padding 15、圆角 20、1.5vp dashed `line`、`brand_wash` 55% 底。
- 内容：图标 42×42（圆角 13，`brand_wash`/`brand_ink`）+ 账本名 12/700 + “还没有设置本月预算”10/400 + “未设置前不计入合计”10/400 `ink_3`。
- 底部主按钮“设置预算”40 高，点击打开本任务交付的 `BudgetEditDialog`（T08 复用同一弹层）。
- 设置成功后卡片从该区块移到“其他账本”，合计刷新。

### 4.5 其他账本

- 行：`36px 1fr auto`，gap 11，padding `12 13`，圆角 20，`surface` 底。
- 左：账本色封面 36（圆角 12，图标 19）。
- 中：名称 13/700 + 进度条 5 + `已用 ¥x / 剩余 ¥y` 10/400。
- 右：百分比 14/700（`ink`；超支 `expense`）。
- 点击行：滚动到主预算卡并高亮 300ms（或打开预算编辑弹层，二选一，需在实现中固定）。
- 无进度条时显示 5 高轨道。

### 4.6 空状态

- 所有账本都未设预算：主预算卡位置替换为居中空状态（图标 `ic_tab_budget`、标题“还没有预算”、说明“先给一个账本设置月度预算”），CTA“设置预算”。
- 所有账本都有预算：不显示“待设置预算”区块。

### 4.7 月份与眼睛

- 月份切换与首页一致：`32/700` + 左右箭头；切换后重新计算整页。
- 眼睛按钮切换全局 `hideAmount`。
- 状态栏图标深色。

## 5. 验收标准

| 编号 | 验收项 | 验证方式 |
|---|---|---|
| AC-1 | 视觉与 `07-budget-light.png` 对齐；深色与 `08-budget-dark.png` 对齐 | 截图比对 |
| AC-2 | 合计 = 所有“已设预算且已解锁且未归档”账本之和；未设预算不计入 | 造数验证 |
| AC-3 | 私密锁定账本不计入合计、不显示金额 | 真机 + T13 |
| AC-4 | 主预算环百分比与已用/预算一致，超支时变红且剩余为负 | 造数验证 |
| AC-5 | 每天可用 = 剩余 / 本月剩余天数（含今天），剩余为负时为 0 | 手工计算比对 |
| AC-6 | 待设置预算卡显示正确，点击“设置预算”可写入并刷新 | 真机 |
| AC-7 | 切换月份/账本变化后整页数据同步 | 真机 |
| AC-8 | 眼睛按钮切换后金额与环填充隐藏，比例文字保留 | 真机 |
| AC-9 | 无任何预算时显示空状态 | 清空预算验证 |
| AC-10 | 构建通过 | `devecocli build` |

## 6. 注意事项

- 环用 Canvas 绘制，不用 `Progress(Ring)`，因为需要渐变填充与末端圆点（末端圆点本页可选，若实现需与设计一致）。
- 百分比保留整数；不要用浮点累加金额。
- 本页不负责设置预算的表单，弹层由 T08 提供。
- 隐藏金额时不要用 `blur`，统一打码。
