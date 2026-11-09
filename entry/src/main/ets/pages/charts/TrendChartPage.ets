import { AppFont, Radius, Space } from '../../theme/Theme';
import { PeriodChips } from '../../components/chart/PeriodChips';
import { CustomRangeDialog } from '../../components/chart/CustomRangeDialog';
import { TrendChart, TrendPoint } from '../../components/chart/TrendChart';
import { TopDaysList } from '../../components/chart/TopDaysList';
import { BucketGranularity, BucketSum, DailyStats, DaySum, PeriodRange, PeriodType, StatsFilter } from '../../models/StatsTypes';
import { PeriodResolver } from '../../service/PeriodResolver';
import { StatsService } from '../../service/StatsService';
import { DateUtil } from '../../utils/DateUtil';
import { ErrorUtil } from '../../utils/ErrorUtil';
import { MoneyText, MoneyTone } from '../../components/base/MoneyText';
import { EmptyState } from '../../components/base/EmptyState';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
struct TrendStat {
  @Param label: string = '';
  @Param cents: number = 0;
  @Param note: string = '';

  build() {
    Column({ space: 3 }) {
      MoneyText({
        cents: this.cents,
        fontSize: AppFont.body,
        weight: AppFont.bold,
        tone: MoneyTone.Ink
      })
      Text(this.label)
        .fontSize(AppFont.caption)
        .fontColor($r('app.color.ink_3'))
      if (this.note.length > 0) {
        Text(this.note)
          .fontSize(AppFont.micro)
          .fontColor($r('app.color.ink_3'))
          .maxLines(1)
      }
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }
}

@ComponentV2
export struct TrendChartPage {
  @Param bookIds: string[] = [];
  @Param memberIds: string[] = [];
  @Param excludeBookIds: string[] = [];
  @Param weekStart: number = 1;
  @Param filterVersion: number = 0;
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local period: PeriodType = PeriodType.MONTH;
  @Local customRange: PeriodRange | null = null;
  @Local points: TrendPoint[] = [];
  @Local totalCents: number = 0;
  @Local stats: DailyStats = new DailyStats();
  @Local topDays: DaySum[] = [];
  @Local selectedIndex: number = -1;
  @Local redrawKey: number = 0;
  @Local showRange: boolean = false;
  @Local loading: boolean = true;
  @Local errorText: string = '';

  aboutToAppear(): void {
    this.reload();
  }

  @Monitor('filterVersion')
  onFilterChanged(): void {
    this.reload();
  }

  @Monitor('ui.hideAmount', 'ui.isDark')
  onDisplayChanged(): void {
    this.redrawKey += 1;
    this.selectedIndex = -1;
  }

  private currentRange(): PeriodRange {
    if (this.period === PeriodType.CUSTOM && this.customRange !== null) {
      return this.customRange;
    }
    return PeriodResolver.resolve(this.period, new Date(), this.weekStart);
  }

  private buildFilter(): StatsFilter {
    const range: PeriodRange = this.currentRange();
    const filter: StatsFilter = new StatsFilter();
    filter.bookIds = this.bookIds;
    filter.memberIds = this.memberIds;
    filter.excludeBookIds = this.excludeBookIds;
    filter.startMs = range.startMs;
    filter.endMs = range.endMs;
    filter.weekStart = this.weekStart;
    return filter;
  }

  private async reload(): Promise<void> {
    try {
      this.errorText = '';
      const filter: StatsFilter = this.buildFilter();
      const range: PeriodRange = this.currentRange();
      const granularity: BucketGranularity = PeriodResolver.bucketGranularity(range);
      const buckets: BucketSum[] = await StatsService.byBucket(filter, granularity);
      const points: TrendPoint[] = [];
      for (const bucket of buckets) {
        const point: TrendPoint = new TrendPoint();
        point.key = bucket.key;
        point.label = bucket.label;
        point.cents = bucket.cents;
        points.push(point);
      }
      this.points = points;
      this.stats = await StatsService.dailyStats(filter);
      this.totalCents = this.stats.totalCents;
      this.topDays = await StatsService.topDays(filter, 3);
      this.selectedIndex = -1;
      this.redrawKey += 1;
    } catch (error) {
      this.errorText = ErrorUtil.messageOf(error);
    } finally {
      this.loading = false;
    }
  }

  private selectPeriod(type: PeriodType): void {
    if (type === PeriodType.CUSTOM) {
      this.showRange = true;
      return;
    }
    this.period = type;
    this.customRange = null;
    this.reload();
  }

  private applyRange(range: PeriodRange): void {
    this.customRange = range;
    this.period = PeriodType.CUSTOM;
    this.showRange = false;
    this.reload();
  }

  private customLabel(): string {
    return this.customRange === null ? '' : this.customRange.label;
  }

  private defaultStartKey(): string {
    const now: Date = new Date();
    return DateUtil.dayKey(new Date(now.getFullYear(), now.getMonth(), 1));
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column({ space: Space.x3 }) {
          PeriodChips({
            selected: this.period,
            customLabel: this.customLabel(),
            onSelect: (type: PeriodType) => {
              this.selectPeriod(type);
            }
          })
          .padding({ left: Space.page, right: Space.page })

          if (this.errorText.length > 0) {
            Text(this.errorText)
              .fontSize(AppFont.caption)
              .fontColor($r('app.color.expense'))
              .padding({ left: Space.page, right: Space.page })
          }

          Row() {
            TrendStat({ label: '合计', cents: this.totalCents, note: '' })
            Divider().vertical(true).height(32).color($r('app.color.line'))
            TrendStat({ label: '日均', cents: this.stats.avgCents, note: '' })
            Divider().vertical(true).height(32).color($r('app.color.line'))
            TrendStat({
              label: '最高',
              cents: this.stats.maxCents,
              note: this.stats.maxDayKey.length > 0 ? PeriodResolver.shortDay(this.stats.maxDayKey) : ''
            })
          }
          .width('100%')
          .padding({ top: 10, bottom: 10 })
          .borderRadius(Radius.card)
          .backgroundColor($r('app.color.surface'))
          .border({ width: 1, color: $r('app.color.line') })
          .margin({ left: Space.page, right: Space.page })

          if (this.totalCents === 0 && !this.loading) {
            Column() {
              EmptyState({
                icon: $r('app.media.ic_tab_charts'),
                title: '这个周期还没有支出',
                description: '换个周期试试'
              })
            }
            .width('100%')
            .padding({ left: Space.page, right: Space.page })
            .borderRadius(Radius.cardLg)
            .backgroundColor($r('app.color.chart_surface'))
          } else {
            Column() {
              TrendChart({
                points: this.points,
                hidden: this.ui.hideAmount,
                selectedIndex: this.selectedIndex,
                redrawKey: this.redrawKey,
                onSelect: (index: number) => {
                  this.selectedIndex = index;
                }
              })
              .width('100%')
              .height(190)
            }
            .width('100%')
            .padding(15)
            .borderRadius(Radius.cardLg)
            .backgroundColor($r('app.color.chart_surface'))
            .border({ width: 1, color: $r('app.color.line') })
            .margin({ left: Space.page, right: Space.page })
          }

          Column({ space: 8 }) {
            Text('支出最高的 3 天')
              .fontSize(AppFont.settings)
              .fontWeight(AppFont.bold)
              .fontColor($r('app.color.ink'))
              .width('100%')
            TopDaysList({
              days: this.topDays,
              maxCents: this.stats.maxCents,
              hidden: this.ui.hideAmount
            })
          }
          .width('100%')
          .padding({ left: Space.page, right: Space.page, top: Space.x3 })

          Row().width('100%').height(Space.x8)
        }
        .width('100%')
        .padding({ top: Space.x3 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)

      CustomRangeDialog({
        visible: this.showRange,
        defaultStart: this.defaultStartKey(),
        defaultEnd: DateUtil.dayKey(new Date()),
        onConfirm: (range: PeriodRange) => {
          this.applyRange(range);
        },
        onClose: () => {
          this.showRange = false;
        }
      })
    }
    .width('100%')
    .height('100%')
  }
}
