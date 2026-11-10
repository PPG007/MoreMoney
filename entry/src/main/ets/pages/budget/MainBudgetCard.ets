import { AppFont, Radius, Space } from '../../theme/Theme';
import { MoneyText, MoneyTone } from '../../components/base/MoneyText';
import { RingProgress } from '../../components/chart/RingProgress';
import { BudgetBookView } from '../../service/BudgetService';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
struct BudgetStatRow {
  @Param label: string = '';
  @Param cents: number = 0;
  @Param tone: MoneyTone = MoneyTone.Ink;

  build() {
    Row() {
      Text(this.label)
        .fontSize(AppFont.caption)
        .fontColor($r('app.color.ink_3'))
        .layoutWeight(1)
      MoneyText({
        cents: this.cents,
        fontSize: AppFont.row,
        weight: AppFont.bold,
        tone: this.tone
      })
    }
    .width('100%')
    .height(22)
  }
}

@ComponentV2
export struct MainBudgetCard {
  @Param view: BudgetBookView | null = null;
  @Param perDayCents: number = 0;
  @Event onTap: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();

  private percentText(): string {
    if (this.view === null || this.view.budgetCents <= 0) {
      return '0%';
    }
    const percent: number = Math.round(this.view.spentCents * 100 / this.view.budgetCents);
    if (percent > 999) {
      return '999%+';
    }
    return percent.toString().concat('%');
  }

  private isExpense(): boolean {
    return this.view !== null && this.view.spentCents > this.view.budgetCents;
  }

  build() {
    if (this.view !== null) {
      Column({ space: Space.x4 }) {
        Row({ space: Space.x5 }) {
          RingProgress({
            percent: this.view.percent,
            ringSize: 116,
            strokeWidth: 11,
            hideFill: this.ui.hideAmount,
            isExpense: this.isExpense(),
            centerText: this.percentText()
          })

          Column({ space: 2 }) {
            Text(this.view.name)
              .fontSize(AppFont.settings)
              .fontWeight(AppFont.bold)
              .fontColor($r('app.color.ink'))
            BudgetStatRow({ label: '预算', cents: this.view.budgetCents, tone: MoneyTone.Ink })
            BudgetStatRow({ label: '已用', cents: this.view.spentCents, tone: MoneyTone.Expense })
            BudgetStatRow({
              label: '剩余',
              cents: this.view.remainingCents,
              tone: this.view.remainingCents < 0 ? MoneyTone.Expense : MoneyTone.Good
            })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Row({ space: 6 }) {
          Text('每天可用')
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.brand_ink'))
          MoneyText({
            cents: this.perDayCents,
            fontSize: AppFont.caption,
            weight: AppFont.semibold,
            tone: MoneyTone.Ink
          })
        }
        .padding({ left: 11, right: 11, top: 9, bottom: 9 })
        .borderRadius(11)
        .backgroundColor($r('app.color.brand_wash'))
        .alignSelf(ItemAlign.Start)
      }
      .width('100%')
      .padding(17)
      .borderRadius(Radius.cardLg)
      .backgroundColor($r('app.color.surface'))
      .border({ width: 1, color: $r('app.color.line') })
      .onClick(() => {
        this.onTap();
      })
    }
  }
}
