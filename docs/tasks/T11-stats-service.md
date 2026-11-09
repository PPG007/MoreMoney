# T11 · 统计聚合服务

> 状态：待开始 ｜ 优先级：P1 ｜ 依赖：T03 ｜ 预估：1.5 人日
> 设计依据：`设计规范.md` §8.3（口径）、§8.4、§9.4、§10.3

## 1. 目标

把“按周期 × 多账本 × 多成员”的统计口径收敛到一个服务里，预算页和三个图表页只调用它，不各自写 SQL。

## 2. 交付物

| 路径 | 内容 |
|---|---|
| `entry/src/main/ets/models/StatsTypes.ets` | `PeriodType`、`StatsFilter`、`PeriodRange`、`CategorySum`、`DaySum`、`BucketSum`、`DailyStats` |
| `entry/src/main/ets/service/PeriodResolver.ets` | 周期解析（纯函数，可单测） |
| `entry/src/main/ets/service/StatsService.ets` | 聚合查询 |
| `entry/src/test/PeriodResolver.test.ets` | 边界单测 |

## 3. 类型定义

```ts
export enum PeriodType { TODAY, WEEK, MONTH, YEAR, ALL, CUSTOM }
export enum BucketGranularity { DAY, WEEK, MONTH }

export class StatsFilter {
  bookIds: string[] = [];          // 空 = 全部未归档账本
  memberIds: string[] = [];        // 空 = 全部成员
  startMs: number = 0;             // 含
  endMs: number = 0;               // 含
  excludeBookIds: string[] = [];   // 锁定私密账本，由调用方传入
  weekStart: number = 1;           // 1=周一 … 7=周日，来自 SettingsService
}

export class PeriodRange { startMs: number = 0; endMs: number = 0; label: string = ''; }
export class CategorySum { categoryId: string = ''; name: string = ''; icon: string = ''; color: string = ''; cents: number = 0; }
export class DaySum { dayKey: string = ''; cents: number = 0; }
export class BucketSum { key: string = ''; label: string = ''; cents: number = 0; }
export class DailyStats { totalCents: number = 0; avgCents: number = 0; maxCents: number = 0; maxDayKey: string = ''; days: number = 0; }
```

## 4. 周期解析

```ts
export class PeriodResolver {
  static resolve(type: PeriodType, now: Date, weekStart: number): PeriodRange
  static custom(startDayKey: string, endDayKey: string): PeriodRange
  static bucketGranularity(range: PeriodRange): BucketGranularity
}
```

规则：

- `TODAY`：当天 00:00:00.000 – 23:59:59.999。
- `WEEK`：按 `weekStart`（1=周一 … 7=周日）取本周起止。
- `MONTH`：当月 1 日 00:00 – 月末 23:59:59.999。
- `YEAR`：1 月 1 日 – 12 月 31 日。
- `ALL`：`startMs = 0`，`endMs = now`。
- `CUSTOM`：起止日期都包含，结束日为 23:59:59.999；起 > 止时抛业务错误（由调用方转换为提示）。
- `label`：`今天` / `本周` / `11月` / `2026年` / `全部` / `11月1日–11月9日`。
- `bucketGranularity`：范围 ≤ 31 天用 `DAY`；32–120 天用 `WEEK`；> 120 天用 `MONTH`。

## 5. StatsService

```ts
export class StatsService {
  static sum(filter: StatsFilter): Promise<number>
  static byCategory(filter: StatsFilter): Promise<CategorySum[]>       // 金额降序
  static byDay(filter: StatsFilter): Promise<DaySum[]>                 // 升序，缺日补 0
  static byBucket(filter: StatsFilter, g: BucketGranularity): Promise<BucketSum[]>
  static topDays(filter: StatsFilter, n: number): Promise<DaySum[]>    // 金额降序
  static dailyStats(filter: StatsFilter): Promise<DailyStats>
  static categoryLegend(filter: StatsFilter): Promise<CategorySum[]>   // 金额降序 + 其他合并
}
```

实现要求：

1. 基础条件固定为 `deleted_at IS NULL`。
2. 时间条件用 `day_key` 字符串比较（`BETWEEN 'YYYY-MM-DD' AND 'YYYY-MM-DD'`），避免毫秒边界问题；`startMs/endMs` 先由 `DateUtil.dayKey` 转成 dayKey。
3. 账本过滤：`book_id IN (...)`，`excludeBookIds` 用 `NOT IN (...)`；同时排除 `archived=1` 的账本（JOIN book 或由调用方传入）。
4. 成员过滤：`member_id IN (...)`，空数组表示不过滤。
5. 所有聚合在 SQL 内完成，禁止把全量流水读进内存再循环。
6. `byCategory` 需要联表取分类名/图标/颜色；同一分类合并。
7. `byDay` 按请求范围补齐缺失日期（值为 0），保证折线/日历连续；**仅用于 ≤120 天的范围**，更长范围由调用方改用 `byBucket`，避免一次生成上千个点。
8. `byBucket` 的 `key`：DAY=`YYYY-MM-DD`，WEEK=该周起始日的 `YYYY-MM-DD`（按 `filter.weekStart`），MONTH=`YYYY-MM`；`label` 分别为 `11/9`、`11/3周`、`11月`。
9. `topDays` 只返回有金额的日期，金额相同按日期升序。
10. `dailyStats`：
    - `days` = 范围内有金额的天数（不是自然天数）；
    - `avgCents` = `totalCents / days` 向下取整；
    - `maxCents`/`maxDayKey` = 最大值及最早出现日。
11. `categoryLegend`：前 5 个分类保留，其余合并为“其他”（`categoryId='__other__'`），用于饼图；分类色由调用方按槽位映射。
12. 查询参数全部使用 `bindArgs`，禁止字符串拼接用户输入。

## 6. 账本口径

- 预算合计只统计“已设置预算且未锁定”的账本（由调用方传 `excludeBookIds`）。
- 私密账本锁定：调用方通过 `PrivateBookService.lockedBookIds()` 得到 ID 数组填入 `excludeBookIds`；本服务不感知解锁状态。
- 归档账本永不参与统计。

## 7. 验收标准

| 编号 | 验收项 | 验证方式 |
|---|---|---|
| AC-1 | `PeriodResolver` 的今天/本周（周一起）/本月/本年/全部/自定义边界正确 | 单测断言 startMs/endMs |
| AC-2 | 2026-02（28 天）、2024-02（29 天）月份边界正确 | 单测 |
| AC-3 | 跨年自定义范围（2025-12-20 – 2026-01-10）返回正确天数 | 单测 |
| AC-4 | 空结果返回 `0` / 空数组，不抛异常 | 调试调用 |
| AC-5 | 多账本 + 多成员 + 排除锁定账本，合计与手工 SQL 一致 | 用 DebugSeed 数据比对 |
| AC-6 | `byDay` 缺日补 0，长度等于范围天数 | 调试断言 |
| AC-7 | 分类图例前 5 + 其他，其他金额等于剩余之和 | 调试断言 |
| AC-8 | 无 `SELECT *` 全表读取，聚合语句带 `GROUP BY` | 代码检查 |
| AC-9 | 构建通过 | `devecocli build` |

## 8. 注意事项

- 时区：全部用本地时区的 `dayKey`，不要用 UTC 日期。
- 周起始日来自 `SettingsService.weekStart`，调用方传入，服务自身不读设置。
- 金额始终为整数分，`AVG` 结果用 `CAST` 后取整，禁止浮点返回。
