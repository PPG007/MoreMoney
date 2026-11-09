# MoreMoney 开发任务拆分

- 版本：v1.0
- 日期：2026-11-09
- 上游文档：`assets/design/设计规范.md`、`assets/design/MoreMoney.md`
- 任务文档目录：`docs/tasks/`
- 拆分原则：一个任务 = 一次可独立提交、可独立验收的改动；任务之间只通过文档中声明的交付物耦合

---

## 1. 产品范围

本轮只做设计规范定义的 v1：支出记账、多账本、成员、分类、预算、三类统计图表、私密账本、金额隐藏、CSV 导入导出、本地备份恢复、搜索。

**明确不做**（见第 6 节）：收入、云同步、多人共享、分类预算、预算结转、组件卡片、账单分期。

---

## 2. 全局技术决策（所有任务必须遵守）

| 项 | 决策 |
|---|---|
| 平台 | HarmonyOS Stage 模型，`compatibleSdkVersion` 6.1.1(24)，不得使用 24 以上才有的 API |
| UI | ArkUI 声明式，**全项目统一 V2 状态管理** |
| 状态装饰器 | `@ComponentV2` / `@Local` / `@Param` / `@Event` / `@Monitor` / `@Computed`；对象模型用 `@ObservedV2` + `@Trace`；**禁止任何 V1 装饰器**（`@State`/`@Prop`/`@Link`/`@Provide`/`@Observed`/`@StorageLink` 等） |
| 全局状态 | `AppStorageV2.connect(GlobalUiStore, 'globalUi', () => new GlobalUiStore())`，从 `@kit.ArkUI` 导入 |
| 导航 | 根页面 `pages/Index.ets` 是唯一 `@Entry`；`Navigation(NavigationMode.Stack)` 承载 4 个 Tab；二级页走系统路由表 `router_map.json`，**不使用** `.navDestination(builder)`，不使用 `router.pushUrl` |
| 导航参数 | 参数必须是 `class`（不是 `interface`），接收方用 `instanceof` 收窄；禁止 `as` |
| 数据 | `@ohos.data.relationalStore`（SQLite），单库 `moremoney.db`，`securityLevel: S1` |
| 金额 | 全链路整数“分”（`number`，安全整数范围内）；字段名以 `Cents` 结尾；禁止浮点存储 |
| 时间 | 毫秒时间戳字段以 `At` 结尾；日期分组使用冗余字段 `dayKey`（`YYYY-MM-DD`） |
| 图表 | Canvas 2D 自绘，不引入第三方图表库 |
| 图标 | 本地单色 SVG（`fill` 路径），通过 `.fillColor()` 着色；不依赖 `sys.symbol` 名称 |
| 字体 | 系统 HarmonyOS Sans；金额用 `.fontFeature('"tnum" 1')` 等宽数字；**不内置 Baloo 2** |
| 网络 | v1 完全离线，不申请网络权限 |
| 主题 | 颜色走资源 `$r('app.color.*')` + `resources/dark`；字号/间距/圆角/阴影走 `Theme.ets` 常量 |

### 2.1 代码红线

1. 禁止 `any`、`unknown`、`ESObject`、`as`、非空断言 `!`、动态属性访问（`obj[key]`，`Record` 除外）。
2. 颜色禁止在组件里写字面量，只能用 `$r('app.color.*')` 或 `Theme` / `ChartPalette` / `MemberPalette`。
3. 每个 `struct` 必须明确属于 V2；`build()` 内不得有变量声明、`if/switch` 之外的语句、状态修改。
4. 数据库读写、聚合必须走 DAO / Service，页面不得直接拼 SQL。
5. 新增 API 前先在 SDK `.d.ts` 中确认存在，再使用。

### 2.2 错误处理约定

- `catch` 不写类型；统一调用 `ErrorUtil.messageOf(e: Object): string`（`utils/ErrorUtil.ets`），内部只用 `instanceof Error` 与 `String(e)`。
- 不依赖 `BusinessError.code` 做分支；需要区分失败原因的场景（导入校验、备份校验）由业务层返回结构化结果。
- 用户可见失败：底部提示条 + 可重试，不弹全屏错误页。

### 2.3 刷新约定

- 页面写入数据后调用自身 `reload()`；
- 二级页返回一级页时通过 `NavPathStack.pushPathByName(name, param, onPop)` 的回调触发 `reload()`；
- 禁止自建全局事件总线。

---

## 3. 目录约定

```text
entry/src/main/ets/
  entryability/                 EntryAbility
  pages/Index.ets               唯一入口：Navigation + Tabs + 全局 SnackBar
  pages/home/HomePage.ets
  pages/budget/BudgetPage.ets
  pages/charts/ChartsPage.ets
  pages/settings/SettingsPage.ets
  pages/books/BookManagePage.ets
  pages/categories/CategoryManagePage.ets
  pages/members/MemberManagePage.ets
  pages/data/DataBackupPage.ets
  pages/search/SearchPage.ets
  pages/add/AddTxnPage.ets
  pages/dev/GalleryPage.ets     仅开发期使用，不放入任何 UI 入口
  components/                   跨页面组件
  components/base/              按钮/卡片/金额等基础组件
  components/sheet/             通用底部弹层
  components/chart/             Canvas 图表组件
  data/db/                      DbManager、Migration、DAO
  models/                       实体与视图模型
  service/                      业务服务（统计、预算、CSV、备份、解锁）
  state/                        GlobalUiStore 与访问器
  theme/                        Token 常量
  utils/                        金额、日期、CSV、错误、安全
resources/base/profile/router_map.json
resources/base/element/color.json
resources/dark/element/color.json
```

命名：页面 `*Page`，弹层 `*Sheet`，组件 `*Card`/`*Row`/`*Button`，DAO `*Dao`，业务服务 `*Service`，纯函数工具 `*Util`。

---

## 4. 任务总览

| ID | 任务 | 里程碑 | 优先级 | 依赖 | 预估 |
|---|---|---|---|---|---|
| T01 | 设计 Token、主题与图标资源 | M0 | P0 | 无 | 1.5 |
| T02 | 应用骨架与导航路由 | M0 | P0 | T01 | 1.0 |
| T03 | 数据模型与 RDB 数据层 | M0 | P0 | T01 | 2.0 |
| T04 | 金额格式化与计算表达式引擎 | M0 | P0 | T01 | 1.0 |
| T05 | 通用组件与全局状态 | M0 | P0 | T01、T02 | 1.5 |
| T06 | 记账本首页 | M1 | P1 | T03、T05 | 2.0 |
| T07 | 记一笔面板 | M1 | P1 | T03、T04、T05 | 3.0 |
| T08 | 账本管理 | M2 | P2 | T03、T05、T12、T13 | 1.5 |
| T09 | 成员管理 | M1 | P1 | T03、T05 | 1.0 |
| T10 | 分类管理 | M1 | P1 | T03、T05 | 1.5 |
| T11 | 统计聚合服务 | M1 | P1 | T03 | 1.5 |
| T12 | 预算页 | M1 | P1 | T05、T11 | 2.0 |
| T13 | 私密账本与解锁 | M2 | P2 | T03、T05 | 2.5 |
| T14 | 全局金额隐藏覆盖 | M2 | P2 | T05、T06、T12 | 1.0 |
| T15 | 图表基础层与分类环形图 | M3 | P2 | T05、T11 | 2.5 |
| T16 | 支出趋势折线图 | M3 | P2 | T15 | 2.0 |
| T17 | 日历热力与单日明细 | M3 | P2 | T11、T15 | 1.5 |
| T18 | 全局搜索 | M4 | P3 | T03、T05、T13 | 1.0 |
| T19 | CSV 导出 | M4 | P3 | T03、T11 | 1.5 |
| T20 | CSV 导入 | M4 | P3 | T03、T19 | 2.0 |
| T21 | 备份与恢复 | M4 | P3 | T03、T13 | 2.5 |
| T22 | 设置页与数据备份页 | M4 | P3 | T05、T19、T20、T21 | 1.5 |
| T23 | 删除撤销与状态反馈 | M4 | P3 | T06、T07 | 1.0 |
| T24 | 单元测试与质量门禁 | M5 | P4 | 全部 | 1.5 |
| T25 | 深浅色/窄屏走查与真机验收 | M5 | P4 | 全部 | 1.5 |

预估单位：人日，按一名熟悉 ArkTS 的开发者估算。总计约 41.5 人日。

**执行顺序**：按依赖执行，不严格按编号。M2 中 **T13 必须先于 T08**（账本管理的私密开关依赖密码/解锁组件）；T13 的服务层与弹层可先交付，其页面口径验收（首页/预算/图表排除）在对应页面任务完成后补跑。T07 在 T13 完成前，私密账本先显示锁并禁用选择，T13 完成后接解锁弹层。

### 里程碑

- **M0 可运行骨架（7 人日）**：主题、导航、数据层、计算引擎、通用组件齐备，App 可启动并在 4 个空页面间切换。
- **M1 记账闭环（11 人日）**：能记账、看首页、管成员/分类、看预算（账本先使用种子数据）。
- **M2 账本与隐私（5 人日）**：账本管理、私密账本、金额隐藏全站生效。
- **M3 图表（6 人日）**：分类、趋势、日历三页完成。
- **M4 数据（9.5 人日）**：搜索、CSV、备份恢复、设置页、删除撤销。
- **M5 质量（3 人日）**：单测、深色/窄屏走查、真机验收。

---

## 5. 完成定义（DoD）

每个任务结束前必须全部满足：

1. 交付物表列出的文件全部存在，无遗留 TODO（`// TODO(Txx)` 之外）。
2. 对本轮新增/修改的 `.ets` 执行一次 `devecocli check arkts <文件...>`，无错误。
3. 执行 `devecocli build` 成功。
4. 任务文档“验收标准”逐条勾选，UI 类任务需在真机或模拟器上验证并记录设备型号。
5. 无第 2.1 节红线违规；无新增第三方依赖（`oh-package.json5` 不变）。
6. 深色模式下该任务的页面/组件可正常显示（未做主题的任务由 T25 统一兜底）。

---

## 6. 暂缓与待确认项

| 项 | 结论 | 处理 |
|---|---|---|
| 自动同步到网盘 | 无通用第三方云盘 API | v1 只做“导出到用户选择的位置”；WebDAV 另立任务 |
| 后台自动备份 | `BackupExtensionAbility` 只能由系统调度，应用不可触发 | 手动备份 + 记录时间；不做后台任务 |
| 一次性恢复码 | 设计标注“可选” | v1 不做，忘记密码不可恢复 |
| Baloo 2 字体 | 授权与包体积 | 用系统字体 + tabular 数字 |
| 分类预算、预算结转 | 设计明确 v1 不做 | 不做 |
| 组件卡片 `FormExtensionAbility` | 设计标 P2 | 不做 |
| 微信/支付宝账单导入 | 未在需求内 | 不做 |

---

## 7. 文档使用方式

1. 开始任务前，先读本文第 2 节 + 任务文档引用的设计规范章节 + 对应截图。
2. 任务文档中的“交付物”是唯一文件清单；需要新增清单外文件时，先更新任务文档再实现。
3. 验收标准中的命令按顺序执行，全部通过才可勾选任务完成。
