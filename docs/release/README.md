# MoreMoney Android v1 发布准备（T26）

> 真机测试期构建使用 `0.0.x`（当前 0.0.3，versionCode 3）；本文件中的 1.0.0 是测试通过后的目标正式版本。

- 版本：1.0.0（versionCode 1）
- 日期：2026-11-24
- 平台：Android 8.0（API 26）及以上，compileSdk / targetSdk 37
- 分发范围：完全离线；无网络权限；不包含私密账本

## 1. 文档索引

| 文档 | 内容 |
|---|---|
| [signing.md](signing.md) | 发布签名、keystore 管理、apksigner 校验 |
| [versioning.md](versioning.md) | versionCode / versionName 策略与升级规则 |
| [privacy-policy.md](privacy-policy.md) | 隐私政策（中文正文 + English summary） |
| [data-safety.md](data-safety.md) | Google Play Data Safety 表单答案 |
| [store-listing.md](store-listing.md) | 商店名称、简介、截图与素材清单 |

## 2. 构建与检查命令

```bash
# 质量门禁
./gradlew :app:testDebugUnitTest :app:lintDebug :app:compileDebugAndroidTestKotlin
./gradlew :app:connectedDebugAndroidTest      # 需要模拟器/真机

# Release（无 keystore.properties 时输出 unsigned APK）
./gradlew :app:assembleRelease

# 有本机签名配置时输出 app-release.apk
./gradlew :app:assembleRelease
$ANDROID_HOME/build-tools/36.0.0/apksigner verify --print-certs \
  app/build/outputs/apk/release/app-release.apk
```

## 3. T26 验收记录

| 子任务 | 结论 | 证据 |
|---|---|---|
| T26.1 签名 / R8 / ProGuard | ✅（本地测试签名已实测；正式 keystore 由发布者生成） | `assembleRelease` 成功；`proguard-rules.pro` 覆盖 Room / Kotlin Serialization；无 `keystore.properties` 时降级为 unsigned APK |
| T26.2 备份规则 / 隐私 | ✅ | Manifest `allowBackup=false`；APK 权限清单无 `INTERNET`，仅 AndroidX 的 `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`；隐私说明见本目录 |
| T26.3 版本 / 商店 / 隐私 / Data Safety | ✅ | 版本策略、隐私政策、Data Safety、商店文案与截图清单已补齐 |
| T26.4 安装 / 升级 / 降级 / R8 检查 | ✅（模拟器） | 测试签名 release 安装、同签名 versionCode 1→2 覆盖升级保留数据、versionCode 2→1 被系统拒绝；启动无崩溃；详见 §4 |

## 4. Release 安装 / 升级 / 降级实测（Medium_Phone API 37）

测试使用**本地临时签名**（`~/.android/mm-release-test.jks`，不入库、非正式发布密钥）：

1. `versionCode=1`、`versionName=1.0.0` 构建（`app-release.apk`）并安装到已清空数据的模拟器，冷启动正常；新增一笔 ¥12.00。
2. 改为 `versionCode=2`、`versionName=1.0.1` 构建，`adb install -r` 覆盖安装成功；强制停止并重启后，¥12.00 仍在，证明升级保留数据。
3. 用 `versionCode=1` 的 APK 覆盖安装，系统返回：
   `INSTALL_FAILED_VERSION_DOWNGRADE: Downgrade detected: Update version code 1 is older than current 2`，符合 Android 预期。
4. R8 构建的 release 包可正常渲染 Compose、Room 与导航；未发现反射/序列化崩溃。
5. 验证结束后已把仓库版本恢复为 `versionCode=1 / versionName=1.0.0`，并删除 `keystore.properties`（避免误用测试密钥签名）；`~/.android/mm-release-test.jks` 仅作本次测试记录保留。

> 本轮签名实测在成员管理删除前的 1.0.0 基线上完成；之后只变更了 Room schema 与 UI，签名、R8 与升级机制未变。v1→v2 迁移由 `MigrationTest` 与模拟器上的旧版升级实测单独覆盖。
>
> 真实商店发布前，请用正式 keystore 重跑以上三步，并在至少一台真机上复核 SAF 与系统字体。

## 5. 已知发布前待办

- 生成并妥善保管正式 release keystore（不要提交到仓库或聊天中）。
- Google Play：填写 Data Safety、隐私政策 URL、内容分级；国内分发：软件著作权、App 备案。
- 真机复核：SAF 文件选择、厂商字体、横屏/折叠屏。
- 若要发布到应用商店，把 `docs/screenshots/` 中的截图按商店尺寸重新导出。
