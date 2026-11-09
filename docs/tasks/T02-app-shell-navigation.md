# T02 · 应用骨架与导航路由

> 状态：待开始 ｜ 优先级：P0 ｜ 依赖：T01 ｜ 预估：1.0 人日
> 设计依据：`设计规范.md` §3、§7.1、§8.1（顶部/底部结构）、§11

## 1. 目标

搭出可运行的应用骨架：全屏窗口 + 安全区适配 + 4 个一级 Tab + 6 个二级页路由 + 全局提示条容器。所有业务页面先用占位内容，保证路由、返回、状态栏样式、Tab 切换可用。

## 2. 交付物

| 路径 | 内容 |
|---|---|
| `entry/src/main/ets/pages/Index.ets` | 唯一 `@Entry`：Navigation(Stack) + 自定义 TabBar + 全局 SnackBar 层 |
| `entry/src/main/ets/pages/home/HomePage.ets` | 一级页占位 |
| `entry/src/main/ets/pages/budget/BudgetPage.ets` | 一级页占位 |
| `entry/src/main/ets/pages/charts/ChartsPage.ets` | 一级页占位（内含 分类/趋势/日历 分段占位） |
| `entry/src/main/ets/pages/settings/SettingsPage.ets` | 一级页占位 |
| `entry/src/main/ets/pages/books/BookManagePage.ets` | 二级页占位（根节点 `NavDestination`） |
| `entry/src/main/ets/pages/categories/CategoryManagePage.ets` | 二级页占位 |
| `entry/src/main/ets/pages/members/MemberManagePage.ets` | 二级页占位 |
| `entry/src/main/ets/pages/data/DataBackupPage.ets` | 二级页占位 |
| `entry/src/main/ets/pages/search/SearchPage.ets` | 二级页占位 |
| `entry/src/main/ets/pages/add/AddTxnPage.ets` | 二级页占位（全屏无标题栏） |
| `entry/src/main/ets/components/layout/MainTabs.ets` | 自定义 TabBar + 4 个 TabContent |
| `entry/src/main/ets/components/layout/PageHeader.ets` | 一级/二级页头组件（本任务先做二级页版本） |
| `entry/src/main/ets/service/SystemBarService.ets` | 状态栏样式、安全区读取 |
| `entry/src/main/ets/state/GlobalUiStore.ets` | 最小全局状态（`isDark`、`topInset`、`bottomInset`），T05 再扩展 |
| `entry/src/main/resources/base/profile/router_map.json` | 系统路由表 |
| `entry/src/main/module.json5` | 增加 `routerMap` 字段 |
| `entry/src/main/ets/entryability/EntryAbility.ets` | 全屏布局、窗口初始化 |

## 3. 实现要求

导入：`window` 来自 `@kit.ArkUI`；`ConfigurationConstant` 来自 `@kit.AbilityKit`。

### 3.1 页面结构

```text
Index (@Entry, @ComponentV2)
└── Stack
    ├── Navigation(this.pathStack)          // mode: Stack, hideTitleBar(true)
    │   └── MainTabs                        // 首页内容 = 4 个 Tab
    └── SnackBarHost                        // 全局提示条，覆盖在 Navigation 之上
```

- `main_pages.json` 只保留 `pages/Index`，不得新增页面。
- 二级页不注册到 `main_pages.json`，只写进 `router_map.json`。
- 路由表 6 项：`BookManage`、`CategoryManage`、`MemberManage`、`DataBackup`、`Search`、`AddTxn`。
- 每个二级页文件导出 `@Builder export function XxxBuilder() { XxxPage() }`，`XxxPage.build()` 的根节点必须是 `NavDestination`，并设置 `.hideTitleBar(true)`（标题栏由自定义 `PageHeader` 提供），从 `onReady((ctx: NavDestinationContext) => { this.stack = ctx.pathStack; })` 取栈。
- **禁止**给 Navigation 挂 `.navDestination(builder)`（与路由表二选一）。
- `Index` 不得调用 `router.pushUrl` / `router.replaceUrl`。

### 3.2 自定义 TabBar

按设计规范 §7.1：

- 高 62，4 等分，整格可点；
- 背景 `tab_bg` + 18vp 模糊，上边框 1vp `line`；
- 图标 20，外层选中胶囊 38×25，选中底 `brand_soft`、图标 `brand_ink`；未选中 `ink_3`；
- 文案 10vp（设计 9 → 落地 10），选中 600、未选中 400；
- 底部手势条区域由安全区撑开，不自己画手势条。

实现建议：`Tabs({ barPosition: BarPosition.End })` + `TabContent().tabBar(this.TabItem(...))`，`Tabs.barHeight(62)`、`.scrollable(false)`、`.animationDuration(0)`；或用 `Stack + 自绘 Row` 切换索引。**选择一种并在代码注释中说明**，但必须保证切 Tab 不重建页面状态（用 `Tabs` 更省心）。

### 3.3 全屏与安全区

- `EntryAbility.onWindowStageCreate` 中调用 `windowStage.getMainWindowSync()` 后设置 `setWindowLayoutFullScreen(true)`，状态栏背景透明。
- `SystemBarService` 提供：
  - `getTopInset(): number`（px2vp，`AvoidAreaType.TYPE_SYSTEM` 的 `topRect.height`）
  - `getBottomInset(): number`（`TYPE_NAVIGATION_INDICATOR`）
  - `setStatusBarDarkText(dark: boolean): void`（`setWindowSystemBarProperties` 的 `statusBarContentColor`）
- 顶部安全区高度写入本任务创建的 `GlobalUiStore.topInset` / `bottomInset`；`isDark` 由 `EntryAbility.onConfigurationUpdate` 更新。T05 在该类上扩展其余字段。
- 首页 Hero 允许内容延伸到状态栏下方；其他一级页顶部 padding = `topInset + 10`。
- 二级页使用 `NavDestination` 自带安全区，不重复加 `topInset`。

### 3.4 状态栏图标颜色

- 一级页：首页 Hero 区域为深色渐变 → 白色图标；切换到预算/图表/设置 → 深色图标。
- 二级页：除 AddTxn 使用页面自身背景（浅色 → 深色图标）外，一律深色图标。
- Tab 切换、页面 push/pop 时都要调用 `SystemBarService.setStatusBarDarkText`，退出时恢复深色图标。

### 3.5 路由参数

- 路由参数一律定义为 `class`，例如 `export class AddTxnParam { bookId: string = ''; dayKey: string = ''; }`。
- 接收方：

```ts
const p = ctx.pathInfo.param;
if (p instanceof AddTxnParam) { this.param = p; }
```

- 禁止 `param as XxxParam`。

### 3.6 二级页返回

- 使用 `NavDestination` 默认返回按钮或自定义 `PageHeader` 的返回按钮调用 `this.stack.pop()`。
- 标题、右侧动作符合 §3.3：返回按钮 34、标题 17/700、右侧 gap 10。
- 系统返回手势必须可用（不拦截 `onBackPressed`，除非有未保存内容）。

## 4. 验收标准

| 编号 | 验收项 | 验证方式 |
|---|---|---|
| AC-1 | App 启动进入首页，4 个 Tab 可互相切换，切换后各 Tab 状态保留 | 真机操作 |
| AC-2 | 6 个二级页均可通过 `pathStack.pushPathByName(name, param)` 打开，均不白屏 | 在 GalleryPage 或临时按钮逐个打开 |
| AC-3 | 二级页返回后回到原 Tab，Tab 选中态不变 | 真机操作 |
| AC-4 | 系统返回手势能关闭二级页 | 真机操作 |
| AC-5 | 首页内容延伸至状态栏下，文字不被状态栏遮挡；其他页面顶部不被遮挡 | 真机截图对照 01/07 |
| AC-6 | 切换 Tab 时状态栏图标颜色随页面变化（首页白、其余深） | 真机观察 |
| AC-7 | 底部 Tab 高度 62、选中胶囊 38×25、毛玻璃背景生效 | 截图比对 §7.1 |
| AC-8 | 无 `.navDestination(` 调用；`main_pages.json` 只有 `pages/Index` | `rg` 检查 |
| AC-9 | 构建通过 | `devecocli build` |

## 5. 注意事项

- 不要在 `Index` 里直接写业务 UI，只做壳。
- `Navigation` 路由表方案下，`pushPathByName` 的目标页必须存在且 `buildMethod` 名称一致，否则运行时白屏且无编译报错。
- 模糊背景在模拟器上可能不生效，以真机为准；不可用时降级为 `tab_bg` 纯色。
- 本任务不实现任何业务逻辑，Tab 页面只放标题 + 一句占位文案。
