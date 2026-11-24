# 商店素材与文案

## 1. 基本信息

| 项 | 内容 |
|---|---|
| 应用名 | MoreMoney · 记账本 |
| 包名 | `com.github.ppg007.moremoney` |
| 类别 | 财务 / 效率 |
| 价格 | 免费（v1 无内购、无广告） |
| 支持语言 | 简体中文（界面）；英文商店文案见下 |
| 隐私政策 | 见 `privacy-policy.md`，发布时替换为公开 URL |
| 内容分级 | 所有人（不含用户生成内容、社交、广告） |

## 2. 短描述（≤ 80 字）

> 完全离线的预算记账本：预算看得见，流水记得快，数据只留在本机。

英文（≤ 80 字符）：

> An offline budget-first expense tracker. Your data never leaves your phone.

## 3. 完整描述（中文）

MoreMoney 是一款完全离线的个人支出记账工具。核心不是“记流水”，而是“让预算看得见”。

**预算先行**
- 首页先看本月支出、预算进度、剩余与每天可用；
- 按账本设置月度预算，未设置预算的账本不计入合计；
- 超支变红，剩余变绿；一个开关可隐藏所有金额、进度与图表数字。

**记账足够快**
- 分类放在上半屏，账本/日期与数字键盘在下半屏；
- 支持 + − × ÷ 与先乘除后加减，保存即求值；
- 长按流水即可删除，5 秒内可撤销。

**看得懂的数据**
- 分类占比环形图、月度趋势、日历热力；
- 支持本月/上月/今年/全部/自定义区间；
- 拼音与首字母搜索备注、分类和金额。

**数据在你手里**
- 无网络权限，完全离线，数据只保存在本机；
- CSV 与 `.mmbk` 备份通过系统文件选择器导出/导入；
- 系统云备份已关闭；卸载即删除本机数据；
- Android v1 不包含私密账本/密码/生物识别。

适合想要“简单、离线、看得见预算”的个人记账用户。

## 4. 完整描述（English）

MoreMoney is a fully offline, budget-first expense tracker for Android.

- See monthly spending, budget progress, remaining budget, and daily allowance at a glance.
- Add transactions fast with a built-in expression keypad, categories, books, dates, and notes.
- Understand spending with a donut chart, monthly trend, and calendar heatmap.
- Hide every amount and progress bar with one tap.
- Search notes, categories, and amounts with pinyin support.
- Export/import CSV and `.mmbk` backups through the system file picker.
- No INTERNET permission, no ads, no analytics, no accounts. Data stays on your device.

Private books are not supported in v1.

## 5. 截图

位于 `docs/screenshots/`，建议按商店要求重新导出为 1080×2400 或 1440×3120：

| 商店顺序 | 文件 | 说明 |
|---|---|---|
| 1 | `02-home-light.png` | 首页：Hero、预算摘要、最近记录 |
| 2 | `04-add-light.png` / `05-add-calc-light.png` | 记一笔与表达式 |
| 3 | `06-budget-light.png` | 预算页与预算环 |
| 4 | `08-charts-category-light.png` | 分类占比 |
| 5 | `09-charts-trend-light.png` | 趋势 |
| 6 | `10-charts-calendar-light.png` | 日历热力 |
| 7 | `18-home-hide-light.png` | 隐藏金额 |
| 8 | `03-home-dark.png` / `12-settings-dark.png` | 深色模式 |
| 9 | `19-home-360dp-font13.png` | 窄屏与大字体 |

## 6. 图标与 Feature Graphic

- 应用图标：`app/src/main/res/drawable-nodpi/ic_launcher_background.png` + `ic_launcher_foreground.png`；自适应图标已配置。
- Feature Graphic（1024×500）与商店图标（512×512）需要美术按图标风格另行导出；当前仓库未包含商店尺寸素材。

## 7. 国内分发补充

- 需要软件著作权登记与 App 备案；
- 各应用商店可能要求隐私政策链接、开发者实名与测试账号（本应用无需账号）；
- 建议在商店页明确“完全离线、无网络权限、无私密账本”。
