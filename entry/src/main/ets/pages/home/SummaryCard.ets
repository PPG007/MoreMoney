import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { LineColors } from '../../theme/Palette';
import { MoneyText, MoneyTone } from '../../components/base/MoneyText';
import { formatCents } from '../../utils/MoneyUtil';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
struct SummaryStat {
  @Param label: string = '';
  @Param tone: MoneyTone = MoneyTone.Ink;
  @Param cents: number = 0;
  @Param showValue: boolean = true;
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local showTip: boolean = false;

  build() {
    Column({ space: 3 }) {
      if (this.showValue) {
        Column() {
          MoneyText({
            cents: this.cents,
            fontSize: AppFont.stat,
            weight: AppFont.bold,
            tone: this.tone
          })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .bindPopup(this.showTip, {
          message: formatCents(this.cents),
          placement: Placement.Top,
          onStateChange: (event: PopupStateChangeParam) => {
            this.showTip = event.isVisible;
          }
        })
        .onClick(() => {
          if (!this.ui.hideAmount) {
            this.showTip = !this.showTip;
          }
        })
      } else {
        Text('—')
          .fontSize(AppFont.stat)
          .fontWeight(AppFont.bold)
          .fontColor($r('app.color.ink_3'))
      }
      Text(this.label)
        .fontSize(AppFont.caption)
        .fontColor($r('app.color.ink_3'))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }
}

@ComponentV2
export struct SummaryCard {
  @Param spentCents: number = 0;
  @Param budgetCents: number = 0;
  @Param hasBudget: boolean = false;
  @Param perDayCents: number = 0;
  @Event onGoBudget: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local showSpentTip: boolean = false;

  private percent(): number {
    if (!this.hasBudget || this.budgetCents <= 0) {
      return 0;
    }
    const ratio: number = this.spentCents / this.budgetCents;
    return ratio < 0 ? 0 : (ratio > 1 ? 1 : ratio);
  }

  private remainingCents(): number {
    return this.budgetCents - this.spentCents;
  }

  private progressWidth(): string {
    return (this.percent() * 100).toString() + '%';
  }

  build() {
    Column({ space: Space.x5 }) {
      Column({ space: 2 }) {
        Text('本月支出')
          .fontSize(AppFont.caption)
          .fontColor($r('app.color.ink_3'))
        Column() {
          MoneyText({
            cents: this.spentCents,
            fontSize: AppFont.heroAmount,
            weight: AppFont.bold,
            tone: MoneyTone.Expense
          })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .bindPopup(this.showSpentTip, {
          message: formatCents(this.spentCents),
          placement: Placement.Top,
          onStateChange: (event: PopupStateChangeParam) => {
            this.showSpentTip = event.isVisible;
          }
        })
        .onClick(() => {
          if (!this.ui.hideAmount) {
            this.showSpentTip = !this.showSpentTip;
          }
        })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      if (this.hasBudget) {
        Stack({ alignContent: Alignment.Start }) {
          Row()
            .width('100%')
            .height(8)
            .borderRadius(Radius.pill)
            .backgroundColor($r('app.color.surface_2'))
          if (!this.ui.hideAmount) {
            Row()
              .width(this.progressWidth())
              .height(8)
              .borderRadius(Radius.pill)
              .linearGradient({
                angle: 0,
                colors: [
                  [$r('app.color.brand'), 0],
                  [$r('app.color.brand_ink'), 1]
                ]
              })
            Stack()
              .width(12)
              .height(12)
              .borderRadius(Radius.pill)
              .backgroundColor($r('app.color.surface'))
              .border({ width: 3, color: $r('app.color.brand_ink') })
              .position({ x: this.progressWidth(), y: -2 })
          }
        }
        .width('100%')
        .height(8)
      } else {
        Row({ space: Space.x2 }) {
          Text('未设置预算')
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.ink_3'))
            .layoutWeight(1)
          Text('去设置')
            .fontSize(AppFont.micro)
            .fontWeight(AppFont.bold)
            .fontColor($r('app.color.brand_ink'))
            .padding({ left: 9, right: 9, top: 5, bottom: 5 })
            .borderRadius(Radius.pill)
            .backgroundColor($r('app.color.brand_wash'))
            .onClick(() => {
              this.onGoBudget();
            })
        }
        .width('100%')
      }

      Row() {
        SummaryStat({
          label: '预算',
          tone: MoneyTone.Ink,
          cents: this.budgetCents,
          showValue: this.hasBudget
        })
        Divider().vertical(true).height(24).color($r('app.color.line')).margin({ left: 8, right: 8 })
        SummaryStat({
          label: '每天可用',
          tone: MoneyTone.Ink,
          cents: this.perDayCents,
          showValue: this.hasBudget
        })
        Divider().vertical(true).height(24).color($r('app.color.line')).margin({ left: 8, right: 8 })
        SummaryStat({
          label: '剩余',
          tone: this.remainingCents() < 0 ? MoneyTone.Expense : MoneyTone.Good,
          cents: this.remainingCents(),
          showValue: this.hasBudget
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(19)
    .borderRadius(Radius.cardLg)
    .backgroundColor($r('app.color.surface'))
    .border({ width: 1, color: LineColors.cardBorder(this.ui.isDark) })
    .shadow(Shadow.card(this.ui.isDark))
  }
}
