import { AppFont, Radius, Space } from '../../theme/Theme';
import { DaySum } from '../../models/StatsTypes';
import { MoneyText, MoneyTone } from '../../components/base/MoneyText';
import { DateUtil } from '../../utils/DateUtil';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
export struct TopDaysList {
  @Param days: DaySum[] = [];
  @Param maxCents: number = 0;
  @Param hidden: boolean = false;
  @Local ui: GlobalUiStore = UiStore.instance();

  private barWidth(cents: number): string {
    if (this.hidden || this.maxCents <= 0) {
      return '0%';
    }
    const ratio: number = cents / this.maxCents;
    const clamped: number = ratio > 1 ? 1 : ratio;
    return (clamped * 100).toString() + '%';
  }

  build() {
    Column({ space: 8 }) {
      if (this.days.length === 0) {
        Text('暂无支出')
          .fontSize(AppFont.caption)
          .fontColor($r('app.color.ink_3'))
          .width('100%')
          .padding({ top: 8, bottom: 8 })
      } else {
        ForEach(this.days, (day: DaySum) => {
          Row({ space: 11 }) {
            Text(DateUtil.formatDayCn(day.dayKey))
              .fontSize(AppFont.caption)
              .fontColor($r('app.color.ink_2'))
              .width(84)
            Column({ space: 4 }) {
              MoneyText({
                cents: day.cents,
                fontSize: AppFont.legend,
                weight: AppFont.bold,
                tone: MoneyTone.Ink
              })
              Row() {
                Stack({ alignContent: Alignment.Start }) {
                  Row()
                    .width('100%')
                    .height(5)
                    .borderRadius(Radius.pill)
                    .backgroundColor($r('app.color.surface'))
                  Row()
                    .width(this.barWidth(day.cents))
                    .height(5)
                    .borderRadius(Radius.pill)
                    .backgroundColor($r('app.color.brand'))
                }
                .width('100%')
                .height(5)
              }
              .width('100%')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding({ left: 13, right: 13, top: 8, bottom: 8 })
          .borderRadius(Radius.chip)
          .backgroundColor($r('app.color.surface_2'))
          .alignItems(VerticalAlign.Center)
        }, (day: DaySum) => day.dayKey)
      }
    }
    .width('100%')
  }
}
