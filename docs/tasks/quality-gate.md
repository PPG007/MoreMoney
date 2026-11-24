# 质量门禁（T24）

- 日期：2026-11-24
- 适用：`app` 模块

## 1. 一条命令

```bash
bash scripts/quality-gate.sh            # 编译 + 单测 + Lint + AndroidTest 编译 + 红线检查
bash scripts/quality-gate.sh --with-device   # 追加 connectedDebugAndroidTest
```

## 2. 分解命令

```bash
./gradlew :app:assembleDebug
./gradlew :app:testDebugUnitTest
./gradlew :app:lintDebug
./gradlew :app:compileDebugAndroidTestKotlin
./gradlew :app:connectedDebugAndroidTest   # 需要 emulator-5554 或真机
```

## 3. 当前结果

| 项 | 结果 |
|---|---|
| assembleDebug | ✅ |
| JVM 单测 | ✅ 58 个（Money / Expression / Date / Period / CSV / Backup / Pinyin / CompatVectors） |
| Lint | ✅ 0 error |
| AndroidTest 编译 | ✅ |
| Instrumentation | ✅ 19 个（Database / Migration / BackupService / MainScreen） |
| Release（R8） | ✅ 无签名配置时输出 unsigned APK |
| 红线脚本 | ✅ 组件无硬编码色、UI 无直接 SQL、无 INTERNET、book 无私密列、不生成 PRIVATE |

## 4. 红线脚本内容

`scripts/check-redlines.sh` 检查：

1. `Color(0x` 只允许出现在 `ui/theme/`；
2. `ui/` 与 `service/` 不出现 `execSQL` / `SupportSQLiteDatabase`；
3. Manifest 不申请 `INTERNET`；
4. `data/db/entity/` 不出现 `is_private` / `pwd_hash` / `pwd_salt` / `pwd_iter`；
5. 备份链路不生成 `PRIVATE` 段。

> 注：`scripts/check-redlines.sh` 里 SQL 检查排除了 `data/db/`，DAO 由 Room 生成，页面层不接触 SQL。

## 5. 未启用的可选项

- Jacoco 覆盖率：未接入；当前以 JUnit + instrumentation + Lint 作为门禁。
- 远程 CI：本地脚本已可复现；如接入 GitHub Actions，直接调用 `scripts/quality-gate.sh --with-device`（需配置模拟器 runner）。
