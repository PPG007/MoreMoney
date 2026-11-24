# MoreMoney Android 依赖复核（2026-11-23）

- 复核对象：`docs/tasks/README.md` §1、§2
- 复核目的：确认当前机器是否具备继续迁移的条件，并验证 T03 数据层的关键工具链
- 结论：**工具链完整，无强制人工依赖；模拟器已就绪；Room + KSP 已实测通过。当前唯一阻塞是 T00 基线文件缺失。**
- **2026-11-23 范围变更：** Android v1 取消私密账本（T13）。生物识别、PBKDF2、AES-GCM 不再需要；`book` 表删除私密列；备份不生成 `PRIVATE`。本报告中的 Room/KSP、模拟器、网络、拼音结论仍然有效；§4.2 生物识别仅作历史记录。
- **2026-11-24 范围变更（历史说明）：** Android 改为独立应用，删除成员管理，不再要求与鸿蒙版互换数据；本报告中涉及鸿蒙资源/字段的段落仅作历史记录，当前数据契约以 `docs/tasks/README.md` §4 为准。

---

## 1. 复核方法

| 检查项 | 命令 / 方式 |
|---|---|
| Gradle / JVM | `./gradlew --version` |
| 当前构建 | `./gradlew :app:assembleDebug --console=plain` |
| SDK / 工具 | 读取 `$ANDROID_HOME` 目录与各组件 `source.properties` |
| 模拟器 | `emulator -list-avds`、`emulator-check accel`、`adb devices`、`adb shell getprop sys.boot_completed` |
| 网络 | `curl` 直连与经 `127.0.0.1:27017` 代理访问 Google Maven / Maven Central |
| Room + KSP | 在仓库外新建最小 spike 工程，使用与主工程相同的 AGP/Kotlin 版本编译 Room 实体 |
| 依赖版本 | 读取 Google Maven / Maven Central 的 `maven-metadata.xml` |

所有命令均在 2026-11-23 本机实际执行。Room spike 位于 `%TEMP%\mm-room-spike`，不属于仓库，可随时删除。

---

## 2. 工具链实测

### 2.1 已具备

| 组件 | 实测值 / 位置 | 证据 | 结论 |
|---|---|---|---|
| 操作系统 | Windows 11 Pro 10.0.26200 | `./gradlew --version` | ✅ |
| Android Studio | 2026.2.2，`D:\jetbrains\Android Studio` | `product-info.json`（AI-262.10968.63.2622.16975389） | ✅ |
| 运行时 JDK | JetBrains Runtime 25.0.4（`JAVA_HOME`） | `java -version`、Gradle Launcher JVM | ✅ |
| 系统 JDK | OpenJDK 25.0.2，`C:\Users\16582\jdk\25.0.2` | 目录存在 | ✅ 备用 |
| Gradle | 9.9.2（Wrapper） | `./gradlew --version` | ✅ |
| Gradle 内置 Kotlin | 2.4.21 | `./gradlew --version` | ✅ |
| JDK 17 编译工具链 | Adoptium 17.0.21（`~/.gradle/jdks`） | 目录与工具链缓存 | ✅ |
| AGP | 9.5.2 | `gradle/libs.versions.toml`，构建已进入任务执行 | ✅ |
| Compose BOM | 2026.11.01 | 同上 | ✅ |
| compileSdk | 37.2（`compileSdk=37` + `compileSdkMinor=2`） | `platforms/android-37.2/android.jar` 存在 | ✅ |
| SDK Platform | `android-37.0`、`android-37.2` | `platforms/` | ✅ |
| SDK Build-Tools | 36.0.0 | `build-tools/36.0.0` | ✅ 构建已使用 |
| Platform-Tools | 37.0.3 | `adb version` | ✅ |
| Emulator | 37.3.10 | `emulator -version` | ✅ |
| 系统镜像 | `android-37.0/google_apis_playstore/x86_64` | `system-images/` | ✅ |
| AVD | `Medium_Phone`，1080×2400，420dpi，API 37 | `emulator -list-avds`、AVD `config.ini` | ✅ |
| 硬件加速 | WHPX 可用 | `emulator-check accel` → `WHPX ... usable` | ✅ |
| 模拟器启动 | `emulator-5554`，`sys.boot_completed=1` | `adb devices` / `adb shell getprop` | ✅ |
| SDK Licenses | `android-sdk-license` 已接受 | `licenses/` | ✅ |
| 网络 | 直连与代理均返回 HTTP 200 | `curl` Google Maven / Maven Central | ✅ |
| 磁盘 | C 盘剩余约 30 GB | `df -h /c` | ⚠️ 够用，但需留意 |
| Git | 2.52.0 | `git --version` | ✅ 可选使用 |

### 2.2 仍不具备

| 项目 | 状态 | 影响 | 处理 |
|---|---|---|---|
| 已连接真机 | ❌ `adb devices` 无物理设备 | SAF 文件选择、厂商字体等真机行为无法 100% 覆盖 | 模拟器可完成绝大部分开发与 UI 测试；T25 建议最后插一台真机补验 |
| `cmdline-tools` | ❌ 未安装 | 不影响 Gradle 构建；Studio 自带的 SDK Manager 可管理 SDK | 不安装，除非需要命令行 `sdkmanager` |
| 仓库 Git 初始化 | ❌ 当前不是 Git 仓库 | 无法按子任务提交、回滚 | T00 只补 `.gitignore`；是否 `git init` 由你决定（见 WBS 决策 D6） |

### 2.3 需要你做的事

**强制项：无。** 现在可以直接开始 T00。

可选：

1. T25/T26 阶段用 USB 连接一台 Android 8.0（API 26）以上真机，开启开发者选项与 USB 调试；
2. 如果希望按子任务提交，确认是否执行 `git init`；
3. 保持 C 盘至少 10 GB 空闲（当前 30 GB）。

---

## 3. 当前构建状态

执行：

```bash
./gradlew :app:assembleDebug --console=plain
```

结果：`BUILD FAILED`，失败任务为 `:app:processDebugMainManifest`。

```text
Input file does not exist
  ... property 'mainManifest' specifies file
  '...\app\src\main\AndroidManifest.xml' which doesn't exist
```

这说明构建流程、AGP、SDK、依赖解析均已正常工作，只是 T00 骨架尚未补齐。按当前源码静态检查，T00 之后还会依次遇到：

| 缺口 | 影响 |
|---|---|
| `app/src/main/AndroidManifest.xml` | 当前构建唯一报错 |
| `ui/ledger/LedgerScreen.kt`、`ui/budget/BudgetScreen.kt`、`ui/charts/ChartsScreen.kt`、`ui/settings/SettingsScreen.kt` | `MainScreen.kt` 的 import 无法解析 |
| `res/values/strings.xml` | `R.string.tab_*`、`placeholder_*`、`color_*` 缺失 |
| `res/values/themes.xml`、`values-night/themes.xml` | Manifest 无主题可用 |
| `res/values/colors.xml`、`values-night/colors.xml` | 启动窗口背景无资源 |
| `res/drawable/ic_tab_books|budget|charts|settings.xml` | `MainScreen.kt` 的 `R.drawable` 缺失 |
| `res/drawable/ic_launcher_background.xml`、`ic_launcher_foreground.xml` | `mipmap-anydpi-v26/ic_launcher.xml` 已引用但文件不存在 |
| `app/src/androidTest` / `app/src/test` 下的测试文件 | 目录存在但为空；`testInstrumentationRunner` 也未配置 |
| `app/proguard-rules.pro` | release 构建引用但文件不存在 |
| `.gitignore` 补全 | 当前缺 `.kotlin/`、`**/build/`、`*.hprof`、完整 `.idea/` 等 |
| `gradle/libs.versions.toml` 数据层依赖 | T03 需要新增 Room / KSP / coroutines / room-testing |

---

## 4. 关键依赖验证

### 4.1 Room + KSP（T03 前置）

这是本次复核最重要的验证。主工程使用 **AGP 9.5.2 内置 Kotlin + Kotlin 2.4.21**，而 KSP 在 Maven 上的最新版本是 **2.3.14**，版本号看起来不匹配。为避免 T03 开工后才发现工具链不兼容，做了最小 spike：

| 项 | 值 |
|---|---|
| AGP | 9.5.2 |
| Kotlin | 2.4.21（AGP 内置） |
| KSP | 2.3.14 |
| Room | 2.8.5（runtime + compiler） |
| compileSdk | 37.2 |
| JDK 目标 | 17 |
| 结果 | ✅ `BUILD SUCCESSFUL`，`kspDebugKotlin`、`compileDebugKotlin`、`packageDebug` 全部通过 |
| Schema 导出 | ✅ `app/schemas/spike.SpikeDb/1.json` 生成 |
| APK | ✅ 约 2.0 MB |

说明：KSP 从 2.3.0 起改为独立版本号，不再与 Kotlin 版本前缀绑定；KSP2 可用于 Kotlin 2.4.x。实测已确认。

**结论：T03 继续使用 Room + KSP，无需回退到手写 SQLiteOpenHelper。**

实现时注意：

1. 根 `build.gradle.kts` 与 `app/build.gradle.kts` 都要应用 `com.google.devtools.ksp`；
2. 依赖为 `androidx.room:room-runtime`、`room-ktx`、`ksp("androidx.room:room-compiler")`；
3. 配置 `ksp { arg("room.schemaLocation", "$projectDir/schemas") }`，并把 `app/schemas/` 入库；
4. Room 的 `@Index` **不支持** `WHERE is_default = 1` 这种部分索引，需在 `RoomDatabase.Callback.onCreate` 中执行建索引 SQL（详见 WBS T03.3）；
5. `room-testing` 用于 instrumentation 测试，不引入 Robolectric。

### 4.2 生物识别（不适用）

**T13 已取消，Android v1 不实现私密账本，因此不需要 `androidx.biometric`、`BiometricPrompt` 或 Keystore 会话令牌。**

历史备注：曾验证 `androidx.biometric:1.4.0-rc01` 提供 Compose API（`rememberAuthenticationLauncher`），且不要求 `FragmentActivity`。该结论保留备查，但不会进入依赖清单或任务交付物。

### 4.3 拼音（T04/T10/T18 前置）

鸿蒙版使用系统 `i18n.Transliterator('Han-Latin')`。Android 上：

- `android.icu.text.Transliterator` **API 29 起才可用**，而本项目 minSdk 是 26；
- `java.text.Collator(Locale.CHINA)` 从 API 1 起可用，可直接做中文拼音排序；
- API 26–28 没有系统级汉字转拉丁能力。

建议方案：

1. 排序：统一用 `Collator.getInstance(Locale.CHINA)` 生成排序键，所有 API 级别行为一致；
2. 拼音键：API 29+ 用 `Transliterator.getInstance("Han-Latin")`；
3. API 26–28：用内置常用字首字母表兜底（只保证首字母搜索），或在该版本区间降级为中文子串搜索；
4. 如果要求 26–28 也具备完整拼音搜索，在 T04.4 生成 GB2312 常用字（约 6763 字）拼音表作为 assets，不引入第三方库。

**结论：T04.4 先按 1–3 实现并写清楚降级行为；T18 再决定是否补全字典。**

### 4.4 设置持久化（T05 前置）

未在 README 中固定。建议：

- 使用 `SharedPreferences` 封装 `SettingsService`，配合 `StateFlow` 暴露给 Compose；
- 不新增 DataStore 依赖；设置项数量少、无多进程需求。

**结论：T05 采用 SharedPreferences + StateFlow。**

### 4.5 图标与启动图（T01 前置）

- 鸿蒙版 `entry/src/main/resources/base/media/ic_*.svg` 共 **47 个**，均为 24×24、单色、`fill` 路径、`fill-rule="evenodd"`；Android v1 需要 **43 个**，私密账本相关的 `ic_lock`、`ic_unlock`、`ic_fingerprint`、`ic_face` 不转换；
- Android 不支持直接使用 SVG，需要转换为 VectorDrawable XML；
- 转换规则固定：`viewportWidth/Height=24`、`pathData` 原样、`fillColor="#FF000000"`、`fillType="evenOdd"`；
- 建议写 `tools/svg2vector.py` 批量转换，避免 47 个文件手抄；
- 启动图标可直接复用鸿蒙版 `AppScope/resources/base/media/background.png`（1024×1024）与 `foreground.png`（1024×1024），放到 Android 的自适应图标层；
- 启动窗口背景用主题 `windowBackground`（浅色 `#FAF8F7`，深色 `#121017`），Android 12+ 用 `values-v31/themes.xml` 的 `windowSplashScreenBackground`，不引入 `core-splashscreen`。

### 4.6 测试策略（T24 前置）

| 测试类型 | 运行位置 | 依赖 |
|---|---|---|
| 金额/表达式/日期/CSV/备份/统计周期 | JVM 单元测试 | JUnit 4、kotlinx-coroutines-test |
| Room DAO / 迁移 / 种子 | 模拟器 instrumentation | `room-testing`、`androidx.test:core`、`runner` |
| Compose UI（Tab、记账、撤销、隐藏金额） | 模拟器 instrumentation | Compose UI Test、`ui-test-manifest` |

必须在 `defaultConfig` 增加：

```kotlin
testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
```

否则 instrumentation 测试无法启动。

### 4.7 自动备份与隐私

v1 的备份完全由应用自己通过 SAF 完成。Android 系统自动备份可能把 `moremoney.db` 上传到云端，与“数据仅存本机”的隐私目标冲突。

建议：Manifest 设 `android:allowBackup="false"`，T26 再评估是否改为“排除数据库、仅备份设置”的规则。此决策记入 WBS D5。

---

## 5. 与 README 原记录的差异

| 项 | README 原记录 | 本次实测 | 处理 |
|---|---|---|---|
| 模拟器镜像 / AVD | ❌ 未安装 | ✅ 已安装 API 37.0 Play Store 镜像 + `Medium_Phone` AVD，且已成功启动 | 更新 README |
| 磁盘剩余 | 约 38 GB | 约 30 GB | 更新 README，注意空间 |
| 构建状态 | 中间态，构建失败 | 确认失败于缺失 `AndroidManifest.xml` | 更新 README |
| Room/KSP | 未验证 | ✅ 实测通过 | 记入技术决策，T03 可直接开工 |
| 私密账本 / 生物识别 | T13 私密账本 | ❌ 已取消；只保留普通账本 | 更新 README/WBS，移除 biometric/PBKDF2 |
| 备份格式 | 含 `PRIVATE` 段 | Android 不生成 `PRIVATE`；恢复旧备份跳过私密账本 | 更新 T21 与兼容红线 |
| 拼音 | 直接移植 | Android API 26–28 无系统转写，需要降级方案 | 记入风险与 T04.4 |
| 设置持久化 | 未指定 | 建议 SharedPreferences | 记入技术决策 |
| Git | `.gitignore` 待重写 | 工程尚未 `git init` | 由你决定 |

---

## 6. 复现命令

```bash
# 工具链
./gradlew --version

# 当前构建（T00 前会失败在 AndroidManifest）
./gradlew :app:assembleDebug --console=plain

# 模拟器
"$ANDROID_HOME/emulator/emulator" -list-avds
"$ANDROID_HOME/emulator/emulator-check" accel
"$ANDROID_HOME/platform-tools/adb" devices
"$ANDROID_HOME/platform-tools/adb" shell getprop sys.boot_completed

# 网络
curl -sS -o /dev/null -w "%{http_code}\n" \
  https://dl.google.com/dl/android/maven2/androidx/room/room-runtime/maven-metadata.xml

# Room spike（仓库外，可删除）
ls "$TEMP/mm-room-spike/app/schemas"
```

---

## 7. 最终结论

1. **T00 是唯一阻塞项**：补齐 Manifest、资源、4 个 Tab 页面、图标和测试骨架后，构建即可恢复。
2. **T03 的技术路线已经验证**：Room 2.8.5 + KSP 2.3.14 + Kotlin 2.4.21 + AGP 9.5.2 可用。
3. **模拟器足以支撑 M0–M2 的开发与 UI 测试**：`emulator-5554` 已启动，后续可直接 `installDebug`、`connectedDebugAndroidTest`。
4. **真机只在 T25/T26 的少数验收项上需要**：SAF 文件选择、系统字体、厂商行为。
5. **私密账本已取消**：不实现 T13、生物识别、PBKDF2/AES-GCM；`book` 表删除私密列，备份不生成 `PRIVATE`。
6. **建议下一步**：按 `WBS.md` 的 T00 清单执行，不要先动 T03/T06 等业务代码。
