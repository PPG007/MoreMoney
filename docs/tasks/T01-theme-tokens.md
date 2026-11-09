# T01 · 设计 Token、主题与图标资源

> 状态：已完成 ｜ 优先级：P0 ｜ 依赖：无 ｜ 预估：1.5 人日
> 设计依据：`设计规范.md` §4、§5、§6、§7.5；截图 `screenshots/01-home-light.png`、`02-home-dark.png`

## 1. 目标

把设计规范中的颜色、字号、间距、圆角、阴影、分类色、成员色、图标固化为代码中的唯一来源。后续任何页面不得再出现颜色字面量或魔法数字。

## 2. 交付物

| 路径 | 内容 |
|---|---|
| `entry/src/main/resources/base/element/color.json` | 浅色 token（见 3.1） |
| `entry/src/main/resources/dark/element/color.json` | 深色 token，key 与浅色完全一致 |
| `entry/src/main/ets/theme/Theme.ets` | `AppFont`、`Space`、`Radius`、`Shadow`、`Duration` |
| `entry/src/main/ets/theme/Palette.ets` | `ChartPalette`、`MemberPalette`、`withAlpha()` |
| `entry/src/main/ets/theme/IconSize.ets` | 图标尺寸常量（可选，可并入 Theme） |
| `entry/src/main/resources/base/media/ic_*.svg` | 图标资源清单（见 3.5） |
| `entry/src/main/ets/theme/ThemeDoc.md`（可选） | 不入库，仅本地对照，可删除 |

## 3. 实现要求

### 3.1 颜色资源

必须实现的 token（key 使用下划线，取值严格照抄设计规范 §4）：

| key | 浅色 | 深色 |
|---|---|---|
| `bg` | `#FAF8F7` | `#121017` |
| `surface` | `#FFFFFF` | `#1C1925` |
| `surface_2` | `#F5F0F1` | `#25212E` |
| `surface_3` | `#ECE4E6` | `#302A3B` |
| `ink` | `#272231` | `#F4F0FA` |
| `ink_2` | `#6B6272` | `#C3BCCD` |
| `ink_3` | `#756B7B` | `#9C93A8` |
| `line` | `#EEE4E6` | `#332D40` |
| `chart_surface` | `#FFFFFF` | `#1C1925` |
| `bezel` | `#15121B` | `#15121B` |
| `scrim` | `#6B181430` | `#94000000` |
| `tab_bg` | `#D6FFFFFF` | `#DB1C1925` |
| `brand` | `#6366F1` | `#818CF8` |
| `brand_ink` | `#4338CA` | `#A5B4FC` |
| `brand_soft` | `#E0E7FF` | `#2E2A5E` |
| `brand_wash` | `#EEF2FF` | `#1E1B3A` |
| `btn_bg` | `#4338CA` | `#A5B4FC` |
| `btn_fg` | `#FFFFFF` | `#1E1B3A` |
| `expense` | `#C62F3D` | `#FF9A9A` |
| `good` | `#137A57` | `#4FD1A0` |
| `warn` | `#8A5200` | `#F0B45A` |
| `hero_a` | `#4F46E5` | `#312E81` |
| `hero_b` | `#4338CA` | `#25225F` |
| `hero_c` | `#312E81` | `#181638` |
| `on_hero` | `#FFFFFF` | `#FFFFFF` |
| `hero_glass` | `#4716123C` | `#17FFFFFF`（约 9% 白） |
| `hero_line` | `#2EFFFFFF` | `#24FFFFFF` |
| `hero_glow` | `#2EFFFFFF` | `#1F8C96FF` |

规则：

1. 半透明色统一写成 `#AARRGGBB`。设计稿里的 `rgba(r,g,b,a)` 转法：`AA = round(a × 255)`，输出两位十六进制。
2. 深色文件只能覆盖同名 key，不得新增或改名。
3. 组件内禁止出现 `#RRGGBB`；唯一例外是 `Palette.ets` 内的图表/成员色定义。

### 3.2 字号

`AppFont` 必须提供以下常量，并**执行窄屏可读性上调**（设计规范 §13.8）：

| 设计值 | 落地值 | 用途 |
|---|---:|---|
| 7 | 10 | 日历格金额 |
| 8 | 10 | 微标签、图表轴、占比标签 |
| 9 | 10 | 表单、选择器、辅助说明 |
| 10 | 10 | 分类名、卡片说明 |
| 11 | 11 | 图例名 |
| 12 | 12 | 设置标题 |
| 13 | 13 | 流水标题、账本名 |
| 14 | 14 | 区块标题、账单金额 |
| 16 | 16 | 统计数字 |
| 17 | 17 | 二级页标题 |
| 19 | 19 | 账本/解锁标题 |
| 23 | 23 | 饼图中心 |
| 24 | 24 | 预算环中心 |
| 25 | 25 | 一级页标题 |
| 26 | 26 | 记一笔金额 |
| 27 | 27 | 趋势主数字 |
| 32 | 32 | 首页月份 |
| 42 | 42 | 首页本月支出 |

同时提供 `AppFont.regular = 400`、`medium = 500`、`semibold = 600`、`bold = 700` 与 `tabular(text)` 辅助说明（金额统一 `.fontFeature('"tnum" 1')`）。

### 3.3 间距与圆角

- `Space`：`x1=4, x2=6, x3=8, x4=10, x5=12, x6=16, x7=20, x8=24, x9=32`；页面左右安全边距 `page=16`。
- `Radius`：`hero=30, cardLg=24, card=20, cardSm=18, icon=14, chip=12, input=10, button=14, sheet=28, pill=999`。
- 数字必须是 `number`（vp），不得用字符串。

### 3.4 阴影与动效

用 `ShadowOptions` 对象（不要用 CSS 字符串）：

```ts
static card(isDark: boolean): ShadowOptions {
  return { radius: 28, offsetX: 0, offsetY: 10,
           color: isDark ? 'rgba(0,0,0,0.32)' : 'rgba(50,40,110,0.08)' };
}
static nav(isDark: boolean): ShadowOptions  // radius 24, offsetY -8
static fab(isDark: boolean): ShadowOptions  // radius 34, offsetY 16, 颜色取 btn_bg 38%
```

- `Duration`：`fast=150, normal=220, slow=320`（毫秒）。
- 阴影按 `isDark: boolean` 参数返回，组件通过 `GlobalUiStore.isDark` 取值。
- `ShadowOptions` 类型来自 ArkUI 全局声明，不需要 import。

### 3.5 图标资源

统一规格：24×24 viewBox、单色、**使用 `fill` 路径而非 `stroke`**（保证 `Image.fillColor()` 可着色）、无内置背景、无文字。

必须交付：

- Tab：`ic_tab_books`、`ic_tab_budget`、`ic_tab_charts`、`ic_tab_settings`
- 通用：`ic_back`、`ic_close`、`ic_plus`、`ic_chevron_left`、`ic_chevron_right`、`ic_eye`、`ic_eye_off`、`ic_lock`、`ic_unlock`、`ic_search`、`ic_calendar`、`ic_member`、`ic_book`、`ic_edit`、`ic_trash`、`ic_archive`、`ic_file`、`ic_cloud`、`ic_fingerprint`、`ic_face`、`ic_warning`、`ic_undo`、`ic_more`
- 分类：`ic_cat_food`、`ic_cat_transport`、`ic_cat_home`、`ic_cat_shopping`、`ic_cat_entertain`、`ic_cat_medical`、`ic_cat_study`、`ic_cat_water`、`ic_cat_power`、`ic_cat_phone`、`ic_cat_travel`、`ic_cat_repair`、`ic_cat_other`
- 账本封面：`ic_book_daily`、`ic_book_travel`、`ic_book_family`、`ic_book_study`、`ic_book_work`、`ic_book_repair`

命名规则：`ic_<domain>_<name>.svg`，全部小写下划线。

### 3.6 调色板

`Palette.ets`：

```ts
export class ChartColors {
  slots: string[];   // 5 个分类色，索引 0-4
  other: string;
}
export function chartColors(isDark: boolean): ChartColors
export class MemberColors { self: string; family: string; child: string; }
export function memberColors(isDark: boolean): MemberColors
export function withAlpha(hex: string, alpha: number): string  // '#RRGGBB' -> '#AARRGGBB'
```

取值见设计规范 §4.4、§4.5。分类色与品牌色不得互相复用。

## 4. 验收标准

| 编号 | 验收项 | 验证方式 |
|---|---|---|
| AC-1 | `color.json` 浅/深两套 key 完全一致，且覆盖 3.1 全部 token | 逐项对照本表 / 脚本比对 key |
| AC-2 | 切换系统深色模式后，`bg`、`surface`、`ink`、`brand` 自动变化，无需重启 | 真机设置切换后回到 App 观察 |
| AC-3 | `Theme.ets` 编译通过，常量可被页面引用 | `devecocli check arkts entry/src/main/ets/theme/Theme.ets entry/src/main/ets/theme/Palette.ets` |
| AC-4 | 图标全部存在且可被 `Image($r('app.media.ic_xxx'))` 加载 | 在 `GalleryPage`（T05）逐项渲染，无空白 |
| AC-5 | 图标 `fillColor` 着色生效（同色图标显示为品牌色） | Gallery 中渲染 `ic_eye` 并设 `fillColor($r('app.color.brand_ink'))` |
| AC-6 | 全项目 `ets/` 下除 `Palette.ets` 外无 `#[0-9A-Fa-f]{6}` 颜色字面量 | `rg "\\#[0-9A-Fa-f]{6}" entry/src/main/ets` 仅命中 Palette/注释 |
| AC-7 | 构建通过 | `devecocli build` |

## 5. 注意事项

- 不要引入字体文件；金额等宽用 `fontFeature`。
- 阴影字符串在 ArkUI 中可用 `ShadowOptions` 或 `.shadow()` 的字符串形式，若当前 SDK 不接受字符串，改为 `ShadowOptions` 对象常量，但必须保持同一 token 名。
- 图标先用几何化示意即可，后续任务可按截图替换，但文件名不得变更。
- 本任务不创建任何页面，不修改 `Index.ets`。
