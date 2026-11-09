# MoreMoney

HarmonyOS 记账应用（v1：支出记账、多账本、成员、分类、预算、统计图表、私密账本、金额隐藏、CSV 导入导出、备份恢复、搜索）。

## 技术栈

- HarmonyOS Stage 模型，`compatibleSdkVersion` 6.1.1(24)
- ArkTS / ArkUI 声明式开发，全项目统一 **V2 状态管理**（`@ComponentV2` / `@Local` / `@Param` / `@Event` / `@ObservedV2` + `@Trace`）
- 全局状态：`AppStorageV2.connect`（`state/UiStore.ets` 统一访问）
- 导航：唯一入口 `pages/Index.ets`，`Navigation(NavigationMode.Stack)` + 4 个 Tab；二级页走系统路由表 `resources/base/profile/router_map.json`
- 数据：`@ohos.data.relationalStore`（SQLite，单库 `moremoney.db`，`securityLevel: S1`）
- 金额：全链路整数“分”（字段以 `Cents` 结尾），显示与计算由 `utils/MoneyUtil.ets`、`utils/ExpressionEngine.ets` 统一处理
- 图表：Canvas 2D 自绘，无第三方图表库
- 网络：v1 完全离线，不申请网络权限

## 目录结构

```text
entry/src/main/ets/
  entryability/        EntryAbility（全屏、状态栏、深色模式同步）
  pages/Index.ets      唯一 @Entry：Navigation + Tabs + SnackBar
  pages/               一级页（home/budget/charts/settings）与二级页
  pages/dev/           GalleryPage 组件样例（@Preview，不接入路由）
  components/layout/   MainTabs、PageHeader
  components/base/     按钮 / 卡片 / 金额 / 提示条等基础组件
  data/db/             DbManager、Schema、SeedData、DAO、Mapper
  models/              实体与过滤模型
  service/             系统栏、设置、提示条、调试种子
  state/               GlobalUiStore、UiStore
  theme/               Token 常量、调色板、图标尺寸
  utils/               金额、表达式、日期、错误、ID
resources/base|dark/element/color.json   浅色 / 深色 token
resources/base/profile/router_map.json   系统路由表
```

## 构建与运行

```bash
# 静态检查（ArkTS）
devecocli check arkts entry/src/main/ets/pages/Index.ets

# 构建
devecocli build

# 安装并运行（需已连接设备或启动模拟器）
devecocli run --skip-build --device "Mate 90 Pro"
```

本地单元测试位于 `entry/src/test/`（Hypium），可在 DevEco Studio 中运行 Local Unit Test。

## 开发约定

完整规范见 `docs/tasks/README.md` 与 `assets/design/设计规范.md`，核心红线：

1. 禁止 `any`、`unknown`、`ESObject`、`as`、非空断言、动态属性访问（`Record` 除外）。
2. 颜色只用 `$r('app.color.*')` 或 `theme/` 中的调色板，组件内不写十六进制。
3. 每个 `struct` 必须属于 V2 状态管理，禁止 V1 装饰器。
4. 数据库读写与聚合必须走 DAO / Service，页面不拼 SQL。
5. 新增 API 前先在 SDK `.d.ts` 确认存在。

## 任务拆分

开发任务按里程碑拆分在 `docs/tasks/`：

- M0 骨架：T01 主题、T02 导航、T03 数据层、T04 金额计算、T05 通用组件
- M1 记账闭环：T06 首页、T07 记一笔、T09 成员、T10 分类、T11 统计、T12 预算
- M2 账本与隐私：T08、T13、T14
- M3 图表：T15–T17
- M4 数据：T18–T23
- M5 质量：T24、T25
