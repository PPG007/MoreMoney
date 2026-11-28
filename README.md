# MoreMoney · 记账本

完全离线的 Android 个人预算记账应用。预算先行：首页直接展示本月支出、预算进度、剩余金额与每日可用额度；数据只保存在本机。

## 功能

- **预算**：按账本设置月度预算，超支标红；一个开关隐藏全部金额与进度。
- **记账**：分类、账本、日期、备注；内置支持 `+ − × ÷` 与运算优先级的数字键盘，保存即求值。
- **统计**：分类占比环形图、月度趋势、日历热力图，支持本月/上月/今年/全部/自定义区间。
- **搜索**：按备注、分类、金额搜索，支持拼音与首字母。
- **数据**：CSV 与 `.mmbk` 备份的导入导出（系统文件选择器）；无网络权限，无账号、无广告、无统计。

## 技术栈

Kotlin · Jetpack Compose (Material 3) · Room · Navigation 3 · Coroutines；JDK 17，minSdk 26，targetSdk 37。

## 构建

```bash
./gradlew :app:assembleDebug        # 调试包
./gradlew :app:testDebugUnitTest    # JVM 单元测试
./gradlew :app:assembleRelease      # 正式包（无 keystore.properties 时输出 unsigned APK）
```

签名与发布流程见 [docs/release/signing.md](docs/release/signing.md) 和 [docs/release/README.md](docs/release/README.md)。

## 文档

- 发布准备：[docs/release/README.md](docs/release/README.md)
- 任务与进度：[docs/tasks/README.md](docs/tasks/README.md)
- 隐私政策：[docs/release/privacy-policy.md](docs/release/privacy-policy.md)

## 状态

当前为 `0.0.5` 真机测试期版本（`versionCode` 5）；测试通过后发布 `1.0.0`。
