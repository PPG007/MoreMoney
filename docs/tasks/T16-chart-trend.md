# T16 · 支出趋势折线图

> 状态：已完成 ｜ 优先级：P2 ｜ 依赖：T15 ｜ 预估：2.0 人日
> 设计依据：`设计规范.md` §8.4（趋势）；截图 `10-charts-trend-light.png`

## 1. 目标

完成“图表 → 趋势”子页：折线 + 渐变面积、最高点气泡、统计三列、最高 3 天排行，支持周期与多账本/多成员筛选。

## 2. 交付物

| 路径 | 内容 |
|---|---|
| `entry/src/main/ets/pages/charts/TrendChartPage.ets` | 子页容器、数据、统计 |
| `entry/src/main/ets/components/chart/TrendChart.ets` | Canvas 折线绘制 + 命中 |
| `entry/src/main/ets/components/chart/TopDaysList.ets` | 最高 3 天列表 |
| `entry/src/main/ets/components/chart/CustomRangeDialog.ets` | 自定义日期范围 |

## 3. 页面结构

```text
列
├── 周期 chips（T15 的 PeriodChips）
├── 统计三列：合计 / 日均 / 最高
├── 图表卡（padding 15、圆角 24、chart_surface）
│   └── TrendChart（320×190 基准，含最高点标签）
├── “支出最高的 3 天”标题
└── TopDaysList × 3
```

## 4. 数据

- 过滤器同 T15（周期、账本、成员、排除锁定账本）。
- `StatsService.byDay(filter)` 取序列；不足 2 个点时仍绘制单点/双点。
- 粒度：`PeriodResolver.bucketGranularity(range)`：
  - `DAY`：按日；
  - `WEEK`：按周（周一起）；
  - `MONTH`：按月。
- 统计：
  - 合计 = `sum`；
  - 日均 = 合计 / 有金额的天数（`dailyStats.days`，为 0 时显示 0）；
  - 最高 = `dailyStats.maxCents` + 对应日期。

## 5. 绘制

- 绘制区 padding：左 26、右 12、上 34、下 16（给轴标签与最高点气泡留空间）。
- Y 轴：
  - `niceMax = 向上取整到 1/2/5 × 10^n`，最小 100 元；`maxY` = niceMax；
  - 画 3 条水平参考线（`line` 40% 透明，1vp），不画 Y 轴数字（设计无 Y 轴刻度），但保留顶部 `¥maxY` 微标签 10/400 `ink_3`（可选，若与设计冲突则去掉）。
- X 轴：
  - 标签 10/400 `ink_3`，最多 6 个（首、尾、中间均匀取样）；
  - DAY 显示 `11/9`，WEEK 显示 `11/3周`，MONTH 显示 `11月`；
  - 首尾标签与边缘留 8vp 内边距，避免裁切。
- 折线：
  - 2vp `brand_ink`；
  - 面积渐变 `createLinearGradient(0, top, 0, bottom)`：`brand` 30% → 0；
  - 点：r 3.4，`chart_surface` 填充 + 2vp `brand_ink` 描边；最后一个点 r 4.6；
  - 单点：不画线，只画点 + 面积省略。
- 最高点：
  - 在最值点上方绘制白底胶囊（`surface` 底、1vp `line`、圆角 8、padding `3 6`），文字 10/700 `ink`，金额（`¥1,286` 整数部分即可，若设计需要两位小数则保留）；
  - 超出顶部时翻到点下方；左右夹紧在画布内。
- 选中/点按：
  - 点击最近的数据点（水平距离 < 16vp），显示竖向指示线 + 该点气泡（日期 + 金额）；
  - 再次点空白取消。
- 隐藏金额：不显示最高点气泡、不显示统计数字、Top3 金额与条隐藏；折线形状保留。
- 空数据：显示 `EmptyState`，不画空坐标系。

## 6. 统计与 Top3

- 三列：数字 14/700（合计 `ink`、日均 `ink`、最高 `ink`），标签 10/400 `ink_3`。
- `TopDaysList`：最多 3 行，行 padding `8 13`、圆角 12、`surface_2` 底：
  - 日期 10/400 `ink_2`（`11月9日 周一`）
  - 金额 11/700 `ink`
  - 条：高 5、圆角 999、宽度按 `cents / max`，填充 `brand`
- 不足 3 天时只显示实际天数；无数据显示“暂无支出”。

## 7. 自定义范围

- 点击“自定义” chips 打开 `CustomRangeDialog`：
  - 两行：开始日期 / 结束日期，点击各自弹 `DatePickerDialog`；
  - 默认：本月 1 日 – 今天；
  - 校验：开始 ≤ 结束，且结束不晚于今天（允许未来？v1 不允许）；
  - 确认后 chips 文本变为 `11/1–11/9`，重新查询。
- 其他周期切换后清空自定义选择。

## 8. 验收标准

| 编号 | 验收项 | 验证方式 |
|---|---|---|
| AC-1 | 视觉与 `10-charts-trend-light.png` 对齐（折线、面积、点、最高点标签） | 截图比对 |
| AC-2 | 周期切换（今日/本周/本月/本年/全部/自定义）数据与横轴粒度正确 | 真机 + 造数 |
| AC-3 | 大于 120 天自动按月聚合，32–120 天按周聚合 | 造数验证 |
| AC-4 | 最高点标签不越界、不遮挡；单点/两点数据不崩溃 | 真机 |
| AC-5 | 点击数据点显示日期与金额，点空白取消 | 真机 |
| AC-6 | 统计三列与 Top3 数值与数据库一致 | 手工比对 |
| AC-7 | 隐藏金额时统计、气泡、Top3 全部隐藏，折线保留 | 真机 |
| AC-8 | 多账本/多成员筛选生效，锁定私密账本排除 | 真机 |
| AC-9 | 无数据时显示空态 | 清空数据验证 |
| AC-10 | 构建通过 | `devecocli build` |

## 9. 注意事项

- 不要用 `Canvas` 的 `fillText` 画中文标签（字体度量不稳定），轴标签与气泡用 ArkUI 组件叠加。
- Y 轴刻度只用于内部映射，不显示密集网格。
- 面积渐变必须随画布高度计算，窗口变化后重绘。
- 所有金额从 `StatsService` 的整数分转换，不要在绘制层做单位换算。
