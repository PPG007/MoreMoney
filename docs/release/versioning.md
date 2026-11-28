# 版本策略

## 1. 字段

- `versionCode`：整数，单调递增；每次对外发布 +1，不允许回退。
- `versionName`：语义化版本 `MAJOR.MINOR.PATCH`。
  - MAJOR：数据格式/备份兼容性破坏，或大版本重构；
  - MINOR：新增功能（如新的统计视图）；
  - PATCH：修复、文案、样式微调。
- `schemaVersion`（备份文件内）：当前为 `3`。只有 SQLite 表结构或备份正文格式变化才升级，并在 `docs/tasks/` 记录迁移与测试；当前兼容读取 v1/v2。

## 2. 当前基线

| 项 | 值 |
|---|---|
| versionCode | 3 |
| versionName | 0.0.3 |
| Room schema | 3 |
| 备份 format | 1 |
| 备份 schemaVersion | 3 |

> 真机测试期（2026-11-24 起）：`versionName` 保持 `0.0.x`，从 `0.0.1` 开始；每个测试包 `versionCode` +1（0.0.1=1、0.0.2=2、0.0.3=3……）。真机测试通过后再切正式版本 1.0.0，`versionCode` 继续单调递增。

## 3. 发布流程建议

1. 更新 `versionCode` / `versionName`，提交版本变更。
2. 跑质量门禁与 release 构建。
3. 用正式 keystore 签名，归档 APK/AAB 与 mapping 文件（`app/build/outputs/mapping/release/mapping.txt`）。
4. 在至少一台真机与一个模拟器上做安装/升级冒烟。
5. 商店后台填写 release notes；如涉及数据格式变化，附迁移说明。

## 4. 降级

Android 默认禁止 `versionCode` 回退安装（`INSTALL_FAILED_VERSION_DOWNGRADE`）。测试/回滚请使用相同或更高 `versionCode` 重新发布，不要要求用户卸载（卸载会清空本地数据）。
