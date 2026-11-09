import { AppFont, Radius, Space } from '../../theme/Theme';
import { ChartColors } from '../../components/chart/ChartColors';
import { DonutChart, DonutSegment } from '../../components/chart/DonutChart';
import { DonutLabels } from '../../components/chart/DonutLabels';
import { PeriodChips } from '../../components/chart/PeriodChips';
import { CustomRangeDialog } from '../../components/chart/CustomRangeDialog';
import { CategorySum, PeriodRange, PeriodType, StatsFilter } from '../../models/StatsTypes';
import { PeriodResolver } from '../../service/PeriodResolver';
import { StatsService } from '../../service/StatsService';
import { DateUtil } from '../../utils/DateUtil';
import { ErrorUtil } from '../../utils/ErrorUtil';
import { MoneyText, MoneyTone } from '../../components/base/MoneyText';
import { ChartLegend } from './ChartLegend';
import { EmptyState } from '../../components/base/EmptyState';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
export struct CategoryChartPage {
  @Param bookIds: string[] = [];
  @Param memberIds: string[] = [];
  @Param excludeBookIds: string[] = [];
  @Param weekStart: number = 1;
  @Param filterVersion: number = 0;
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local period: PeriodType = PeriodType.MONTH;
  @Local customRange: PeriodRange | null = null;
  @Local segments: DonutSegment[] = [];
  @Local totalCents: number = 0;
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
  }

  private currentRange(): PeriodRange {
    if (this.period === PeriodType.CUSTOM && this.customRange !== null) {
      return this.customRange;
    }
    return PeriodResolver.resolve(this.period, new Date(), this.weekStart);
  }

  private async reload(): Promise<void> {
    try {
      this.errorText = '';
      const range: PeriodRange = this.currentRange();
      const filter: StatsFilter = new StatsFilter();
      filter.bookIds = this.bookIds;
      filter.memberIds = this.memberIds;
      filter.excludeBookIds = this.excludeBookIds;
      filter.startMs = range.startMs;
      filter.endMs = range.endMs;
      filter.weekStart = this.weekStart;
      const legend: CategorySum[] = await StatsService.categoryLegend(filter);
      let total: number = 0;
      for (const item of legend) {
        total += item.cents;
      }
      const segments: DonutSegment[] = [];
      for (const item of legend) {
        const segment: DonutSegment = new DonutSegment();
        segment.categoryId = item.categoryId;
        segment.name = item.name;
        segment.icon = item.icon;
        segment.cents = item.cents;
        segment.percent = total > 0 ? item.cents / total : 0;
        segment.color = item.categoryId === '__other__' ? ChartColors.other(this.ui.isDark) : item.color;
        segments.push(segment);
      }
      this.totalCents = total;
      this.segments = segments;
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
    if (this.customRange === null) {
      return '';
    }
    return this.customRange.label;
  }

  private hasSelection(): boolean {
    return this.selectedIndex >= 0 && this.selectedIndex < this.segments.length;
  }

  private selName(): string {
    return this.hasSelection() ? this.segments[this.selectedIndex].name : '';
  }

  private selCents(): number {
    return this.hasSelection() ? this.segments[this.selectedIndex].cents : 0;
  }

  private selPercentText(): string {
    const percent: number = this.hasSelection() ? this.segments[this.selectedIndex].percent : 0;
    return (percent * 100).toFixed(1).concat('%');
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
              .width('100%')
              .padding({ left: Space.page, right: Space.page })
          }

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
            Column({ space: Space.x3 }) {
              Stack() {
                DonutChart({
                  segments: this.segments,
                  selectedIndex: this.selectedIndex,
                  redrawKey: this.redrawKey,
                  onSelect: (index: number) => {
                    this.selectedIndex = index;
                  }
                })
                DonutLabels({
                  segments: this.segments,
                  selectedIndex: this.selectedIndex,
                  hidden: this.ui.hideAmount
                })
                Column({ space: 2 }) {
                  if (this.hasSelection()) {
                    Text(this.selName())
                      .fontSize(AppFont.caption)
                      .fontColor($r('app.color.ink_3'))
                    MoneyText({
                      cents: this.selCents(),
                      fontSize: AppFont.donutCenter,
                      weight: AppFont.bold,
                      tone: MoneyTone.Ink
                    })
                    if (!this.ui.hideAmount) {
                      Text(this.selPercentText())
                        .fontSize(AppFont.caption)
                        .fontColor($r('app.color.ink_3'))
                    }
                  } else {
                    Text('总额')
                      .fontSize(AppFont.caption)
                      .fontColor($r('app.color.ink_3'))
                    MoneyText({
                      cents: this.totalCents,
                      fontSize: AppFont.donutCenter,
                      weight: AppFont.bold,
                      tone: MoneyTone.Ink
                    })
                  }
                }
                .width(160)
                .alignItems(HorizontalAlign.Center)
              }
              .width(280)
              .height(280)

              ChartLegend({
                segments: this.segments,
                selectedIndex: this.selectedIndex,
                onSelect: (index: number) => {
                  this.selectedIndex = index;
                }
              })
            }
            .width('100%')
            .padding(15)
            .borderRadius(Radius.cardLg)
            .backgroundColor($r('app.color.chart_surface'))
            .border({ width: 1, color: $r('app.color.line') })
            .margin({ left: Space.page, right: Space.page })
          }

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
