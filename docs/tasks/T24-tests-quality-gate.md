# T24 · 单元测试与质量门禁

> 状态：待开始 ｜ 优先级：P4 ｜ 依赖：全部 ｜ 预估：1.5 人日
> 设计依据：`设计规范.md` §10、本文档第 2.1 节红线

## 1. 目标

把关键纯逻辑用单测锁住，并建立提交前的静态检查与构建门禁，防止后续改动破坏金额、统计、CSV、备份等高风险模块。

## 2. 交付物

| 路径 | 内容 |
|---|---|
| `entry/src/test/MoneyUtil.test.ets` | 金额格式化/解析 |
| `entry/src/test/ExpressionEngine.test.ets` | 计算器全部用例 |
| `entry/src/test/DateUtil.test.ets` | 日期/月份/周起点 |
| `entry/src/test/PeriodResolver.test.ets` | 统计周期边界 |
| `entry/src/test/CsvFormat.test.ets` | CSV 转义/公式注入 |
| `entry/src/test/CsvParser.test.ets` | RFC4180 解析 |
| `entry/src/test/BackupFormat.test.ets` | 备份包往返/校验和 |
| `entry/src/test/PinyinUtil.test.ets` | 拼音排序键 |
| `entry/src/test/List.test.ets` | 汇总入口（Hypium 模板已有，更新用例列表） |
| `tools/quality-gate.ps1` | 静态红线检查脚本（PowerShell） |

## 3. 测试要求

### 3.1 覆盖范围

必须覆盖：

- 金额：0、1 分、¥1,286.40、负数展示、两位小数、超限。
- 计算器：T04 第 3.3 节全部 17 条。
- 日期：月末、闰年 2 月、跨年、周起点周一/周日、自定义范围。
- 统计周期：今天/本周/本月/本年/全部/自定义的 `startMs/endMs`。
- CSV：逗号、引号、换行、BOM、`=SUM()` 转义、空字段、CRLF。
- 备份：往返一致、篡改校验和失败、未知行忽略、版本不匹配拒绝。
- 拼音：中文、英文、数字、空串、转写失败回退。

不要求单测（依赖设备/Context）：

- DAO 的 SQL 执行、RDB 建表/迁移、文件选择器、生物识别、Canvas 绘制。这些通过 T25 的手工回归覆盖。

### 3.2 测试约束

- 单测文件放在 `entry/src/test/`，使用 Hypium（`describe/it/expect`）。
- 不 import `@kit.AbilityKit`、RDB、Preferences、UI 组件；纯函数才可测。
- 时间相关函数必须接受 `now: Date` 参数，禁止在函数内部 `new Date()`（便于注入固定时间）。
- 测试数据用常量，不读真实文件。

## 4. 质量门禁

提交前依次执行（本轮改动涉及的文件）：

```bash
devecocli check arkts <本轮所有新增/修改的 .ets 文件>
devecocli build
```

静态红线检查：实现 `tools/quality-gate.ps1`，执行 `powershell -ExecutionPolicy Bypass -File tools/quality-gate.ps1`，脚本逐项输出 `PASS/FAIL`，任一 FAIL 返回非零退出码。

| 检查 | 模式 | 期望 |
|---|---|---|
| 无 V1 装饰器 | `@State`、`@Prop`、`@Link`、`@Provide`、`@Consume`、`@Observed`（不含 `@ObservedV2`）、`@StorageLink`、`@StorageProp` | 无命中 |
| 无 `as` 断言 | `\bas\s+[A-Za-z_]` | 仅注释/字符串可命中 |
| 无 `any` / `unknown` | `:\s*(any|unknown)\b` | 无命中 |
| 无硬编码颜色 | `#[0-9A-Fa-f]{6}` | 仅 `Palette.ets`、`Theme.ets` |
| 唯一入口 | `@Entry` | 仅 `pages/Index.ets` |
| 无 navDestination | `\.navDestination\(` | 无命中 |
| 无第三方依赖 | 解析 `oh-package.json5` 的 `dependencies` | 为空 |

> 允许的例外必须写进代码注释并说明原因（例如 `Palette.ets` 内的图表色定义）。脚本用 `Get-ChildItem -Recurse -Filter *.ets` + `Select-String` 实现，不依赖 `rg`。

## 5. 手工回归清单（本任务执行一次）

| # | 场景 | 期望 |
|---|---|---|
| 1 | 冷启动 → 首页 | 无白屏，1 秒内出现骨架 |
| 2 | 记一笔 → 首页 | 数据正确、金额正确 |
| 3 | 切换月份/账本/成员 | 列表与摘要同步 |
| 4 | 设置预算 → 预算页 | 合计与百分比正确 |
| 5 | 三张图表切换周期 | 无崩溃、无空环 |
| 6 | 私密账本锁定/解锁 | 打码与排除正确 |
| 7 | 导出 CSV → Excel 打开 | 中文正常、金额正确 |
| 8 | 导入 CSV | 预览与错误行号正确 |
| 9 | 备份 → 清空 → 恢复 | 数据完全一致 |
| 10 | 深色模式全页面走查 | 无白块、无不可读文字 |

## 6. 验收标准

| 编号 | 验收项 | 验证方式 |
|---|---|---|
| AC-1 | 8 个测试文件全部存在，用例覆盖第 3.1 节 | 代码检查 |
| AC-2 | Local Unit Test 全部通过（0 failed） | DevEco Studio Test 面板 |
| AC-3 | `devecocli check arkts` 无错误 | 命令 |
| AC-4 | `devecocli build` 成功 | 命令 |
| AC-5 | `tools/quality-gate.ps1` 全部 PASS | 执行脚本 |
| AC-6 | 第 5 节手工回归 10 项全部通过 | 真机记录 |
| AC-7 | 无新增第三方依赖 | `oh-package.json5` |

## 7. 注意事项

- 不要为了让测试通过而修改业务预期值；先确认设计口径。
- 单测中禁止 `setTimeout` 等待，全部同步断言。
- 计算器/金额测试必须使用整数断言，不比较浮点。
- 若 Local Unit Test 无法在命令行运行，以 DevEco Studio 测试面板结果为准，并在任务完成记录中注明。
