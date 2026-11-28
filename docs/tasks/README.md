# MoreMoney Android 迁移任务

- 日期：2026-11-23
- 工程目录：`C:\Users\16582\workspace\MoreMoneyAndroid`
- 历史参考实现：`C:\Users\16582\workspace\MoreMoney`（HarmonyOS / ArkTS，仅作迁移来源，不再要求兼容）
- 设计规范：`C:\Users\16582\workspace\MoreMoney\assets\design\设计规范.md`
- 任务编号沿用早期迁移计划，便于对照历史记录。
- **2026-11-24 实现进度：** T00–T08、T10–T26 完成（T09 已删除、T13 已取消）。构建、58 个 JVM 单测、19 个 instrumentation（含 v1→v2 迁移测试）、Lint 0 error、Release（R8）构建与签名安装/升级/降级验证均通过；T25 验收见 `docs/tasks/T25-report.md`，发布文档见 `docs/release/`，暂停/续做快照见 `docs/tasks/PROGRESS-2026-11-23.md`，截图见 `docs/screenshots/`。
- **2026-11-24 范围变更（重要）：** Android 版改为**独立应用**，不再要求与鸿蒙版互换数据；**移除成员管理**（UI、筛选、统计、CSV/备份字段、Room 表）。Room schema 升到 v2（保留流水迁移），CSV 改为 9 列（旧 10 列可导入并忽略成员列），备份 `schemaVersion=2`（可读取旧 v1 备份并忽略成员）。详见 §4。
- **2026-11-28 预算改造：** Room schema 升到 v3；`budget` 改为每账本一条“周期 + 金额”（年/季/月，自动重复）；预算页移除月份切换与跨账本合计，改为单张预算卡左右切换账本（默认优先默认账本）；备份升到 `schemaVersion=3`，兼容 v1/v2。
- **2026-11-23 复核：** 模拟器镜像与 AVD 已就绪；Room/KSP 兼容性已实测通过。复核证据见 `docs/tasks/dependency-check-2026-11-23.md`，子任务级拆分见 `docs/tasks/WBS.md`。
- **2026-11-23 范围变更：** Android v1 **取消私密账本**（密码、生物识别、锁定、加密备份），只保留普通账本。T13 改为已取消；`book` 表不再包含 `is_private` / `pwd_hash` / `pwd_salt` / `pwd_iter`；备份不再生成 `PRIVATE` 段。详见 WBS 决策 D3 与 T21。

---

## 1. 本机依赖检查结论

### 1.1 已安装且可用

| 依赖 | 状态 | 版本 / 位置 |
|---|---|---|
| Android Studio | ✅ | 2026.2.2，`D:\jetbrains\Android Studio` |
| 运行时 JDK | ✅ | JBR 25.0.4（`JAVA_HOME=D:\jetbrains\Android Studio\jbr`），Gradle 实测 |
| 系统 JDK | ✅ | OpenJDK 25.0.2，`C:\Users\16582\jdk\25.0.2`（备用） |
| Gradle | ✅ | Wrapper 9.9.2，已下载到 `~/.gradle/wrapper/dists` |
| JDK 17 编译工具链 | ✅ | Gradle 已自动下载 Adoptium 17.0.21 到 `~/.gradle/jdks` |
| Android SDK | ✅ | `C:\Users\16582\AppData\Local\Android\Sdk` |
| SDK Platform | ✅ | `android-37.2`（另有 `android-37.0`） |
| SDK Build-Tools | ✅ | `36.0.0` |
| Android Platform-Tools | ✅ | `37.0.3` |
| Android Emulator | ✅ | `37.3.10`，程序已安装 |
| 模拟器系统镜像 | ✅ | `android-37.0/google_apis_playstore/x86_64` |
| AVD | ✅ | `Medium_Phone`，1080×2400，420dpi，API 37 |
| 硬件加速 / 启动 | ✅ | WHPX 可用，已实测启动为 `emulator-5554`（`sys.boot_completed=1`） |
| SDK Licenses | ✅ | `licenses/android-sdk-license` 已接受 |
| 网络 / 代理 | ✅ | 直连与 `127.0.0.1:27017` 代理访问 Google Maven / Maven Central 均返回 200；Gradle 代理配置在 `~/.gradle/gradle.properties`（不入库） |
| 工程 SDK 指向 | ✅ | `local.properties` 已指向本机 SDK |

### 1.2 尚未具备

| 项目 | 状态 | 影响 |
|---|---|---|
| 已连接真机 | ❌ 无设备 | SAF 文件选择、系统字体和部分厂商行为仍需真机补验；日常开发与 UI 测试可用模拟器 |
| `cmdline-tools` | ❌ 未安装 | 不影响构建；Studio SDK Manager 可管理 SDK |
| Git 仓库 | ❌ 未初始化 | 不能按子任务提交/回滚；T00 只补 `.gitignore`，是否 `git init` 由你决定 |

### 1.3 需要你做的事

**强制项：无。** 当前依赖足够完成编译、单元测试、Lint 和模拟器 UI 测试；`emulator-5554` 已启动。

**可选项：**

1. T25/T26 阶段用 USB 连接一台 Android 8.0（API 26）以上真机，补验 SAF、系统字体和厂商行为；
2. 如果希望按子任务提交，确认是否执行 `git init`（见 `WBS.md` 决策 D6）。

C 盘当前剩余约 **30 GB**，仍够用；不要同时保留多个旧模拟器镜像。

---

## 2. 当前工程状态（2026-11-24 更新）

**v1 功能已实现完毕，构建、测试与 Lint 全绿。** 当前代码包含：

- 4 个一级 Tab（账本/预算/图表/设置）与 5 个二级页（记一笔、账本、分类、搜索、数据与备份）；
- Room 数据层（6 表、6 DAO（含 StatsDao）、Repository、种子数据、部分唯一索引，schema v3）；
- 金额/表达式/日期/拼音/CSV/备份纯逻辑与 58 个 JVM 单测；
- Canvas 环形图、趋势图、日历热力；
- CSV 导入导出、`MOREMONEY_BACKUP` schemaVersion=3 备份恢复（兼容旧 v1/v2，跳过私密账本并提示）；
- 全局金额隐藏、删除撤销、Snackbar、浅/深色主题、360dp 与横屏适配；
- debug 演示数据与组件 Gallery；
- 发布文档：`docs/release/`；T25 验收：`docs/tasks/T25-report.md`；质量门禁：`docs/tasks/quality-gate.md`。

验证：

```text
assembleDebug ✅   testDebugUnitTest ✅ 58   lintDebug ✅ 0 error
compileDebugAndroidTestKotlin ✅   connectedDebugAndroidTest ✅ 19（含迁移）
assembleRelease ✅（R8；无 keystore.properties 时为 unsigned）
```

未完成/需人工确认：真机复核（SAF、厂商字体、折叠屏）、正式发布 keystore、商店备案与素材。Git 仍未初始化（WBS D6），本次未做任何提交。

进度快照见 `docs/tasks/PROGRESS-2026-11-23.md`（其中 T25/T26 的收尾项已于 2026-11-24 完成，见该文档顶部说明与 `T25-report.md`、`docs/release/README.md`）。

---

## 3. 技术决策

| 项 | 决策 |
|---|---|
| 语言 / UI | Kotlin + Jetpack Compose（Material 3） |
| 构建 | Gradle 9.9.2 Wrapper + AGP 9.5.2（内置 Kotlin） |
| Kotlin | 2.4.21（Compose Compiler 插件版本与之相同） |
| Compose | Compose BOM 2026.11.01 |
| compileSdk | 37，minor 2（`compileSdkMinor = 2`），即 API 37.2 |
| targetSdk | 37 |
| minSdk | 26（Android 8.0） |
| JDK | 源码/字节码目标 17，Gradle 运行在 JDK 25 上 |
| 导航 | Navigation 3（`androidx.navigation3`），二级页使用 `@Serializable NavKey` |
| 数据 | Room 2.8.5 + KSP 2.3.14；Android 独立版 schema v3（无成员表、无 `member_id`，预算每账本一条），见 §4 |
| 图表 | Compose `Canvas` 自绘，不引入第三方图表库 |
| 网络 | v1 完全离线，不申请 `INTERNET` 权限 |
| 文件导入导出 | Storage Access Framework（`CreateDocument` / `OpenDocument`），不申请存储权限 |
| 私密账本 | ❌ v1 不做；`book` 表省略 `is_private` / `pwd_hash` / `pwd_salt` / `pwd_iter`；不实现密码、生物识别、锁定或加密备份 |
| 设置持久化 | `SharedPreferences` + `StateFlow`，不新增 DataStore 依赖 |
| 拼音 | 排序用 `java.text.Collator(Locale.CHINA)`；API 29+ 用 `android.icu.text.Transliterator`；API 26–28 降级 |
| 图标 | 43 个历史设计 SVG 通过 `tools/svg2vector.mjs` 转为 Android VectorDrawable；私密账本相关的 4 个未转换 |
| 测试 | JVM 纯逻辑测试 + 模拟器上的 Room DAO / Compose UI instrumentation 测试 + Lint |

**注意：** AGP 9 默认启用内置 Kotlin，不要再添加 `org.jetbrains.kotlin.android` 插件；当前只保留 `org.jetbrains.kotlin.plugin.compose` 和 `org.jetbrains.kotlin.plugin.serialization`。若手动改回 `kotlin-android`，会与 AGP 内置 Kotlin 冲突。

**Room/KSP 已验证：** 2026-11-23 在仓库外的最小 spike 中，Room 2.8.5 + KSP 2.3.14 + Kotlin 2.4.21 + AGP 9.5.2 编译成功，schema 正常导出。KSP 2.3+ 已改为独立版本号，不需要与 Kotlin 版本前缀一致。详情见 `docs/tasks/dependency-check-2026-11-23.md`。

---

## 4. Android 独立版数据约定（2026-11-24 起，2026-11-28 预算改造）

Android v1 不再要求与鸿蒙版互换数据，数据格式以本仓库与测试为准：

1. **Room schema v3**（`app/schemas/com.github.ppg007.moremoney.data.db.MoreMoneyDatabase/3.json`）：
   - 业务表：`book`、`category_group`、`category`、`txn`、`budget`、`app_meta`；
   - **无 `member` 表，`txn` 无 `member_id`**；
   - v1 → v2 迁移删除 `member` 表并重建 `txn`，保留全部流水、金额、日期、备注与软删状态；
   - v2 → v3 迁移把按月的 `budget` 重建为每账本一条（`cycle` + 金额），同一账本保留 `updated_at` 最新的一条；
   - 金额列以 `*_cents` 结尾，全部为整数“分”；`day_key` 使用 `YYYY-MM-DD`。
2. **预算**：一个账本只能设置年、季、月其中一个周期，设置后自动重复；其他周期金额自动折算，不再逐月保存。
3. **备份**：保持 `MOREMONEY_BACKUP`、`format=1`；`schemaVersion=3`，不再生成 `MEMBER` 行，`TXN` 行 9 列，`BOOK` 行仍为 13 列（私密占位），不生成 `PRIVATE` 段；
   - `BUDGET` 行第 3 列为 `cycle`；仍可读取 `schemaVersion=1/2` 的旧备份：`MEMBER` 行与 TXN 的 member 列忽略，旧月份字段按月度预算处理，私密账本/`PRIVATE` 跳过。
4. **CSV**：固定 9 列 `date,time,type,book,group,category,amount,note,id`；UTF-8 BOM、CRLF、金额两位小数；可导入旧 10 列文件（成员列忽略）。
5. Android 不创建私密账本；恢复旧备份时跳过 `is_private=1` 的账本与 `PRIVATE` 行，并在预览中提示。
6. 金额、表达式、日期、CSV、备份与统计以本项目 JVM 单测 + instrumentation 为规格；历史测试向量仅作回归数据来源。

---

## 5. 任务路线图

| 里程碑 | 任务 | 状态 |
|---|---|---|
| M0 工程基线 | T00 恢复可构建基线、T01 主题与 token、T02 应用外壳与导航 | ✅ 已完成 |
| M1 数据与基础 | T03 Room 数据层、T04 金额与表达式、T05 基础组件 | ✅ 已完成 |
| M2 记账闭环 | T06 账本首页、T07 记一笔、T08 账本管理、T09 成员（已删除）、T10 分类、T11 统计、T12 预算 | ✅ 已完成；T09 已删除 |
| M3 显示与图表 | T13 私密账本（已取消）、T14 金额隐藏、T15 环形图、T16 趋势图、T17 日历热力 | ❌ T13 已取消；✅ T14–T17 已完成 |
| M4 数据与设置 | T18 搜索、T19 CSV 导出、T20 CSV 导入、T21 备份恢复、T22 设置与数据页、T23 删除撤销与状态反馈 | ✅ 已完成 |
| M5 质量与发布 | T24 测试与质量门禁、T25 深色/窄屏验收、T26 发布准备 | ✅ 已完成（真机复核与正式签名待发布者执行） |

> 子任务级拆分、剩余估算、并行轨道与决策清单见 `docs/tasks/WBS.md`；依赖实测证据见 `docs/tasks/dependency-check-2026-11-23.md`。

推荐执行顺序：

```text
T00 → T01 → T02 → T03 → T04 → T05
                         ↘ T06 → T07 → T08 → T10
                                  ↘ T11 → T12 → T15 → T16 → T17
                         ↘ T18 → T19 → T20 → T21 → T22
T13 已取消；T14 依赖 T06、T12；T21 只依赖 T03；T23 依赖 T07；
T24/T25 贯穿 M2–M4，作为每个里程碑的出口检查；
T26 最后执行。
```

---

## 6. 任务明细

### T00 恢复可构建基线

- 目标：把当前中间态补齐到能稳定 `assembleDebug`，并建立可重复的构建环境。
- 交付物：
  - 补齐上节列出的 4 个 Tab 页面、资源文件、Manifest、图标、测试文件；
  - 重写 `.gitignore`，覆盖 `.gradle/`、`.kotlin/`、`.idea/`、`local.properties`、`**/build/`、`*.hprof`；
  - 确认 `local.properties` 不入库。
- 验收：
  - `./gradlew :app:assembleDebug` 成功；
  - `./gradlew :app:lintDebug` 无 error；
  - `./gradlew :app:compileDebugAndroidTestKotlin` 成功。
- 说明：T00 不新增业务功能，只恢复骨架。

### T01 主题与设计 Token

- 目标：完成浅色/深色主题、字体、圆角、间距、图标尺寸与启动背景。
- 参考：`entry/src/main/ets/theme/Theme.ets`、`Palette.ets`、`resources/base|dark/element/color.json`。
- 交付物：
  - `MoreMoneyColors` 与 Material 3 ColorScheme 映射；
  - `MoreMoneyTypography`（10–42sp，金额等宽数字 `tnum`）；
  - `Spacing` / `Radius` / `IconSize`；
  - 启动窗口背景（浅色 `#FAF8F7`，深色 `#121017`）；
  - 自适应图标（靛蓝渐变背景 + 白色 ¥）；
  - 组件中禁止写十六进制颜色，统一通过 `MoreMoneyTheme.colors`。
- 验收：
  - 浅色/深色各截一张图；
  - 对比设计规范主色、状态色、圆角、字号；
  - Lint 无硬编码颜色告警（主题文件除外）。

### T02 应用外壳与导航

- 目标：`MainActivity` + 根导航 + 4 个一级 Tab，复刻 `MainTabs.ets` 的选中态。
- 参考：`pages/Index.ets`、`components/layout/MainTabs.ets`、`resources/base/profile/router_map.json`。
- 交付物：
  - Edge-to-edge、状态栏/导航栏 Insets 处理；
  - Navigation 3 根入口 `Main`，`NavDisplay`；
  - 底部 Tab：账本 / 预算 / 图表 / 设置；
  - Tab 栏 62dp、选中胶囊 38×25dp、20dp 图标、10sp 标签、顶部 1dp 分隔线；
  - 选中 Tab 在进程重建后保持（`rememberSaveable`）；
  - 二级页参数使用 `@Serializable NavKey`，不使用字符串路由。
- 验收：
  - 四个 Tab 可切换，页面标题正确；
  - 深色模式下 Tab 栏颜色正确；
  - Compose UI 测试覆盖四个 Tab 可见和切换；
  - 系统返回键行为正确。

### T03 Room 数据层

- 目标：建立 Android 独立数据层，页面不直接写 SQL。
- 交付物：
  - Room Entity / DAO / Database（当前 version 2）；
  - 6 个业务表：`book`、`category_group`、`category`、`txn`、`budget`、`app_meta`；无 `member` 表、无 `txn.member_id`；
  - 默认账本、分类、分类组的种子数据；
  - Repository 层；
  - Room schema JSON 导出（`room.schemaLocation`），v1→v2 迁移测试。
- 验收：
  - 内存数据库 DAO 测试通过；
  - 金额分、`day_key`、软删除字段 `deleted_at` 行为正确；
  - `book` 表不含 `is_private` / `pwd_hash` / `pwd_salt` / `pwd_iter`；
  - 旧 v1 数据库升级到 v2 后流水完整保留。

### T04 金额、表达式与格式工具

- 目标：先移植纯逻辑和测试，锁死数据格式规则。
- 参考：历史工具实现与历史测试向量。
- 交付物：
  - Kotlin 版金额工具（整数分、格式化、四舍五入规则）；
  - 四则运算/百分比表达式引擎；
  - 日期区间、日键、拼音工具；
  - CSV 解析/格式化、备份格式解析；
  - 对应 JUnit 测试（优先 1:1 移植现有用例）。
- 验收：
  - `./gradlew test` 全绿；
  - 金额不存在浮点存储；
  - 固定测试向量的输入/输出保持一致。

### T05 基础组件

- 目标：建立可复用的 UI 基础层，后续页面不重复造轮子。
- 参考：`components/base/*`、`components/sheet/*`。
- 交付物：
  - 金额文本（等宽数字、隐藏金额状态）；
  - 卡片、主/次按钮、图标按钮、列表行、分段控件、徽标、空状态、错误重试；
  - Snackbar Host（供 T23 撤销使用）；
  - 确认弹层/底部 Sheet 基础容器；
  - 组件预览或 Gallery 页。
- 验收：
  - 浅/深色可用；
  - 点击区域不小于 48dp；
  - 文本支持系统字体缩放（至少到 1.3× 不截断关键数字）。

### T06 账本首页

- 目标：完成首页预算卡片、月度汇总、按日分组的流水列表。
- 参考：`pages/home/*`、`service/BudgetService.ets`。
- 交付物：Hero 预算卡、汇总卡、日期分组、流水行、空状态、金额隐藏联动。
- 验收：切换账本、月度切换、无数据状态、深色模式；点击流水可打开详情。

### T07 记一笔

- 目标：完成新增/编辑支出、金额键盘、分类选择、账本/日期选择、保存与删除撤销。
- 参考：`pages/add/*`、`components/sheet/TxnDetailSheet.ets`。
- 交付物：金额输入与表达式计算、分类选择器、账本/日期选择、备注、保存校验、编辑回填。
- 验收：新增后首页即时刷新；金额分正确；非法输入有提示；返回未保存有确认。

### T08 账本管理

- 目标：账本 CRUD、默认账本、归档、预算入口；不包含私密账本。
- 参考：`pages/books/*`、`BookDao.ets`。
- 验收：默认账本唯一；归档后不出现在选择器；排序持久化；无密码/私密开关。

### T09 成员管理（2026-11-24 已删除）

- 状态：❌ 已删除。Android 独立版不再提供成员概念：无成员表、无 `txn.member_id`、无成员筛选/选择/统计/CSV/备份字段。
- 迁移：Room v1→v2 会删除 `member` 表与 `txn.member_id`，保留流水；旧备份/CSV 中的成员字段可读取但被忽略。

### T10 分类管理

- 目标：分类组与分类 CRUD、图标/颜色、常用分类、拼音排序与搜索。
- 参考：`pages/categories/*`、`CategoryDao.ets`、`PinyinUtil.ets`。
- 验收：组内排序；常用按频率但组内拼音稳定；归档分类不参与新增选择。

### T11 统计服务

- 目标：提供分类占比、趋势、日历热力所需的聚合服务。
- 参考：`service/StatsService.ets`、`models/StatsTypes.ets`、`utils/PeriodResolver.ets`。
- 验收：本月/上月/自定义区间与本项目统计单测一致；无账本锁定/排除逻辑。

### T12 预算页

- 目标：年/季/月预算、账本预算、进度、剩余、每天可用；预算设置一次后自动重复。
- 参考：`pages/budget/*`、`BudgetService.ets`、`BudgetDao.ets`。
- 验收：预算为 0/未设置状态；超支状态；预算页无月份切换、无跨账本合计；各账本按自身周期展示；多账本有预算时可左右切换且默认展示默认账本；金额隐藏时进度条与数字一起隐藏。

### T13 私密账本（已取消）

- 状态：❌ 已取消。Android v1 只支持普通账本。
- 不交付：密码设置/解锁、PBKDF2、生物识别、Keystore 会话令牌、私密账本的金额打码/统计排除、`PRIVATE` 加密备份。
- Schema 影响：`book` 表删除 `is_private`、`pwd_hash`、`pwd_salt`、`pwd_iter`；其余表不变。
- 备份影响：Android 不生成 `PRIVATE` 行；恢复旧备份时跳过 `is_private=1` 的账本与 `PRIVATE` 行，并在预览中提示。
- 相关任务调整：T08 删除私密入口；T14 只保留全局金额隐藏；T21 删除私密加密/解密。

### T14 金额隐藏

- 目标：全局眼睛按钮，隐藏所有金额、进度、图表金额、日历热力。
- 参考：`state/GlobalUiStore.ets`、`components/base/EyeButton.ets`。
- 验收：一个开关覆盖全部页面；隐藏状态在页面间一致；不通过颜色/长度反推金额。

### T15–T17 图表

- 目标：环形图（分类占比）、趋势图（月度）、日历热力（每日支出）。
- 参考：`components/chart/*`、`pages/charts/*`。
- 交付物：Compose Canvas 绘制；图例、选中态、空数据、隐藏金额；点击钻取。
- 验收：与设计规范和归档截图对比布局与颜色；旋转/窄屏不溢出；不引入第三方图表库。

### T18 搜索

- 目标：按备注、分类、金额搜索，支持拼音。
- 参考：`pages/search/SearchPage.ets`、`PinyinUtil.ets`。
- 验收：拼音首字母命中；结果分组；空结果与清空；普通账本全部可搜索。

### T19 CSV 导出

- 目标：按筛选条件导出，使用 SAF 选择保存位置。
- 参考：`service/CsvExportService.ets`、`CsvFormat.ets`、`ExportFilterSheet.ets`。
- 验收：导出的文件可被本项目重新导入；9 列顺序固定、UTF-8 BOM、CRLF、金额两位小数；取消保存不提示失败。

### T20 CSV 导入

- 目标：选择文件、预览、校验、去重、导入。
- 参考：`service/CsvImportService.ets`（如有）、`ImportPreviewSheet.ets`、`CsvParser` 测试。
- 验收：坏行可定位；重复交易按 ID 跳过；导入后统计刷新。

### T21 备份与恢复

- 目标：导出/导入 `MOREMONEY_BACKUP`，只处理普通账本。
- 验收：
  - `schemaVersion=3` 备份可在本项目完整导出/恢复；可读取 `schemaVersion=1/2` 旧备份并忽略成员字段，旧预算按月度处理；
  - SHA-256 校验和正确；不生成 `MEMBER` 行与 `PRIVATE` 段；
  - `BOOK` 行第 5–8 列写 `0`、空、空、`10000` 占位，保持普通备份格式；
  - 恢复含私密账本的旧备份时，跳过 `is_private=1` 的账本与 `PRIVATE` 行，并在预览中提示跳过数量；
  - 恢复前预览，失败可回滚；
  - 文件通过 SAF 读写，无存储权限。

### T22 设置与数据页

- 目标：设置项、备份状态、数据统计、关于信息。
- 参考：`pages/settings/*`、`pages/data/*`。
- 验收：开关持久化；数据统计与数据库一致；隐私政策/版本号入口；无私密账本入口。

### T23 删除撤销与状态反馈

- 目标：删除流水后的 Snackbar 撤销、加载/错误/空状态统一。
- 参考：`pages/books/BookActions.ets`、`components/base/SnackBarHost.ets`。
- 验收：撤销恢复软删除数据；连续删除不串状态；错误提示可重试。

### T24 测试与质量门禁

- 目标：建立可持续的质量基线。
- 交付物：
  - 纯逻辑单元测试（金额、表达式、日期、CSV、备份、统计）；
  - Compose UI 测试（Tab、记账、删除撤销、隐藏金额）；
  - `lintDebug` 无 error；
  - 可选的 Jacoco 覆盖率报告。
- 验收：`./gradlew test lintDebug` 通过；关键工具类均有直接单测。

### T25 深色与窄屏验收

- 目标：按 `T25-dark-narrow-acceptance.md` 做双端视觉验收。
- 验收：360dp 窄屏、系统字体放大、深色模式、横屏/折叠屏基本可用；截图归档。

### T26 发布准备

- 目标：可安装的正式包。
- 交付物：签名配置、R8/ProGuard 规则、备份规则、隐私说明、商店素材、版本号策略。
- 注意：国内分发需要软件著作权和 App 备案；Google Play 需要 Data Safety 表单。v1 无网络权限、无私密账本，隐私说明应明确“完全离线，数据仅存本机”。

---

## 7. 验证命令

```bash
# 编译
./gradlew :app:assembleDebug

# 单元测试
./gradlew :app:testDebugUnitTest

# Lint
./gradlew :app:lintDebug

# 编译 UI 测试（不需要设备）
./gradlew :app:compileDebugAndroidTestKotlin

# 连接设备/模拟器后运行 UI 测试
./gradlew :app:connectedDebugAndroidTest

# 安装到设备
./gradlew :app:installDebug
```

Gradle 代理只配置在本机 `~/.gradle/gradle.properties`，不进入仓库；换机器时需重新配置或直接访问网络。

模拟器 `Medium_Phone`（`emulator-5554`）已启动，`installDebug` 与 `connectedDebugAndroidTest` 可直接使用；无真机时无需等待设备。

---

## 8. 已知风险与注意事项

1. **AGP 9 内置 Kotlin**：不要添加 `org.jetbrains.kotlin.android`；Compose Compiler 版本必须与 Kotlin 一致（当前 2.4.21）。
2. **compileSdk 37.2**：Compose BOM 2026.11.01 要求至少 37.1；本机已安装 37.2，换机器需同步安装 `platforms/android-37.2`。
3. **Navigation 3**：与旧版 `navigation-compose` API 不同，不要混用；二级页统一用 `@Serializable NavKey`。
4. **备份格式自洽**：以本项目 `BackupFormat`/`BackupService` 测试为合同；v2 不生成 `MEMBER`/`PRIVATE`，恢复旧 v1 备份时忽略成员字段并跳过私密账本；每次改格式都要同时改测试。
5. **金额精度**：全链路整数分；任何 UI、导入、统计、备份都不允许出现浮点金额。
6. **私密账本已取消**：Android 不实现密码、生物识别、锁定或加密备份；`book` 表删除私密列；不要引入 `PrivateBookService` / `CryptoUtil` / `UnlockSheet`。
7. **磁盘**：Gradle + SDK + 工具链与模拟器镜像已占用较多空间；C 盘剩余约 30 GB，不要再安装多个旧镜像。
8. **中文排版**：使用系统 CJK 字体，金额用 `tnum`；窄屏不要把 10sp 辅助文字继续缩小。
9. **拼音降级**：Android API 26–28 没有系统汉字转拉丁能力；按 `WBS.md` 决策 D2 使用 `Collator` 排序 + 低版本首字母降级，不要静默改变排序。
10. **Room 部分索引**：`idx_book_default` 需在 `RoomDatabase.Callback.onCreate` 中创建；Room 导出的 schema JSON 不包含它，需在文档与测试中单独覆盖。
11. **系统自动备份**：Manifest 使用 `android:allowBackup="false"`，避免数据库进入系统云备份；T26 再评估。
12. **Git**：工程尚未初始化仓库；T00 只补 `.gitignore`，不要擅自 `git init`，需要时由你确认。
13. **Schema 以本仓库为准**：`book` 表只有 9 个普通列、无私密列；`member` 表已删除；以 `app/schemas/.../2.json` 与迁移测试为准。
