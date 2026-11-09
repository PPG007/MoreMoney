# T15 · 图表基础层与分类环形图

> 状态：待开始 ｜ 优先级：P2 ｜ 依赖：T05、T11 ｜ 预估：2.5 人日
> 设计依据：`设计规范.md` §8.4（分类）、§4.4；截图 `09-charts-category-light.png`、`12-charts-category-dark.png`

## 1. 目标

建立可复用的 Canvas 图表基础层，并完成“图表 → 分类”子页：环形图、分类圆片、占比标签、图例、点按联动。

## 2. 交付物

| 路径 | 内容 |
|---|---|
| `entry/src/main/ets/components/chart/ChartCanvas.ets` | Canvas 容器（尺寸、像素比、重绘、空态） |
| `entry/src/main/ets/components/chart/ChartColors.ets` | Canvas 用色（来自 `Palette`） |
| `entry/src/main/ets/components/chart/DonutChart.ets` | 环形图绘制 + 命中检测 |
| `entry/src/main/ets/components/chart/DonutLabels.ets` | 分类圆片、占比标签、中心文本 |
| `entry/src/main/ets/pages/charts/ChartsPage.ets` | 三子页容器（分段控件 + 周期 chips） |
| `entry/src/main/ets/pages/charts/CategoryChartPage.ets` | 分类子页 |
| `entry/src/main/ets/pages/charts/ChartLegend.ets` | 图例 |
| `entry/src/main/ets/components/chart/PeriodChips.ets` | 周期选择 chips（趋势/日历复用） |

## 3. 图表基础层

```ts
@ComponentV2
export struct ChartCanvas {
  @Param width: number = 0;          // vp
  @Param height: number = 0;
  @Param redrawKey: number = 0;      // 数据/主题/隐藏变化时 +1
  @Event onDraw: (ctx: CanvasRenderingContext2D, w: number, h: number) => void = () => {};
  @Event onTapPoint: (x: number, y: number) => void = () => {};
}
```

要求：

1. 使用 `Canvas(this.ctx)` + `RenderingContextSettings(true)` 抗锯齿。
2. 尺寸通过外层 `onAreaChange` 获取，不写死；`width/height` 变化时重绘。
3. `redrawKey` 变化时清空并重绘（`ctx.clearRect`）。
4. 点击用 `.onClick((event: ClickEvent) => ...)`，坐标取 `event.x/event.y`（vp），回调给具体图表做命中检测。
5. 提供 `drawEmpty(ctx, w, h, text)` 工具，但空态优先用 ArkUI `EmptyState` 覆盖。
6. 所有颜色从 `ChartColors` 取，禁止在绘制函数里写 hex。

## 4. 分类环形图

### 4.1 数据

```ts
export class DonutSegment {
  categoryId: string = '';
  name: string = '';
  cents: number = 0;
  percent: number = 0;       // 0–1
  color: string = '';        // 来自分类自身 color，不按排名分配
  icon: string = '';
}
```

- 数据来自 `StatsService.byCategory(filter)`，按金额降序。
- 长尾合并：前 5 个 + “其他”；“其他”颜色用 `ChartColors.other`。
- 颜色绑定分类自身（`category.color`），排序变化不换色。

### 4.2 绘制

- 画布基准 280×280，实际按 `min(w,h)` 等比缩放；中心 (w/2, h/2)。
- 半径 `r = 92 * scale`，线宽 `30 * scale`，起始角 `-π/2`，顺时针。
- 段间间隙 2vp（按弧长换算角度）：每段起止各留 `gap/2 = (1 / r)` 弧度。
- 段颜色 `segment.color`；“其他”用 `other`。
- 选中段：外扩 2vp 或提高亮度 8%（二选一，需固定），其余段透明度降到 0.55。
- 中心文本用 ArkUI 叠加，不用 Canvas 文字：总额 `23/700`、标签 10/400；选中时显示分类名 + 金额 + 占比。
- 空数据：不画环，显示居中空态“这个周期还没有支出”。

### 4.3 分类圆片与占比标签

- 圆片 40×40、2vp 分类色边、`surface` 底、图标 19；圆心位于每段中间角度、半径 `r + 26`（保证圆片不超出 280 画布）。
- 用 `Stack` + `.position({ x, y })` 定位（减去自身一半宽高）；超出画布边距时内收，避免裁切。
- 占比标签：8/700 白字小胶囊（`padding 1 4`、圆角 999），位于每段中间角度、半径 `r`；至少显示前 4 个，长尾并入“其他”不显示。
- 圆片/标签为装饰，不拦截点击；点击只走 Canvas 命中检测。

### 4.4 图例

- 行：圆点 8（分类色）+ 图标 28（圆角 8，分类色 13% 底）+ 名称 11/500 + 占比 10/400 `ink_3` + 金额 12/700 `ink`。
- 顺序按金额降序；点击行等同于点击扇区；选中行背景 `brand_wash`。
- 隐藏金额时：金额与占比隐藏（或替换为 `••`），名称/图标保留。

### 4.5 命中检测

- 点击坐标转极坐标：`dx = x - cx`、`dy = y - cy`、`dist = sqrt(dx²+dy²)`。
- 命中条件：`|dist - r| <= 15 + 8`（环带 + 容差）。
- 角度转回 0–2π 后判断落在哪个段；点在中心或环外 → 取消选中。
- 选中状态改变后 `redrawKey += 1`。

## 5. 页面

- `ChartsPage`：顶部标题“图表”25/700 + EyeButton；`SegmentedControl(['分类','趋势','日历'])`；内容区按选中渲染子页。
- 周期 chips：`今日 / 本周 / 本月 / 本年 / 全部 / 自定义`，9→10vp，padding `6 11`，圆角 999，激活 `brand_ink` 底白字。
- 账本/成员筛选：右上角“筛选”按钮，打开多选弹层；默认全选未锁定账本、全部成员；锁定账本不出现在列表。
- 图表卡：padding 15、圆角 24、背景 `chart_surface`、1vp `line`。
- 页面切换使用 `if/else` 条件渲染，保留各子页状态（用 `@Local` 存在父级）。

## 6. 验收标准

| 编号 | 验收项 | 验证方式 |
|---|---|---|
| AC-1 | 视觉与 `09-charts-category-light.png` 对齐；深色与 `12-charts-category-dark.png` 对齐 | 截图比对 |
| AC-2 | 扇区之间有 2vp 间隙，起始角在 12 点方向 | 截图放大检查 |
| AC-3 | 颜色跟随分类：改变时间范围导致排序变化时，同一分类颜色不变 | 真机切换周期 |
| AC-4 | 点按扇区/图例行，中心显示该分类金额与占比，再次点空白恢复总额 | 真机 |
| AC-5 | 长尾合并为“其他”，前 5 个之外金额之和等于“其他” | 造数验证 |
| AC-6 | 多账本/多成员筛选生效，环与图例同步 | 真机 |
| AC-7 | 金额隐藏时中心金额、图例金额、占比标签全部隐藏，环形状保留 | 真机 |
| AC-8 | 无数据时显示空态，不出现空环 | 真机 |
| AC-9 | Canvas 在 360vp 与 420vp 宽度下不变形、不裁切 | 两台设备/预览器 |
| AC-10 | 构建通过 | `devecocli build` |

## 7. 注意事项

- 不要引入 echarts/McCharts；全部 Canvas 自绘。
- 圆片定位要处理扇区过小（<3%）的情况，避免标签重叠；小于阈值的扇区只显示图例。
- Canvas 尺寸变化必须重绘，否则旋转/分屏后图像拉伸。
- 深色模式下环底色用 `chart_surface`，不要用白色。
