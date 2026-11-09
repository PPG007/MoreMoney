# T05 · 通用组件与全局状态

> 状态：已完成 ｜ 优先级：P0 ｜ 依赖：T01、T02 ｜ 预估：1.5 人日
> 设计依据：`设计规范.md` §7.2、§7.3、§7.4、§9.3、§9.6

## 1. 目标

提供全项目复用的基础组件、全局 UI 状态、设置持久化与通用工具，后续页面只做组合，不重复实现按钮/卡片/金额文本/提示条。

## 2. 交付物

| 路径 | 内容 |
|---|---|
| `entry/src/main/ets/state/GlobalUiStore.ets` | 扩展 T02 的 `@ObservedV2` 全局状态（隐藏金额、SnackBar、解锁） |
| `entry/src/main/ets/state/UiStore.ets` | `UiStore.instance()` 访问器 |
| `entry/src/main/ets/service/SnackBarService.ets` | 提示条队列 |
| `entry/src/main/ets/service/SettingsService.ets` | Preferences 读写 |
| `entry/src/main/ets/utils/DateUtil.ets` | dayKey/月份/周起点/日历计算 |
| `entry/src/main/ets/utils/ErrorUtil.ets` | 错误信息归一化 |
| `entry/src/main/ets/utils/IdUtil.ets` | UUID |
| `entry/src/main/ets/components/base/MoneyText.ets` | 金额文本（含隐藏/打码） |
| `entry/src/main/ets/components/base/AppCard.ets` | 通用卡片 |
| `entry/src/main/ets/components/base/PrimaryButton.ets` | 主按钮 |
| `entry/src/main/ets/components/base/SecondaryButton.ets` | 次级按钮 |
| `entry/src/main/ets/components/base/IconButton.ets` | 圆形图标按钮 |
| `entry/src/main/ets/components/base/EyeButton.ets` | 眼睛按钮 |
| `entry/src/main/ets/components/base/Badge.ets` | 徽标 |
| `entry/src/main/ets/components/base/SectionHeader.ets` | 区块标题 |
| `entry/src/main/ets/components/base/ListRow.ets` | 设置/列表行 |
| `entry/src/main/ets/components/base/ToggleRow.ets` | 开关行 |
| `entry/src/main/ets/components/base/EmptyState.ets` | 空状态 |
| `entry/src/main/ets/components/base/SegmentedControl.ets` | 分段控件 |
| `entry/src/main/ets/components/base/AmountBar.ets` | 进度条（预算/排行共用） |
| `entry/src/main/ets/components/base/MemberDot.ets` | 成员首字圆点 |
| `entry/src/main/ets/components/base/SnackBarHost.ets` | 全局提示条宿主 |
| `entry/src/main/ets/pages/dev/GalleryPage.ets` | 组件样例页（`@Preview`，不接入路由） |

## 3. 实现要求

### 3.1 GlobalUiStore

```ts
@ObservedV2
export class GlobalUiStore {
  @Trace hideAmount: boolean = false;      // 会话内有效，不持久化
  @Trace isDark: boolean = false;
  @Trace topInset: number = 0;             // vp
  @Trace bottomInset: number = 0;          // vp
  @Trace snackbar: SnackBarState = new SnackBarState();
  @Trace unlockVersion: number = 0;        // 解锁状态变化时 +1

  unlockedUntil: Record<string, number> = {}; // bookId -> 过期时间戳

  isBookUnlocked(bookId: string): boolean;
  unlockBook(bookId: string, minutes: number): void; // 默认 5 分钟
  lockBook(bookId: string): void;
  lockAllPrivate(): void;
}
```

- `unlockedUntil` 不做深观察，任何变更后 `unlockVersion += 1` 触发刷新。
- `isDark` 由 `EntryAbility.onConfigurationUpdate` 写入：`config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK`。
- `hideAmount` **不持久化**：冷启动默认显示金额。

组件中统一这样取：

```ts
@Local ui: GlobalUiStore = UiStore.instance();
```

`UiStore.instance()` 内部使用 `AppStorageV2.connect(GlobalUiStore, 'globalUi', () => new GlobalUiStore())`；若返回 `undefined`，用模块级缓存兜底，保证所有组件拿到**同一个**实例：

```ts
let fallback: GlobalUiStore | undefined;
static instance(): GlobalUiStore {
  const shared = AppStorageV2.connect(GlobalUiStore, 'globalUi', () => new GlobalUiStore());
  if (shared !== undefined) { return shared; }
  fallback = fallback ?? new GlobalUiStore();
  return fallback;
}
```

### 3.2 MoneyText

```ts
@ComponentV2
export struct MoneyText {
  @Param cents: number = 0;
  @Param size: number = AppFont.body;        // 14
  @Param weight: number = AppFont.bold;
  @Param tone: MoneyTone = MoneyTone.Ink;    // Ink | Expense | Good | OnHero | Inherit
  @Param showSymbol: boolean = true;
  @Param signed: boolean = false;            // true 时前缀 −
  @Param locked: boolean = false;            // 私密且未解锁时由调用方传 true
  @Param forceVisible: boolean = false;
  @Local ui: GlobalUiStore = UiStore.instance();
}
```

打码条件（满足任一即打码）：

1. `ui.hideAmount === true` 且 `forceVisible === false`；
2. `locked === true`（调用方通过 `PrivateBookService.isLocked(bookId)` 计算后传入，T13 接入）。

`locked` 与全局隐藏互相独立，任一满足即打码；`forceVisible` 只覆盖全局隐藏，不覆盖私密锁定。

打码文案固定 `¥••••`，字号字重与正常一致，禁止使用 `blur`（性能与可读性都差）。

### 3.3 通用组件规格

| 组件 | 参数 | 规格 |
|---|---|---|
| `AppCard` | `padding=19`、`radius=Radius.cardLg`、`@BuilderParam content` | 背景 `surface`、1vp `line` 76%、`Shadow.card` |
| `PrimaryButton` | `label`、`enabled`、`onTap` | 高 46、圆角 14、`btn_bg`/`btn_fg`、13/700；禁用时 40% 透明 |
| `SecondaryButton` | 同上 | 高 46、圆角 14、`surface` 底、1vp `line` 边、12/600 |
| `IconButton` | `icon`、`size=34`、`tint`、`onTap` | 圆形、`surface` 底、1vp `line`；热区扩大到 44 |
| `EyeButton` | 无（直接读写 `ui.hideAmount`） | 34，激活时 `brand_wash` 底 + `brand_ink` 图标 |
| `Badge` | `text`、`tone` | 胶囊 `padding 1 6`、10/600；brand：`brand_wash`/`brand_ink`；warn：`warn` 12% 底 |
| `SectionHeader` | `title`、`trailing?: @BuilderParam` | 14/700，右侧可选动作 |
| `ListRow` | `icon?`、`title`、`subtitle?`、`trailingText?`、`showArrow`、`onTap` | 高 ≥52、`padding 11 13`、图标 31/圆角 10 |
| `ToggleRow` | `title`、`subtitle?`、`isOn`、`onChange` | `Toggle({ type: ToggleType.Switch, isOn })`，38×22 |
| `EmptyState` | `icon`、`title`、`description?`、`actionLabel?`、`onAction?` | 居中，图标 42、标题 13/600、说明 10/400 |
| `SegmentedControl` | `options: string[]`、`selectedIndex`、`onChange` | 背景 `surface_2`、padding 3、圆角 13、按钮高 30、圆角 10、10/600 |
| `AmountBar` | `percent: number`、`height=5`、`tone` | 轨 `surface_2`，填充 `brand`；`percent` 夹在 0–1 |
| `MemberDot` | `initial`、`color`、`size=15` | 15 圆，色 15% 底，10/700 |

所有组件禁止接收颜色字面量参数，只接收 `tone`/枚举或资源。

### 3.4 SnackBar

```ts
export class SnackBarOptions {
  message: string = '';
  actionLabel: string = '';
  durationMs: number = 5000;
  onAction: () => void = () => {};
}
export class SnackBarService {
  static show(options: SnackBarOptions): void;
  static dismiss(): void;
}
```

- 宿主放在 `Index` 的 Stack 顶层，距底部 `bottomInset + 76`。
- 样式：`ink` 92% 底、白字 11、圆角 12、`padding 12 14`、单行省略；动作按钮 `brand` 亮色文字。
- 同一时间只显示一条，新消息替换旧消息并重置计时器。
- 5 秒后自动消失；点击动作先执行回调再关闭。

### 3.5 SettingsService

`preferences` 来自 `@kit.ArkData`。Preferences 名 `moremoney_settings`，键：

| key | 类型 | 默认 |
|---|---|---|
| `weekStart` | number | 1（周一） |
| `lastBackupAt` | number | 0 |
| `lastBackupPath` | string | `''` |
| `recentSearches` | string(JSON 数组) | `'[]'` |
| `defaultBookId` | string | `''` |

提供 `init(context)`、`getNumber/getString`、`setNumber/setString`、`flush()`。所有读写走同一个单例；禁止在页面直接调 `preferences`。

### 3.6 DateUtil

必须提供：

```ts
dayKey(date: Date): string                  // 'YYYY-MM-DD' 本地时区
monthKey(date: Date): string                // 'YYYY-MM'
parseDayKey(key: string): Date              // 本地 00:00
daysInMonth(year: number, month1to12: number): number
startOfWeek(date: Date, weekStart: number): Date
rangeOfMonth(monthKey: string): { startMs: number; endMs: number }
addMonths(monthKey: string, delta: number): string
formatMonthCn(monthKey: string): string     // '11月'
formatDayCn(dayKey: string): string         // '11月9日 周一'
```

- 所有边界用本地时间；`endMs` 为当月最后一刻（23:59:59.999）。
- 周日 = 0，周一 = 1，与 `Date.getDay()` 对齐；`weekStart` 取值 1–7。

### 3.7 GalleryPage

- `@Preview @ComponentV2 struct GalleryPage`，不入路由表。
- 分区展示：颜色 token 色块、字号阶梯、按钮三态、卡片、徽标、空状态、分段控件、进度条、MoneyText（正常/隐藏/私密）、SnackBar 触发按钮。
- 底部提供“写入演示数据”按钮调用 `DebugSeedService.seedDemo()`，仅 debug 可用。

## 4. 验收标准

| 编号 | 验收项 | 验证方式 |
|---|---|---|
| AC-1 | Gallery 可预览，所有组件正常渲染，无布局溢出 | DevEco Previewer / 真机 |
| AC-2 | 点击眼睛按钮，Gallery 内全部 `MoneyText` 同步切换 `¥••••`，进度条数字同步隐藏 | 预览操作 |
| AC-3 | `MoneyText` 在 `locked=true` 时打码；`forceVisible` 只覆盖全局隐藏，不覆盖私密锁定 | Gallery 用例 |
| AC-4 | SnackBar 5 秒自动消失，动作按钮可点击并执行回调，连续调用只显示最新一条 | Gallery 操作 |
| AC-5 | `SettingsService` 写入后杀进程重启仍能读到 | 真机验证 |
| AC-6 | `DateUtil` 月份边界、周起点（周一/周日）计算正确 | 单测或 Gallery 打印 |
| AC-7 | 组件内无颜色字面量，无 V1 装饰器 | `rg` 检查 |
| AC-8 | 构建通过 | `devecocli build` |

## 5. 注意事项

- V2 中父组件给子组件传值必须用 `@Param`；回调必须用 `@Event`，不要传函数类型 `@Param`。
- `@BuilderParam` 的默认值写法：`@BuilderParam content: () => void = this.defaultContent;` 并定义 `@Builder defaultContent() {}`。
- `AppStorageV2.connect` 必须在组件初始化阶段调用，不要在 `build()` 内反复 connect。
- 本任务不实现业务页面，只保证组件与状态可用。
