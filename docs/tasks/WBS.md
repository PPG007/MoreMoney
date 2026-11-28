# MoreMoney Android 详细任务拆分（WBS）

- 日期：2026-11-23
- 上游：`docs/tasks/README.md`
- 依赖复核：`docs/tasks/dependency-check-2026-11-23.md`
- 参考实现：`C:\Users\16582\workspace\MoreMoney`（HarmonyOS / ArkTS）
- 编号规则：沿用早期迁移计划的历史编号；Android 专有基线为 `T00`；子任务用 `Txx.y`
- 估算单位：人日（1 人、熟悉 Kotlin/Compose、已有参考实现）
- 状态：✅ 已完成 ｜ 🟡 部分完成 ｜ ⬜ 未开始

> **2026-11-24 实现进度：** T00–T08、T10–T26 完成（T09 已删除、T13 已取消）。构建、58 个 JVM 单测、19 个 instrumentation（含 v1→v2 迁移测试）、Lint 0 error、Release（R8）构建与签名安装/升级/降级验证均通过；深色/360dp/1.3× 字体/横屏验收见 `docs/tasks/T25-report.md`，发布文档见 `docs/release/`，暂停/续做快照见 `docs/tasks/PROGRESS-2026-11-23.md`，截图见 `docs/screenshots/`。
>
> **2026-11-24 范围变更：** Android 改为独立应用，**删除成员管理**。本文件中 T06/T07/T09/T11/T18/T19/T20/T22 涉及成员的子项均不再适用；Room schema 升为 v2（无 `member` 表/`member_id`，保留流水迁移），CSV 9 列（旧 10 列可导入并忽略成员），备份 `schemaVersion=2`（可读旧 v1 并忽略成员）。
>
> **2026-11-28 预算改造：** Room schema 升为 v3。`budget` 表改为每个账本一条配置（`cycle` = `YEAR`/`QUARTER`/`MONTH` + 金额，唯一索引 `idx_budget_book`），设置后自动按周期重复；旧版按月预算迁移时保留每账本最新一条。备份 `schemaVersion=3`，仍兼容读取 v1/v2。T12 口径与页面同步更新。

---

## 0. 先看结论

1. **当前唯一下一步是 T00。** 构建失败在缺失 `AndroidManifest.xml`；T00 完成前不要动 T03/T06 等业务代码。
2. **T03 不需要改技术路线。** Room 2.8.5 + KSP 2.3.14 + Kotlin 2.4.21 + AGP 9.5.2 已实测通过，schema 可正常导出。
3. **模拟器已可用。** `emulator-5554` 已启动（API 37，1080×2400），可以直接安装 APK、跑 Room DAO 测试和 Compose UI 测试。
4. **建议顺序：** `T00 → T01/T02 → T03 ∥ T04 → T05 → T06/T07 → T08–T12 → T14–T17 → T18–T23 → T24–T26`。T13 已取消。
5. **T01/T02 不是从零开始。** 主题、根导航、Tab 栏已有 50%–70% 的实现，剩余工作已拆到子任务，避免重复劳动。
6. **范围变更（2026-11-23）：** Android v1 **取消私密账本**，只保留普通账本。T13 已取消；`book` 表删除私密列；备份不生成 `PRIVATE` 段。详见 D3 与 T13。
7. **两件事需要你拍板**（不阻塞 T00）：
   - API 26–28 的拼音搜索是否接受降级（D2）；
   - 是否执行 `git init` 并按子任务提交（D6）。

---

## 1. 工程结构与命名

### 1.1 目标目录

```text
app/src/main/kotlin/com/github/ppg007/moremoney/
  MainActivity.kt
  MoreMoneyApp.kt                 # T03 起：持有 AppContainer
  Navigation.kt
  NavigationKeys.kt
  data/
    db/
      MoreMoneyDatabase.kt
      entity/                     # BookEntity、TxnEntity...
      dao/                        # BookDao、TxnDao...
      SeedData.kt
      DatabaseProvider.kt
    repository/                   # BookRepository、TxnRepository...
  domain/model/                   # UI 使用的领域模型（可与 Entity 合并）
  service/                        # StatsService、BudgetService、DeleteService...
  state/                          # AppUiState、SettingsService
  ui/
    theme/                        # 已有 Color/Type/Dimens/Theme
    components/base/              # MoneyText、AppCard、PrimaryButton...
    components/sheet/             # 通用弹层
    components/chart/             # Canvas 图表
    main/MainScreen.kt            # 已有
    ledger/LedgerScreen.kt        # 一级 Tab：账本首页
    budget/BudgetScreen.kt        # 一级 Tab：预算
    charts/ChartsScreen.kt        # 一级 Tab：图表
    settings/SettingsScreen.kt    # 一级 Tab：设置
    add/AddTxnScreen.kt
    books/BookManageScreen.kt
    categories/CategoryManageScreen.kt
    data/DataBackupScreen.kt
    search/SearchScreen.kt
  util/                           # MoneyUtil、DateUtil、CsvParser...
app/src/test/kotlin/...           # JVM 纯逻辑测试
app/src/androidTest/kotlin/...    # Room DAO + Compose UI 测试
app/src/debug/kotlin/...          # 演示数据、组件 Gallery（不进正式包）
app/schemas/                      # Room 导出的 schema JSON，必须入库
tools/svg2vector.mjs              # 历史 SVG → Android VectorDrawable
tools/material-icons2vector.mjs   # Material Icons Outlined → Android VectorDrawable
```

### 1.2 命名约定

| 类型 | 约定 | 示例 |
|---|---|---|
| 页面 | `*Screen` | `LedgerScreen` |
| 弹层 | `*Sheet` / `*Dialog` | `BookEditSheet` |
| 组件 | `*Card` / `*Row` / `*Button` | `TxnRow` |
| DAO | `*Dao` | `TxnDao` |
| 业务服务 | `*Service` | `BudgetService` |
| 纯函数工具 | `*Util` | `MoneyUtil` |
| 导航键 | `@Serializable NavKey` | `AddTxn` |

### 1.3 与历史实现的写法差异

| 历史写法 | Android 对应 |
|---|---|
| `@ObservedV2` / `@Trace` | `mutableStateOf` / `StateFlow` |
| `AppStorageV2` | `CompositionLocal` + 单例 `AppUiState` |
| `Navigation` + `router_map.json` | Navigation 3 + `@Serializable NavKey` |
| `relationalStore` | Room |
| `Canvas 2D` | Compose `Canvas` |
| `i18n.Transliterator` | API 29+ `android.icu.text.Transliterator`，低版本降级 |
| `userAuth` / `PrivateBookService` | **不做**：Android v1 无私密账本、无生物识别 |
| `DocumentViewPicker` | Storage Access Framework（`CreateDocument` / `OpenDocument`） |
| `Preferences` | `SharedPreferences` |

---

## 2. 全局完成定义（DoD）

每个子任务完成前必须满足：

1. `./gradlew :app:assembleDebug` 成功；
2. 该子任务涉及的单元测试通过；
3. `./gradlew :app:lintDebug` 无 error（警告需记录）；
4. 新增 instrumentation 测试能通过 `./gradlew :app:compileDebugAndroidTestKotlin`；
5. UI 改动在浅色、深色各截一张图（模拟器即可）；
6. 组件中不出现十六进制颜色（`ui/theme/` 与 `Palette.kt` 除外）；
7. 金额全链路使用整数分，不出现 `Double` / `Float`；
8. 页面/UI 不直接写 SQL，不直接操作 `SupportSQLiteDatabase`；
9. 对应的 README/WBS 状态已更新；
10. 不新增未在文档中声明的第三方依赖。

### 2.1 验证命令

```bash
./gradlew :app:assembleDebug
./gradlew :app:testDebugUnitTest
./gradlew :app:lintDebug
./gradlew :app:compileDebugAndroidTestKotlin

# 模拟器已启动时可运行
./gradlew :app:connectedDebugAndroidTest
./gradlew :app:installDebug
```

### 2.2 常见红线

- `transaction`、`book`、`category` 等表名/列名不得改；金额列必须以 `_cents` 结尾。
- **Schema：** 以 `app/schemas/.../2.json` 为准；`book` 表只保留 9 个普通列（无 `is_private` / `pwd_hash` / `pwd_salt` / `pwd_iter`），无 `member` 表、无 `txn.member_id`。
- 备份文件 `MOREMONEY_BACKUP`、`format=1`、`schemaVersion=3`、校验和算法不得改；兼容读取 v1/v2 旧备份；Android 不生成 `PRIVATE` 段。
- CSV 列顺序、UTF-8 BOM、CRLF、金额两位小数不得改。
- Android 不实现私密账本：无密码、无生物识别、无锁定、无 PBKDF2/AES-GCM、无 `PrivateBookService`。
- 恢复旧备份时跳过 `is_private=1` 的账本与 `PRIVATE` 行，并在预览中提示；不得把私密数据当作普通账本导入。

---

## 3. 任务总表

| ID | 任务 | 状态 | 依赖 | 剩余估算 | 子任务数 |
|---|---|---|---:|---:|---:|
| T00 | 恢复可构建基线 | ✅ | — | 0.5 | 6 |
| T01 | 主题与设计 Token | ✅ | T00 | 1.0 | 6 |
| T02 | 应用外壳与导航 | ✅ | T00、T01 | 1.0 | 5 |
| T03 | Room 数据层 | ✅ | T00 | 2.5 | 9 |
| T04 | 金额/表达式/格式工具 | ✅ | T00 | 2.0 | 8 |
| T05 | 基础组件与全局状态 | ✅ | T01、T02、T03 | 2.0 | 7 |
| T06 | 账本首页 | ✅ | T03、T05、T11、T12 | 2.5 | 6 |
| T07 | 记一笔 | ✅ | T03、T04、T05 | 3.0 | 6 |
| T08 | 账本管理 | ✅ | T03、T05、T12 | 1.0 | 4 |
| T09 | 成员管理（2026-11-24 已删除） | ❌ | — | 0 | 0 |
| T10 | 分类管理 | ✅ | T03、T04、T05 | 1.5 | 5 |
| T11 | 统计聚合服务 | ✅ | T03、T04 | 1.5 | 5 |
| T12 | 预算页 | ✅ | T05、T11 | 2.0 | 6 |
| T13 | 私密账本（已取消） | ❌ | — | 0 | 0 |
| T14 | 金额隐藏 | ✅ | T05、T06、T12、T15–T17 | 1.0 | 4 |
| T15 | 环形图 | ✅ | T05、T11 | 2.0 | 5 |
| T16 | 趋势图 | ✅ | T15 | 1.5 | 4 |
| T17 | 日历热力 | ✅ | T11、T15 | 1.5 | 4 |
| T18 | 搜索 | ✅ | T03、T05 | 1.0 | 4 |
| T19 | CSV 导出 | ✅ | T03、T11 | 1.0 | 4 |
| T20 | CSV 导入 | ✅ | T03、T19 | 1.5 | 5 |
| T21 | 备份与恢复 | ✅ | T03 | 1.5 | 5 |
| T22 | 设置与数据页 | ✅ | T05、T19–T21 | 1.0 | 4 |
| T23 | 删除撤销与状态反馈 | ✅ | T06、T07 | 1.0 | 5 |
| T24 | 测试与质量门禁 | ✅ | 全部 | 1.5 | 4 |
| T25 | 深色/窄屏验收 | ✅ | 全部 | 1.0 | 3 |
| T26 | 发布准备 | ✅ | 全部 | 1.5 | 4 |

**合计约 38.5 人日。** T01/T02 的估算只算剩余工作；若从零重做，分别约 1.5 / 1.0 人日。T13 已取消，不计入总量。

---

## 4. 详细拆分

### T00 · 恢复可构建基线

**目标：** 补齐骨架，让 `assembleDebug`、`lintDebug`、`compileDebugAndroidTestKotlin` 三条命令恢复绿色；不实现业务功能。

**当前事实：** 构建失败于 `processDebugMainManifest`，`app/src/main/AndroidManifest.xml` 不存在；`MainScreen.kt` 还引用了 4 个不存在的页面、多个字符串和 4 个 Tab 图标。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T00.1 | `AndroidManifest.xml`：`application`、`MainActivity`（exported launcher）、`allowBackup=false`、`enableOnBackInvokedCallback=true`、`windowSoftInputMode=adjustResize`、`testInstrumentationRunner` 写入 `app/build.gradle.kts` | manifest 合并通过 |
| T00.2 | `res/values/strings.xml`：`app_name`、`tab_ledger`、`tab_budget`、`tab_charts`、`tab_settings`、`placeholder_*`、`color_*`；4 个占位页 `LedgerScreen`、`BudgetScreen`、`ChartsScreen`、`SettingsScreen`，均调用 `PlaceholderScreen` | Kotlin import 全部解析 |
| T00.3 | `res/values/themes.xml`、`values-night/themes.xml`、`values-v31/themes.xml`、`colors.xml`、`values-night/colors.xml`；浅色窗口背景 `#FAF8F7`、深色 `#121017`；状态栏/导航栏透明 | 启动无白屏/黑屏闪烁 |
| T00.4 | 4 个 Tab 图标 VectorDrawable：`ic_tab_books`、`ic_tab_budget`、`ic_tab_charts`、`ic_tab_settings`；自适应图标 `ic_launcher_background` / `ic_launcher_foreground`（可先用历史 PNG） | `R.drawable` 全部存在 |
| T00.5 | 测试骨架：`app/src/test/.../SmokeTest.kt`（JUnit）、`app/src/androidTest/.../MainScreenSmokeTest.kt`（Compose）；补 `app/proguard-rules.pro` | `compileDebugAndroidTestKotlin` 成功 |
| T00.6 | `.gitignore` 补全：`.gradle/`、`.kotlin/`、`.idea/`、`local.properties`、`**/build/`、`captures/`、`*.hprof`、`*.iml`；确认 `app/schemas/` 不被忽略 | `git status` 无构建产物（若已 init） |

**关键实现细节：**

- Manifest 的 `android:name` 暂不指向 `MoreMoneyApp`，避免 T00 引入空类；T03.6 再补。
- 主题建议：

```xml
<!-- values/themes.xml -->
<style name="Theme.MoreMoney.Base" parent="@android:style/Theme.Material.Light.NoActionBar">
  <item name="android:windowBackground">@color/start_window_background</item>
  <item name="android:statusBarColor">@android:color/transparent</item>
  <item name="android:navigationBarColor">@android:color/transparent</item>
  <item name="android:windowLightStatusBar">true</item>
</style>
<style name="Theme.MoreMoney" parent="Theme.MoreMoney.Base" />
```

`values-night` 改用 `Theme.Material.NoActionBar` 并关闭 `windowLightStatusBar`；`values-v31` 追加 `android:windowSplashScreenBackground` 与 `android:windowSplashScreenAnimatedIcon`。

- `allowBackup=false` 是隐私决策（D5）；T26 再评估备份规则。
- 4 个占位页的包名必须保持 `ui.ledger`、`ui.budget`、`ui.charts`、`ui.settings`，因为现有 `ui/main/MainScreen.kt` 已按这些包名 import。
- T00 只创建 4 个 Tab 图标；其余 43 个图标在 T01.4 统一转换。

**验收命令：**

```bash
./gradlew :app:assembleDebug
./gradlew :app:lintDebug
./gradlew :app:compileDebugAndroidTestKotlin
./gradlew :app:installDebug
adb shell am start -n com.github.ppg007.moremoney/.MainActivity
```

---

### T01 · 主题与设计 Token

**目标：** 把设计规范中的颜色、字号、间距、圆角、阴影、动效、图标固化为唯一来源。

**现状（🟡）：**

- ✅ `Color.kt` 已覆盖大部分浅/深色 token；缺 `bezel`（Android 可不用）。
- ✅ `Type.kt` 已覆盖 10–42sp 的主要字号；缺 24sp、26sp 等专用字号。
- ✅ `Dimens.kt` 已覆盖 `Spacing`、`Radius`、`IconSize`。
- ✅ `Theme.kt` 已映射 Material 3 ColorScheme 与 Shapes。
- ❌ 缺图表色/`withAlpha`。
- ❌ 缺阴影、动效 token。
- ❌ 图标全部未落地；自适应图标引用的 drawable 不存在。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T01.1 | 对照 `MoreMoney/docs/tasks/T01-theme-tokens.md` §3.1 审计 `Color.kt`；补缺失 token；统一命名 | 浅/深 key 一一对应 |
| T01.2 | 补专用字号：`amountInput=26sp`、`ringCenter=24sp`、`stat=16sp` 等；新增 `MoreMoneyTextStyles`；金额统一 `tabularNumbers()` | 首页 42sp、记一笔 26sp、环形图 24sp 可引用 |
| T01.3 | 新增 `Palette.kt`：`ChartColors`（5 槽 + other）、`SeedColors`、`withAlpha()`；取值来自设计规范与历史配色 | 单测/预览验证 alpha 转换 |
| T01.4 | `tools/svg2vector.mjs`：把 43 个 v1 需要的 `ic_*.svg` 转成 `res/drawable/*.xml`；处理多 path、`fill-rule=evenodd`。分类补充图标用 `tools/material-icons2vector.mjs`（Google Material Icons Outlined，Apache 2.0） | 所有 drawable 生成，构建通过；内置分类图标互不相同 |
| T01.5 | 自适应图标 + 启动窗口：复用历史 `background.png` / `foreground.png`；`values-v31` 配置 splash | 模拟器冷启动背景色正确 |
| T01.6 | 审计 + 截图：`grep` 确认组件无十六进制颜色；浅/深各截首页与 Tab 栏 | Lint 无硬编码颜色 error |

**图标清单（43 个；私密账本相关的 `ic_lock`、`ic_unlock`、`ic_fingerprint`、`ic_face` 不转换）：**

- Tab：`ic_tab_books`、`ic_tab_budget`、`ic_tab_charts`、`ic_tab_settings`
- 通用：`ic_back`、`ic_close`、`ic_plus`、`ic_chevron_left`、`ic_chevron_right`、`ic_eye`、`ic_eye_off`、`ic_search`、`ic_calendar`、`ic_member`、`ic_book`、`ic_edit`、`ic_trash`、`ic_archive`、`ic_file`、`ic_cloud`、`ic_warning`、`ic_undo`、`ic_more`、`ic_check`
- 分类：`ic_cat_food`、`ic_cat_transport`、`ic_cat_home`、`ic_cat_shopping`、`ic_cat_entertain`、`ic_cat_medical`、`ic_cat_study`、`ic_cat_water`、`ic_cat_power`、`ic_cat_phone`、`ic_cat_travel`、`ic_cat_repair`、`ic_cat_other`
- 账本封面：`ic_book_daily`、`ic_book_travel`、`ic_book_family`、`ic_book_study`、`ic_book_work`、`ic_book_repair`

**转换脚本要求：**

- 输入：`MoreMoney/entry/src/main/resources/base/media/ic_*.svg`
- 输出：`app/src/main/res/drawable/ic_*.xml`
- 规则：`width/height=24dp`、`viewport=24`、`pathData` 原样、`fillColor="#FF000000"`、`fillType="evenOdd"`（仅当 SVG 有 `fill-rule`）
- 可重复执行；输出文件头加“自动生成，勿手改”。

**验收：**

```bash
./gradlew :app:assembleDebug
grep -rn "Color(0x" app/src/main/kotlin --include='*.kt' | grep -v 'ui/theme/'
```

---

### T02 · 应用外壳与导航

**目标：** 完成 Edge-to-edge、4 个一级 Tab、6 个二级页入口、系统返回与状态栏样式。

**现状（🟡）：**

- ✅ `MainActivity` 已 `enableEdgeToEdge()`。
- ✅ `Navigation.kt` 已使用 Navigation 3 的 `rememberNavBackStack(Main)` + `NavDisplay`。
- ✅ `MainScreen` 已实现 62dp Tab 栏、38×25 选中胶囊、20dp 图标、10sp 标签、1dp 顶部分隔线、`rememberSaveable` 选中态。
- ❌ 缺 6 个二级页 NavKey、占位页和 `NavDisplay` 条目。
- ❌ 缺状态栏图标颜色随 Tab 切换。
- ❌ 缺 UI 测试。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T02.1 | Edge-to-edge Insets：一级页 `statusBarsPadding`；Tab 栏 `navigationBarsPadding`；避免 Scaffold 双重 inset | 4 个 Tab 页面文字不被状态栏/导航栏遮挡 |
| T02.2 | Tab 栏收尾：核对 62dp、38×25、20dp、10sp、选中色；给每个 Tab 加 `testTag` | 与设计规范 §7.1 截图一致 |
| T02.3 | `NavigationKeys.kt` 增加 `@Serializable` 键：`AddTxn(bookId, dayKey)`、`BookManage`、`CategoryManage`、`DataBackup`、`Search`；新增 5 个占位 Screen；`NavDisplay` 注册 | 5 个页面可 push/pop |
| T02.4 | 将 `MainScreen` 的导航回调接入：FAB/设置行等入口后续任务使用；系统返回键由 `NavDisplay` 处理 | 返回后回到原 Tab，选中态不变 |
| T02.5 | 状态栏图标：一级页默认深色；首页 Hero 完成后切白色；二级页深色。封装 `SystemBarAppearance` | 浅/深背景下图标可读 |

**状态栏实现建议：**

```kotlin
val view = LocalView.current
val window = (view.context as Activity).window
SideEffect {
  WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !useLightIcons
}
```

在 T02 阶段首页还是占位页，`useLightIcons=false`；T06 的 Hero 出现后再切 `true`。

**UI 测试（T02.5）：**

- 四个 Tab 文案可见；
- 点击每个 Tab 后对应标题可见；
- 从设置页的“账本管理”入口打开二级页，再按返回，选中 Tab 仍为设置；
- `ActivityScenario.recreate()` 后选中 Tab 保持。

---

### T03 · Room 数据层

**目标：** 建立 Android 独立数据层（schema v3，无成员表），页面只依赖 DAO/Repository，不直接写 SQL。

**前置：** Room + KSP 兼容性已实测通过（见依赖复核 §4.1）。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T03.1 | 版本目录增加 `room=2.8.5`、`ksp=2.3.14`、`coroutines-android=1.10.2`；根/app 应用 KSP；配置 `room.schemaLocation` | `assembleDebug` 成功 |
| T03.2 | 6 个 Entity：`BookEntity`、`CategoryGroupEntity`、`CategoryEntity`、`TxnEntity`、`BudgetEntity`、`AppMetaEntity`；所有列名用 `@ColumnInfo` 显式声明；无 `MemberEntity` | `PRAGMA table_info` 与 `2.json` 一致 |
| T03.3 | `MoreMoneyDatabase`（version=3，`exportSchema=true`）；`MIGRATION_1_2` 删除成员表/列并重建 `txn`；`MIGRATION_2_3` 把按月的 `budget` 表重建为每账本一条（`cycle` + 金额）；部分唯一索引 `idx_book_default` 用 `RoomDatabase.Callback.onCreate/onOpen` 执行 SQL | `PRAGMA index_list(book)` 含 `idx_book_default` |
| T03.4 | 6 个 DAO：Book/Category/Txn/Budget/AppMeta/Stats；列表查询返回 `Flow`，写操作 `suspend`；动态筛选用 `@RawQuery` | DAO 方法覆盖页面与统计需求 |
| T03.5 | 幂等种子数据：固定 ID、名称、颜色、拼音、图标；3 个普通账本；18 个内置分类；`app_meta.seed_version=3`（v1 升级时按旧默认名称原地改名并归档旧“其他”，v2 升级时把默认图标换成各自独立图标） | 连续启动 3 次不重复；18 个内置分类图标互不相同 |
| T03.6 | `MoreMoneyApp` + `AppContainer`：持有数据库、Repository、SettingsService；Manifest 注册 | 冷启动可拿到单例 |
| T03.7 | Instrumentation DAO 测试：CRUD、软删/恢复、默认账本唯一、dayKey 边界、预算 upsert、种子幂等；断言 `book` 表没有 `is_private` / `pwd_hash` / `pwd_salt` / `pwd_iter` | `connectedDebugAndroidTest` 全绿 |
| T03.8 | 调试演示数据 `DebugSeedService` 放 `src/debug`：4 账本、30 笔本月流水、2 个预算 | 仅 debug 包可见 |
| T03.9 | 提交 `app/schemas/.../1.json` 与 `2.json`；在 `docs/tasks/` 记录 v2 迁移与部分索引例外；迁移测试按 v1 schema 建库 | schema JSON 入库，`MigrationTest` 通过 |

**表结构：** 以 `app/schemas/.../2.json` 为准；表名、列名、索引不得随意改。`book` 表使用以下 9 列：

```sql
CREATE TABLE book (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  color TEXT NOT NULL,
  is_default INTEGER NOT NULL DEFAULT 0,
  sort INTEGER NOT NULL DEFAULT 0,
  archived INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

**不要**给 `book` 表添加 `is_private`、`pwd_hash`、`pwd_salt`、`pwd_iter` 私密列。

**Entity 注意点：**

| 实体 | 注意点 |
|---|---|
| `BookEntity` | 仅 9 个普通字段；无 `isPrivate`/`pwdHash`/`pwdSalt`/`pwdIter`；`isDefault`、`archived` 用 `Boolean` |
| `CategoryGroupEntity` | `isSystem` 布尔 |
| `CategoryEntity` | `pinyin` 默认空串；`archived` 布尔 |
| `TxnEntity` | `amountCents: Long`；`occurredAt: Long`；`dayKey: String`；`deletedAt: Long?` |
| `BudgetEntity` | `amountCents: Long`；`(bookId, period)` 唯一索引 |
| `AppMetaEntity` | `key` 主键；`value` 非空 |

**部分唯一索引：**

Room 的 `@Index` 不支持 `WHERE is_default = 1`。在 `Callback.onCreate` 中执行：

```sql
CREATE UNIQUE INDEX IF NOT EXISTS idx_book_default ON book(is_default) WHERE is_default = 1
```

**不要**在 `BookEntity` 的 `@Entity(indices = ...)` 里声明 `is_default` 唯一索引，否则 Room 会再建一个非部分索引，与回调冲突，也改变 schema JSON。

并在 DAO 测试中用 `PRAGMA index_list('book')` 断言其存在。schema JSON 不会包含该索引，需在文档中注明。

**种子数据（必须逐字一致）：**

| 类型 | ID | 名称 | 其他 |
|---|---|---|---|
| 账本 | `book_daily` | 日常账本 | `ic_book_daily`、`#2A78D6`、默认、sort 0 |
| 账本 | `book_travel` | 旅行 | `ic_book_travel`、`#EB6834`、sort 1 |
| 账本 | `book_repair` | 装修 | `ic_book_repair`、`#1BAF7A`、sort 2 |
| 分组 | `group_food` | 餐饮 | sort 0 |
| 分组 | `group_travel` | 出行 | sort 1 |
| 分组 | `group_home` | 居家 | sort 2 |
| 分组 | `group_shop` | 购物 | sort 3 |
| 分组 | `group_leisure` | 休闲 | sort 4 |
| 分组 | `group_other` | 其他 | sort 5 |

所有种子账本均为普通账本；所有种子分组 `is_system=1`；所有种子分类 `archived=0`。种子账本/分类/分组的 `createdAt` 用同一次启动的当前时间。成员种子已于 2026-11-24 删除。

分类（18 个）：

| ID | 分组 | 名称 | 图标 | 颜色 | 拼音 | sort |
|---|---|---|---|---|---|---:|
| `cat_food` | `group_food` | 饮食 | `ic_cat_food` | `#EB6834` | `yinshi` | 0 |
| `cat_water` | `group_home` | 电费 | `ic_cat_power` | `#008300` | `dianfei` | 0 |
| `cat_shopping` | `group_home` | 日用 | `ic_cat_daily` | `#E87BA4` | `riyong` | 1 |
| `cat_transport` | `group_travel` | 交通 | `ic_cat_transport` | `#2A78D6` | `jiaotong` | 0 |
| `cat_social` | `group_leisure` | 社交 | `ic_cat_social` | `#EDA100` | `shejiao` | 0 |
| `cat_home` | `group_home` | 住房物业 | `ic_cat_home` | `#1BAF7A` | `zhufangwuye` | 2 |
| `cat_parking` | `group_travel` | 停车费 | `ic_cat_parking` | `#2A78D6` | `tingchefei` | 1 |
| `cat_carwash` | `group_travel` | 洗车 | `ic_cat_carwash` | `#008300` | `xiche` | 2 |
| `cat_gift` | `group_shop` | 礼物 | `ic_cat_gift` | `#E87BA4` | `liwu` | 0 |
| `cat_phone` | `group_other` | 通信 | `ic_cat_phone` | `#B8AAB1` | `tongxin` | 0 |
| `cat_work` | `group_other` | 工作 | `ic_cat_work` | `#6250D6` | `gongzuo` | 1 |
| `cat_clothing` | `group_shop` | 服饰 | `ic_cat_clothing` | `#E87BA4` | `fushi` | 1 |
| `cat_entertain` | `group_leisure` | 娱乐 | `ic_cat_entertain` | `#EDA100` | `yule` | 1 |
| `cat_beauty` | `group_other` | 美容 | `ic_cat_beauty` | `#E87BA4` | `meirong` | 2 |
| `cat_medical` | `group_other` | 医疗 | `ic_cat_medical` | `#E34948` | `yiliao` | 3 |
| `cat_tax` | `group_other` | 税金 | `ic_cat_tax` | `#B8AAB1` | `shuijin` | 4 |
| `cat_study` | `group_other` | 教育 | `ic_cat_study` | `#6250D6` | `jiaoyu` | 5 |
| `cat_travel` | `group_travel` | 旅行 | `ic_cat_travel` | `#EB6834` | `lvxing` | 3 |

> 2026-11-28：内置分类由 v1 的 10 个调整为以上 18 个。种子版本升为 2；v1 升级时仅在名称仍为旧默认值时重命名（保留 ID 与流水关联），旧“其他”分类归档。

**预算记录（v3）：** 每个账本最多一条，`budget_<bookId>`；`cycle` 为 `YEAR`/`QUARTER`/`MONTH`，唯一索引 `idx_budget_book`。设置一次后按周期自动重复，不再按月保存；其他周期金额由 `BudgetCycleUtil` 自动折算。

**DAO 方法与语义：**

| DAO | 方法 |
|---|---|
| `BookDao` | `list()`、`get(id)`、`insert`、`update`、`setDefault`、`archive`、`delete`、`countTxns`、`countOtherActive` |
| `CategoryDao` | `listGroups()`、`listByGroup(groupId)`、`get`、`insert`、`update`、`archive`、`delete`、`listFrequent(limit, sinceMs)`、`insertGroup`、`renameGroup`、`deleteGroup` |
| `TxnDao` | `insert`、`update`、`softDelete`、`restore`、`hardDeleteExpired`、`listByDay`、`listRange`、`listRecent`、`moveToBook`、`sumRange`、`countByBook`、`countByCategory`、`search` |
| `BudgetDao` | `get(bookId, period)`、`upsert`、`list(period)`、`listAll`、`remove` |
| `AppMetaDao` | `get(key)`、`set(key, value)` |

- 列表排序：账本 `archived ASC, sort ASC, created_at ASC`；分类 `archived ASC, pinyin ASC, sort ASC`；流水 `occurred_at DESC, created_at DESC`。
- 所有流水查询默认 `deleted_at IS NULL`；`listDeleted` 例外。
- `setDefault` 必须在事务内先清零再置一。
- 删除账本：有流水（含软删）时拒绝；默认账本必须先指定新默认。
- 删除分类：被引用时只允许归档。

**验收：**

```bash
./gradlew :app:connectedDebugAndroidTest
./gradlew :app:assembleDebug
```

- 内存数据库 DAO 测试通过；
- `book` 表 `SUM(is_default)=1`；
- 金额写入/读出为整数分；
- 连续 3 次启动种子不重复；
- schema JSON 已生成并入库。

---

### T04 · 金额、表达式与格式工具

**目标：** 先移植纯逻辑和测试，锁死数据格式规则。此任务不依赖 Android 框架，可与 T03 并行。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T04.1 | `MoneyUtil.kt`：`formatCents`、`formatYuan`、`parseYuanToCents`、`roundHalfUp`，全部 `Long` 分 | MoneyUtil 测试全绿 |
| T04.2 | `ExpressionEngine.kt` + `CalcTypes.kt`：状态机、1e-6 元整数、预览/错误 | 17 个表达式用例全绿 |
| T04.3 | `DateUtil.kt` / `PeriodResolver.kt`：`java.time`，`Clock` 注入；dayKey/monthKey/周起点/月范围/自定义区间 | DateUtil、Period 测试全绿 |
| T04.4 | `PinyinUtil.kt`：排序键用 `Collator`；API 29+ 用 `Transliterator`；26–28 降级 | 拼音测试 + 低版本降级测试 |
| T04.5 | `IdUtil.kt`（UUID）、`ErrorUtil.kt`（异常消息归一化） | 单测 |
| T04.6 | `CsvFormat.kt` + `CsvParser.kt`：RFC4180、BOM、CRLF、公式注入 | CsvFormat/CsvParser 测试全绿 |
| T04.7 | `BackupFormat.kt`：头/正文/`[BODY]`/`[END]`、校验和解析、未知行忽略 | BackupFormat 测试全绿 |
| T04.8 | 历史测试向量：`app/src/test/resources/compat/*.tsv`，作为回归数据；文档记录 | 同一向量输入输出稳定 |

**MoneyUtil 必测用例：**

| 输入 | 期望 |
|---|---|
| `formatCents(128640)` | `¥1,286.40` |
| `formatCents(128640, symbol=false)` | `1,286.40` |
| `formatCents(-1200)` | `−¥12.00`（U+2212） |
| `formatYuan(1230)` | `12.30` |
| `parseYuanToCents("12.3")` | `1230` |
| `parseYuanToCents(".5")` | `500` |
| `parseYuanToCents("12.345")` | `null` |
| `parseYuanToCents("-1")` | `null` |
| `parseYuanToCents("abc")` / `""` / `"1.2.3"` | `null` |
| `roundHalfUp(1.5)` / `(-1.5)` | `2` / `-2` |

**表达式引擎必测用例：**

| 输入 | 期望 |
|---|---|
| `12+3` | `1500` 分 |
| `1+2×3` | `700` |
| `10−4` | `600` |
| `10÷4` | `250` |
| `10÷3` | `333` |
| `1÷3×3` | `100` |
| `0.1+0.2` | `30` |
| `12..3` | `1230` |
| `5−8` | `NEGATIVE` |
| `0` | `ZERO` |
| `1÷0` | `DIVIDE_BY_ZERO` |
| `3×` | `INVALID` |
| `999999.99×9` | `899999991` |
| 空表达式 | `EMPTY` |
| 退格删除 `12+` 的 `+` | `12`，求值 `1200` |
| `00` | `ZERO` |
| 连续 `+` 再 `×` | 表达式为 `0×` |

**Date/Period 测试：** 直接移植 `MoreMoney/entry/src/test/DateUtil.test.ets` 与 `PeriodResolver.test.ets` 的全部断言；固定 `Clock` 与 `TimeZone`，避免机器时区影响。

**Pinyin 决策（D2）：**

- 排序：`Collator.getInstance(Locale.CHINA)`；
- 转换：API 29+ `android.icu.text.Transliterator.getInstance("Han-Latin")`；
- API 26–28：内置常用字首字母表兜底；无法转换时返回小写原文；
- 测试至少覆盖 `餐饮→canyin`、`出行→chuxing`、英文/数字/空串；
- 如果产品要求 26–28 完整拼音，T04.4 追加 GB2312 常用字表，不引第三方库。

**验收：**

```bash
./gradlew :app:testDebugUnitTest
```

---

### T05 · 基础组件与全局状态

**目标：** 建立可复用 UI 基础层与会话级全局状态，后续页面只做组合。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T05.1 | `AppUiState`：`hideAmount`、`snackbar`；Compose `mutableStateOf`；进程重建后 `hideAmount=false` | 单测 + 跨页一致 |
| T05.2 | `SettingsService`：SharedPreferences + `StateFlow`；键：`default_book_id`、`week_start`、`last_backup_at`、`last_backup_name`、`screen_privacy` | 重启后保留 |
| T05.3 | `MoneyText`、`EyeButton`、`AmountBar`、`RingProgress`：支持 `hidden`/`locked`，金额统一 `tnum` | 隐藏/打码测试 |
| T05.4 | 基础组件 A：`AppCard`（已有）、`PrimaryButton`、`SecondaryButton`、`IconButton`、`Badge`、`SectionHeader`、`EmptyState`、`SegmentedControl` | Gallery 可预览 |
| T05.5 | 基础组件 B：`ListRow`、`ToggleRow`、`SnackbarHost`（带撤销 action）、`ConfirmDialog`、`SkeletonList`、`ErrorRetry` | 撤销/重试可用 |
| T05.6 | 组件 Gallery：`src/debug` 下的 `GalleryActivity` 或 Compose Preview 集合；不进入正式导航 | debug 包可打开 |
| T05.7 | 组件测试：48dp 点击区、字体 1.3×、浅/深色、Snackbar 撤销 | `connectedDebugAndroidTest` |

**金额组件的关键行为：**

- `MoneyText(cents, hidden, signed, style)`：
  - `hidden=true` → `¥••••`；
  - `signed=true` 且支出 → 前缀 `−`；
  - 负数用 U+2212；
  - 一律 `tabularNumbers()`。
- `AmountBar(progress, hidden)`：隐藏时轨道保留、填充不绘制；不通过长度反推金额。
- `RingProgress(progress, hidden)`：同理。

**Snackbar 撤销接口：**

```kotlin
data class SnackAction(val label: String, val onAction: () -> Unit)

fun showSnack(message: String, action: SnackAction? = null, durationMs: Long = 5000)
```

**验收：**

```bash
./gradlew :app:testDebugUnitTest
./gradlew :app:connectedDebugAndroidTest
```

---

### T06 · 账本首页

**目标：** 一级 Tab“账本”：Hero、账本/月份切换、月度汇总、按日分组流水、FAB。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T06.1 | `LedgerViewModel` + `LedgerUiState`：账本、当前账本、月份、流水、汇总、预算；`StateFlow` | 切换账本/月份自动刷新 |
| T06.2 | `HomeHero`：渐变 `heroA→heroB→heroC`、月份 32sp、左右箭头、账本 chips、眼睛按钮；状态栏白色 | 与 `01-home-light.png` 对齐 |
| T06.3 | `SummaryCard`：本月支出 42sp、预算进度、三列（预算/每天可用/剩余）、无预算态、隐藏态 | 与 `01/02` 对齐 |
| T06.4 | 流水列表：`LazyColumn` + `stickyHeader` 日期分组、`TxnRow`、空/加载/错误态 | 滚动流畅、分组正确 |
| T06.5 | `TxnDetailSheet`（只读）+ 编辑入口；FAB → `AddTxn(bookId, dayKey)` | 点击流水可查看详情 |
| T06.6 | 测试与截图：浅/深、隐藏金额、空数据 | 截图归档 |

**口径：**

- 选中单账本：该账本本月流水；选中“全部”：全部未归档账本。
- 预算：单账本用该账本预算；“全部”用所有“已设预算、未归档”账本之和。
- 每天可用 = `max(0, (budget - spent) / 本月剩余天数)`，含今天。

**测试重点：**

- 月份切换后日期分组与合计正确；
- 金额隐藏后进度条填充消失；
- 无预算显示“未设置预算”与“去设置”；
- 空数据不显示空白页。

---

### T07 · 记一笔

**目标：** 新增/编辑支出：分类、账本、日期、金额计算器、备注、保存、删除撤销。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T07.1 | `AddTxn` 路由参数、`AddTxnViewModel`、表单校验、未保存返回确认 | 返回有确认 |
| T07.2 | 金额行 + `CalcKeypad`：复用 T04 引擎，预览文案、非法态、长按退格清空 | 17 个表达式用例在 UI 可用 |
| T07.3 | `CategoryPicker`：常用最多 8 个 + 分组网格、选中态、图标 52dp | 与 `03-add-light.png` 对齐 |
| T07.4 | `SelectorRow`：账本/日期；日期禁止未来 | 选择器行为正确 |
| T07.5 | 备注展开、保存、编辑回填、删除（软删 + 撤销）；保存后返回首页并自动切到该笔流水的账本与月份 | 新增后即使首页原在别的账本/月份，也能立即看到该笔记录 |
| T07.6 | 测试与截图：金额、备注、深色 | 截图归档 |

**关键行为：**

- 金额存储为 `Long` 分；保存前调用 `CalcEngine.evaluate()`，失败提示。
- 日期用 `LocalDate` + 主题化的 `AppDatePickerDialog`（Material3，`ui/components/base/DatePickers.kt`），`end = 今天`。
- 账本默认优先级：路由参数 > `SettingsService.defaultBookId` > 数据库默认账本。
- 编辑模式：回填账本/分类/日期/金额/备注；保存走 `update`。
- 删除：`softDelete` + Snackbar 撤销（T23 提供通用 Snackbar）。

**测试重点：**

- 新增后首页/预算/图表数据刷新（Room Flow 自动触发）；
- 非法金额不能保存；
- 编辑后金额与分类正确；
- 返回未保存有确认。

---

### T08 · 账本管理

**目标：** 账本 CRUD、默认、归档、预算入口；不包含私密账本。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T08.1 | `BookManageScreen` + `BookCard`：封面、名称、预算、默认徽标 | 与 `16-books-light.png` 对齐 |
| T08.2 | `BookEditSheet`：名称、图标（6 个封面）、颜色（种子色板）、默认开关 | 新建/编辑即时生效 |
| T08.3 | 操作：设默认、归档、删除（有流水拒绝）、预算编辑（复用 T12 `BudgetEditDialog`） | 默认唯一、归档不出现在选择器 |
| T08.4 | 测试：默认账本、归档、删除约束、排序持久化 | instrumentation |

**规则：**

- 默认账本全局唯一；删除默认账本前必须指定新默认。
- 有流水（含软删）的账本只能归档，不能删除。
- 归档账本不出现在首页、预算、记账选择器。
- 排序字段 `sort` 持久化；v1 可用拖动或上下移动按钮实现。
- 不出现密码、私密开关、锁图标或解锁入口。

---

### T09 · 成员管理（2026-11-24 已删除）

**状态：** ❌ 已删除。Android 独立版不再有成员概念；Room v1→v2 删除 `member` 表与 `txn.member_id`，保留流水；旧备份/CSV 的成员字段读取时忽略。以下内容仅保留为历史记录。

**原目标：** 成员 CRUD、默认、归档、颜色/首字母。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T09.1 | `MemberManageScreen` + 列表（首字圆点、名称、默认徽标） | 与设计一致 |
| T09.2 | `MemberEditSheet`：名称、首字、颜色 | 新增/编辑 |
| T09.3 | 设默认、归档、删除引用检查 | 被引用只能归档 |
| T09.4 | 测试：默认唯一、排序稳定、归档不出现在选择器 | instrumentation |

---

### T10 · 分类管理

**目标：** 分组/分类 CRUD、图标/颜色、常用分类、拼音排序与搜索。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T10.1 | `CategoryManageScreen` + `GroupCard` / `FrequentCard` | 分组与常用展示 |
| T10.2 | `CategoryEditSheet`：名称、图标、颜色、分组 | 新增/编辑 |
| T10.3 | `GroupEditSheet`：新建/重命名/删除（空分组） | 分组管理 |
| T10.4 | 常用分类：`listFrequent(8, now-30d)`；组内按拼音排序；搜索 | 常用排序稳定 |
| T10.5 | 引用检查 + 测试 | 被引用只能归档 |

**常用分类口径：**

- 先按近 30 天使用次数降序；
- 次数相同按 `pinyin ASC, sort ASC`；
- 最多 8 个；
- 归档分类不参与新增选择。

---

### T11 · 统计聚合服务

**目标：** 提供分类占比、趋势、日历热力所需的聚合；纯服务层，不依赖 UI。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T11.1 | `StatsTypes.kt` + `PeriodResolver`（T04.3 可复用） | 类型与周期测试 |
| T11.2 | `StatsDao` / `TxnDao` 聚合查询：按分类、按日、按账本、按桶 | SQL 与手工结果一致 |
| T11.3 | `StatsService`：`byCategory`、`byDay`、`byBook`、`buckets`、`dailyStats` | 空结果返回 0/空数组 |
| T11.4 | 空数据与边界：空库、单日、跨月区间返回 0/空数组；`byDay` 缺日补 0 | 不抛异常 |
| T11.5 | 测试：2 月 28/29 天、跨年区间、多账本 | 单测 + instrumentation |

**规则：**

- 全部使用本地时区 `dayKey`；
- 周起始日由调用方传入（`SettingsService.weekStart`），服务不读设置；
- 金额整数分，禁止 `AVG` 浮点返回；
- `byDay` 缺日补 0，长度等于范围天数；
- 分类图例前 5 + 其他，其他金额等于剩余之和。

---

### T12 · 预算页

**目标：** 年/季/月预算、账本预算、进度、剩余、每天可用；预算设置一次后自动重复，页面不再提供月份切换。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T12.1 | `BudgetService` + `BudgetCycleUtil`：每账本单周期、周期区间、月折算、合计、已用、剩余、每天可用、超支 | 手工计算一致 |
| T12.2 | `BudgetScreen`：去掉顶部合计摘要与月份切换；单张预算卡左右切换已设预算账本 | 无月份切换、无跨账本合计；默认账本有预算时优先展示 |
| T12.3 | `MainBudgetCard` + `RingProgress`（116dp，stroke 11）；卡片标注年度/季度/月度预算 | 环百分比正确 |
| T12.4 | `BudgetBookRow`、`UnsetBudgetCard`、空状态；每行展示账本自身周期 | 无预算/未设置态 |
| T12.5 | `BudgetEditDialog`：选择年/季/月周期 + 金额，设置/清空；切换周期即时折算 | 写入后即时刷新 |
| T12.6 | 隐藏金额与迁移测试 | 进度/数字一起隐藏；v2 按月预算正确迁移 |

**口径（2026-11-28 起）：**

- 一个账本只能设置年、季、月其中一个周期，不能同时设置多个；
- 设置后自动按周期重复，切换月份/季度/年份无需重设；
- 各账本按自身周期统计当前周期已用与剩余（年度看本年、季度看本季、月度看本月）；
- 不做跨账本合并计算，页面不显示“预算合计 / 已用 / 剩余”三列摘要；
- 多个账本已设预算时，预算卡支持左右切换；默认账本有预算则优先展示，否则展示第一个已设预算账本；
- 未设预算的账本单独列入“待设置预算”；
- 每天可用 = `max(0, 剩余) / 当前周期剩余天数`（含今天）；
- 超支：剩余为负、环变红；
- 隐藏金额：金额、进度填充、百分比一起隐藏，轨道保留。

---

### T13 · 私密账本（已取消）

**状态：** ❌ 已取消。Android v1 只支持普通账本。

**不再交付：**

- `PrivateBookService`、`CryptoUtil`、`UnlockSheet`、`PasswordSetupSheet`
- PBKDF2 / 生物识别 / Keystore / 会话 TTL / 失败锁定
- 私密账本的金额打码/统计排除、`PRIVATE` 加密备份
- `androidx.biometric` 依赖

**Schema 影响：**

- `book` 表删除 `is_private`、`pwd_hash`、`pwd_salt`、`pwd_iter`
- 其余表不变

**备份影响：**

- Android 不生成 `PRIVATE` 行
- 恢复旧备份时跳过 `is_private=1` 的账本与 `PRIVATE` 行，并在预览中提示
- 不得把私密账本当作普通账本导入

**相关任务调整：** T08 删除私密入口；T14 只保留全局金额隐藏；T18/T19 删除锁定排除；T21 删除加密/解密；T24 删除私密测试。

---

### T14 · 金额隐藏

**目标：** 一个全局开关覆盖所有金额、进度、图表、日历热力。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T14.1 | `EyeButton` 接入首页/预算/图表/搜索/账本管理/数据页 | 一个开关全站生效 |
| T14.2 | `MoneyText` / `AmountBar` / `RingProgress` 的 `hidden` 透传 | 数字与进度一起隐藏 |
| T14.3 | 图表/日历：环形图中心、图例金额、趋势轴、热力格金额 | 不通过颜色/长度反推 |
| T14.4 | 测试：跨页一致、冷启动恢复显示 | instrumentation |

**注意：**

- `hideAmount` 不持久化，冷启动默认显示；
- 隐藏时金额占位 `¥••••`，不要用“0”或空白；
- 进度条轨道保留、填充不绘制；
- 日历热力颜色不随金额变化（隐藏时统一中性色）。

---

### T15 · 环形图（分类占比）

**目标：** Compose Canvas 绘制环形图、图例、选中态、空数据、隐藏金额。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T15.1 | `ChartCanvas`：尺寸、像素比、重绘、空态 | 任意尺寸不模糊 |
| T15.2 | `DonutChart`：起始 -90°、内半径 0.62、选中偏移 4dp、命中检测 | 点击扇区正确 |
| T15.3 | `DonutLabels` / `ChartLegend`：中心总额、选中分类、图例前 5 + 其他 | 与设计一致 |
| T15.4 | `ChartsScreen` 容器 + 分段控件（分类/趋势/日历）+ 周期 chips | 三子页切换 |
| T15.5 | 测试与截图：浅/深、空数据、隐藏金额、窄屏 | 不溢出 |

**规则：**

- 关闭动画时也要正确绘制；
- 分类色来自 T01.3 的 5 个槽位，超出归“其他”；
- 隐藏金额时中心/图例金额打码，扇区比例保留（设计允许）；
- 不引入第三方图表库。

---

### T16 · 趋势图

**目标：** 月度支出趋势折线、最高 3 天、自定义区间。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T16.1 | 趋势数据：按 `PeriodResolver.bucketGranularity` 聚合 | 桶边界正确 |
| T16.2 | `TrendChart`：折线/面积、点、命中、坐标轴 | 与设计一致 |
| T16.3 | `TopDaysList` + `CustomRangeDialog` | 前 3 天正确 |
| T16.4 | 测试与截图：空数据、隐藏金额、跨年区间 | 不溢出 |

---

### T17 · 日历热力

**目标：** 月历网格、每日支出热力、选中日明细。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T17.1 | `HeatCalendar`：7 列网格、周起始日、5 档热力 | 与设计一致 |
| T17.2 | 选中日 + `DayDetailList` | 单日明细正确 |
| T17.3 | 月份切换、空月份 | 切换刷新 |
| T17.4 | 测试与截图：隐藏金额、深色、窄屏 | 不溢出 |

---

### T18 · 搜索

**目标：** 按备注、分类、金额搜索，支持拼音。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T18.1 | `TxnDao.search(keyword, limit)`：备注/分类/金额 | SQL 测试 |
| T18.2 | `SearchScreen`：搜索框、结果按日分组、清空、空结果 | 交互正确 |
| T18.3 | 拼音键匹配；普通账本全部可搜索 | 首字母命中 |
| T18.4 | 测试：中文/拼音/金额/空结果 | instrumentation |

---

### T19 · CSV 导出

**目标：** 按筛选导出，SAF 选择保存位置。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T19.1 | `CsvExportService`：查询 → `CsvExportRow` → `CsvFormat.build` | 内容正确 |
| T19.2 | SAF `CreateDocument("text/csv")` + 写 UTF-8 BOM/CRLF | 取消不报错 |
| T19.3 | `ExportFilterSheet`：日期范围、账本 | 筛选生效 |
| T19.4 | 测试：导出→导入往返一致 | 列顺序/金额单位一致 |

**格式固定（2026-11-24 起 9 列）：**

```csv
date,time,type,book,group,category,amount,note,id
2026-11-09,12:30,expense,日常账本,餐饮,餐饮,32.00,午餐,uuid
```

- UTF-8 BOM、CRLF；
- 金额两位小数、无千分位/货币符号；
- 公式注入：`= + - @` 开头加 `'`；
- 文件名 `MoreMoney_YYYYMMDD_HHmm.csv`；
- 无锁定/私密过滤，导出范围只由筛选条件决定。

---

### T20 · CSV 导入

**目标：** 选择文件、预览、校验、去重、事务导入。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T20.1 | 复用 `CsvParser`；读取时剥离 BOM | 单测 |
| T20.2 | `CsvImportService.preview`：逐行校验、自动创建项、重复 ID、错误行号 | 预览统计正确 |
| T20.3 | SAF `OpenDocument` + 5MB/20000 行限制 | 超限拒绝 |
| T20.4 | `ImportPreviewSheet` + 确认导入事务 + 回滚 | 任一错误整体不写 |
| T20.5 | 测试：往返、引号/换行、重复、错误行 | instrumentation |

**规则：**

- 表头必须完全一致、顺序固定；
- 有错误时禁止导入；
- 同一文件重复 ID 保留第一条；
- 库中已存在 ID 计为重复跳过；
- 自动创建账本/分组/分类；
- 写入包裹在事务中，失败回滚；
- 导入后刷新首页/分类；
- 旧版 10 列 CSV（含 member）仍可导入，成员列忽略。

---

### T21 · 备份与恢复

**目标：** 导出/导入 `MOREMONEY_BACKUP` schemaVersion=3，只处理普通账本；支持覆盖恢复与回滚。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T21.1 | 复用 `BackupFormat`；确认 `format=1`、`schemaVersion=3`、校验和；兼容读取 v1/v2 旧备份；不解析/不生成 `PRIVATE` 加密内容 | 单测 |
| T21.2 | `BackupService.export`：查询全表 → Base64/Tab 行 → 校验和 → SAF 保存；`BOOK` 第 5–8 列写 `0`/空/空/`10000` 占位 | 文件可由本项目恢复且计数一致 |
| T21.3 | `BackupService.previewRestore`：校验头/版本/校验和/计数；统计 `is_private=1` 的账本与 `PRIVATE` 行数量 | 损坏拒绝，跳过项可见 |
| T21.4 | 恢复确认 + 事务清空/写入 + 失败回滚；跳过私密账本、`PRIVATE` 行及其引用的流水/预算；缺默认账本时取 `sort` 最小者 | 原数据保留，跳过有提示 |
| T21.5 | 测试：普通导出→恢复→数量/金额一致；混合备份跳过私密账本；篡改校验和拒绝 | instrumentation |

**备份包格式（Android 独立版 schemaVersion=3）：**

- 所有字符串字段 Base64（UTF-8）；数字十进制；
- 不再生成 `MEMBER` 行；`TXN` 行 9 列；`BOOK` 行仍为 13 列（第 5–8 列 `0`/空/空/`10000`）；不生成 `PRIVATE`；
- `BUDGET` 行 5 列：`id`、`book_id`、`cycle`（`YEAR`/`QUARTER`/`MONTH`）、`amount_cents`、`updated_at`；每个账本最多一行；
- 兼容读取 `schemaVersion=1/2`：忽略 `MEMBER` 行与 TXN 的 member 列；旧 BUDGET 第 3 列按月份处理为 `MONTH`，同一账本多条时保留 `updated_at` 最新一条；
- `checksum = SHA-256([BODY] 与 [END] 之间的文本, UTF-8)`，小写 hex；校验覆盖整个 body，包括被跳过的私密行；
- 恢复时清空 `book/category_group/category/txn/budget`，不要清 `app_meta`；
- `BOOK` 行 `is_private=1` 的账本跳过；`PRIVATE` 行跳过；引用被跳过账本的 `TXN` / `BUDGET` 行也跳过；
- 缺少默认账本时把 `sort` 最小者设为默认；
- 未知行类型忽略并告警。

---

### T22 · 设置与数据页

**目标：** 设置项、备份状态、数据统计、关于信息。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T22.1 | `SettingsScreen`：备份状态卡、数据/通用分组、周起始日、外观切换（跟随系统/浅色/深色）、关于 | 与设计一致 |
| T22.2 | `DataBackupScreen`：备份状态、立即备份、恢复、CSV 导入导出入口 | 入口可用 |
| T22.3 | 数据统计卡：账本/分类/流水数量与数据库一致 | 查询正确 |
| T22.4 | 测试：设置持久化、关于版本号、空备份状态 | instrumentation |

**设置项：**

- 周起始日：周一/周日，写入 `SettingsService.weekStart`；
- 外观：跟随系统/浅色/深色，默认跟随系统，写入 `SettingsService.themeMode`；
- 版本号：`BuildConfig.VERSION_NAME` 或 `PackageManager`；
- 隐私说明：本地文案，说明完全离线、无网络权限、无私密账本。

---

### T23 · 删除撤销与状态反馈

**目标：** 删除流水后的 Snackbar 撤销、加载/错误/空状态统一。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T23.1 | `DeleteService`：软删除、撤销、30 天清理 | 单测 |
| T23.2 | `SnackbarHost`：5 秒撤销、连续删除不串状态 | UI 测试 |
| T23.3 | `ConfirmDialog`、`SkeletonList`、`ErrorRetry`、`EmptyState` 统一 | 各页复用 |
| T23.4 | 流水行长按菜单：删除/取消 | 400ms 长按 |
| T23.5 | 测试：删除→撤销→恢复；连续删除；过期清理 | instrumentation |

**规则：**

- 删除不弹二次确认，靠 5 秒撤销；
- 软删后列表立即移除、合计同步更新；
- 撤销后恢复并刷新；
- `purgeExpired` 在应用启动时触发一次，失败不阻断。

---

### T24 · 测试与质量门禁

**目标：** 建立可持续的质量基线。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T24.1 | JVM 单测：Money/Expression/Date/Period/Csv/Backup/Pinyin 全覆盖 | `testDebugUnitTest` 全绿 |
| T24.2 | Instrumentation：DAO、Tab、记账、撤销、隐藏金额、备份跳过私密账本 | `connectedDebugAndroidTest` 全绿 |
| T24.3 | `lintDebug` 无 error；可选 Jacoco；红线检查脚本 | 质量门禁命令通过 |
| T24.4 | 可选 CI（GitHub Actions / 本地脚本）；无网络依赖 | 一条命令复现 |

**门禁命令：**

```bash
./gradlew :app:testDebugUnitTest :app:lintDebug :app:compileDebugAndroidTestKotlin
./gradlew :app:connectedDebugAndroidTest
```

---

### T25 · 深色/窄屏验收

**目标：** 按设计规范逐页走查浅色、深色、360dp、字体放大、横屏/折叠屏。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T25.1 | 360dp 模拟器/设备逐页走查 | 无溢出/截断 |
| T25.2 | 系统字体 1.3×、深色、横屏/折叠屏 | 关键数字不截断 |
| T25.3 | `T25-report.md`：设备、版本、逐页结论、问题清单与修复 | 截图归档 |

**验收口径：**

- 10sp 辅助文字不再缩小；
- 金额/统计数字不截断；
- Tab 栏、FAB、底部弹层不被系统手势遮挡；
- 深色模式下图表、热力、Hero 对比度可读。

---

### T26 · 发布准备

**目标：** 可安装的正式包。

| 子任务 | 内容与产出 | 验收 |
|---|---|---|
| T26.1 | 签名配置（不入库）、R8/ProGuard 规则、`proguard-rules.pro` | `assembleRelease` 成功 |
| T26.2 | 备份规则/隐私说明：`allowBackup=false` 复核；无 `INTERNET` 权限 | 权限清单不含 `INTERNET` |
| T26.3 | 版本号策略、商店素材、隐私政策、Data Safety 文案 | 文档齐全 |
| T26.4 | Release 包安装/升级/降级测试；崩溃与 R8 检查 | 真机/模拟器 |

**注意：**

- 国内分发需要软件著作权与 App 备案；Google Play 需要 Data Safety 表单；
- v1 完全离线，隐私说明明确“无网络权限、数据仅存本机、无私密账本”；
- 备份不生成 `PRIVATE` 段；恢复旧备份时跳过私密账本并提示。

---

## 5. 里程碑与排期

| 里程碑 | 任务 | 估算 |
|---|---|---:|
| M0 工程基线 | T00、T01、T02 | 2.5 人日 |
| M1 数据与基础 | T03、T04、T05 | 6.5 人日 |
| M2 记账闭环 | T06、T07、T08、T09、T10、T11、T12 | 12.5 人日 |
| M3 显示与图表 | T14、T15、T16、T17 | 6.0 人日 |
| M4 数据与设置 | T18、T19、T20、T21、T22、T23 | 7.0 人日 |
| M5 质量与发布 | T24、T25、T26 | 4.0 人日 |
| **合计** | | **38.5 人日** |

### 5.1 关键路径

```text
T00 → T03 → T05 → T06 → T07 → T23 → T24 → T26
```

T04、T09–T12、T15–T22 可在关键路径之外并行；T08 不再依赖 T13。T21 的备份恢复可与 T18–T20 并行，但必须在 T24 前完成。

### 5.2 并行轨道

| 轨道 | 任务 | 说明 |
|---|---|---|
| A UI 基础 | T00 → T01 → T02 → T05 | 修改主题/MainScreen 时避免与他人并行 |
| B 数据/逻辑 | T00 → T03 → T04 → T11 | 纯 JVM 与 Room 可并行 |
| C 记账 UI | T06、T07、T09、T10、T12 | 依赖 A/B |
| D 显示/图表 | T14、T15–T17 | 金额隐藏与图表，无账本锁定逻辑 |
| E 数据交换 | T18–T23 | 依赖 B，T19 先于 T20 |
| F 质量/发布 | T24–T26 | 贯穿 M2–M4，最后收口 |

---

## 6. 决策与风险

| 编号 | 事项 | 结论 / 建议 | 影响 |
|---|---|---|---|
| D1 | Room + KSP 兼容性 | ✅ 已验证：Room 2.8.5 + KSP 2.3.14 + Kotlin 2.4.21 + AGP 9.5.2 | T03 可按计划 |
| D2 | API 26–28 拼音 | 建议 Collator 排序 + API29+ 转写 + 低版本首字母/中文降级；如不接受降级，T04.4 生成常用字表 | T04.4、T10.4、T18.3 |
| D3 | 私密账本 | ❌ 已取消。Android 只支持普通账本；`book` 表删除 `is_private`/`pwd_*`；备份不生成 `PRIVATE`，恢复旧备份时跳过私密账本并提示 | T03、T08、T13、T14、T18、T19、T21、T22、T24 |
| D4 | 设置持久化 | 建议 SharedPreferences + StateFlow，不新增依赖 | T05.2、T22 |
| D5 | 系统自动备份 | 建议 `allowBackup=false`，避免数据库进入系统云备份；T26 复核 | T00.1、T26.2 |
| D6 | Git 初始化 | 当前不是 Git 仓库；是否 `git init` 由你决定 | T00.6、所有提交 |
| D7 | 部分唯一索引 | Room `@Index` 不支持；用 `Callback.onCreate` 执行 SQL，并在测试中断言 | T03.3 |
| D8 | Build-Tools 版本 | 保持 36.0.0；compileSdk 37.2 已可构建 | 无需操作 |
| R1 | 磁盘空间 | 剩余约 30 GB；Gradle/Room/模拟器镜像占用大 | 监控 |
| R2 | 真机缺口 | 无物理设备；SAF、系统字体和厂商行为需模拟器 + 最后真机补验 | T25/T26 |
| R3 | 拼音一致性 | API 26–28 与 29+ 的汉字转拉丁能力不同 | 文档写明降级 |
| R4 | 备份格式自洽 | 以本项目 `BackupFormat`/`BackupService` 测试为合同；不生成 `MEMBER`/`PRIVATE`，恢复旧 v1 时忽略成员并跳过私密账本 | T04.7、T21 |
| R7 | Schema 以 v2 为准 | `book` 表无 4 个私密列；无 `member` 表/`member_id`；T03 测试与迁移测试显式断言 | T03、T21 |
| R5 | Navigation 3 稳定性 | 1.0.1，API 与旧 navigation-compose 不同，禁止混用 | T02 |
| R6 | 金额精度 | 任何 UI/导入/统计/备份不得出现浮点金额 | 全局 |

---

## 7. 首批执行清单（T00）

按顺序做，每项完成即可提交（若已 `git init`）：

- [ ] T00.1 写 `AndroidManifest.xml` + `testInstrumentationRunner` + 禁止自动备份
- [ ] T00.2 写 `strings.xml`，创建 4 个占位 Screen
- [ ] T00.3 写浅/深色 themes 与 colors，配置启动窗口背景
- [ ] T00.4 生成 4 个 Tab 图标与自适应图标
- [ ] T00.5 加 `SmokeTest`、`MainScreenSmokeTest`、`proguard-rules.pro`
- [ ] T00.6 补 `.gitignore`
- [ ] 运行 `./gradlew :app:assembleDebug :app:lintDebug :app:compileDebugAndroidTestKotlin`
- [ ] 启动模拟器，`installDebug`，确认 4 个 Tab 可见
- [ ] 更新 README 状态，记录首张截图

T00 完成后，按 T01.1 → T01.2 → T01.3 → T01.4 → T01.5 → T01.6 顺序做主题收尾；T01.4（43 个图标）是 T01 里最重的一步，建议单独提交。

---

## 8. 历史任务文档对照

| Android | 历史参考 | 说明 |
|---|---|---|
| T00 | 无 | Android 专有：恢复构建基线 |
| T01 | `T01-theme-tokens.md` | 颜色/字号/间距/图标/启动图 |
| T02 | `T02-app-shell-navigation.md` | Navigation 3 替代系统路由表 |
| T03 | `T03-data-layer.md` | Room 替代 relationalStore；`book` 表省略私密列，其余表不变 |
| T04 | `T04-money-calculator.md` | 纯逻辑 1:1 移植 |
| T05 | `T05-common-ui-global-state.md` | Compose 组件与全局状态 |
| T06 | `T06-home-page.md` | 首页 |
| T07 | `T07-add-transaction.md` | 记一笔 |
| T08 | `T08-book-manage.md` | 账本管理 |
| T09 | `T09-member-manage.md` | ❌ 已删除；仅保留历史记录 |
| T10 | `T10-category-manage.md` | 分类管理 |
| T11 | `T11-stats-service.md` | 统计聚合 |
| T12 | `T12-budget-page.md` | 预算页 |
| T13 | `T13-private-books.md` | ❌ 已取消；Android 不做私密账本 |
| T14 | `T14-hide-amounts.md` | 金额隐藏 |
| T15 | `T15-chart-donut.md` | 环形图 |
| T16 | `T16-chart-trend.md` | 趋势图 |
| T17 | `T17-chart-calendar.md` | 日历热力 |
| T18 | `T18-search.md` | 搜索 |
| T19 | `T19-csv-export.md` | CSV 导出 |
| T20 | `T20-csv-import.md` | CSV 导入 |
| T21 | `T21-backup-restore.md` | 仅普通账本备份；不实现 `PRIVATE`，旧备份跳过私密账本 |
| T22 | `T22-settings-data-page.md` | 设置与数据页 |
| T23 | `T23-delete-undo-states.md` | 删除撤销 |
| T24 | `T24-tests-quality-gate.md` | 测试门禁 |
| T25 | `T25-dark-narrow-acceptance.md` | 深色/窄屏验收 |
| T26 | 无 | Android 发布准备 |

**使用方式：** 历史对照仅用于追溯设计来源；当前实现以本仓库代码、`app/schemas/.../2.json`、JVM 单测与 instrumentation 为准。
