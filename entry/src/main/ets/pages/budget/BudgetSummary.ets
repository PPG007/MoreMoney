import { AppFont, Radius, Space } from '../../theme/Theme';
import { MoneyText, MoneyTone } from '../../components/base/MoneyText';

@ComponentV2
struct BudgetStat {
  @Param label: string = '';
  @Param cents: number = 0;
  @Param tone: MoneyTone = MoneyTone.Ink;

  build() {
    Column({ space: 3 }) {
      MoneyText({
        cents: this.cents,
        fontSize: AppFont.subTitle,
        weight: AppFont.bold,
        tone: this.tone
      })
      Text(this.label)
        .fontSize(AppFont.caption)
        .fontColor($r('app.color.ink_3'))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }
}

@ComponentV2
export struct BudgetSummary {
  @Param totalCents: number = 0;
  @Param spentCents: number = 0;
  @Param remainingCents: number = 0;

  build() {
    Row() {
      BudgetStat({ label: '预算合计', cents: this.totalCents, tone: MoneyTone.Ink })
      Divider().vertical(true).height(28).color($r('app.color.line'))
      BudgetStat({ label: '已用', cents: this.spentCents, tone: MoneyTone.Expense })
      Divider().vertical(true).height(28).color($r('app.color.line'))
      BudgetStat({
        label: '剩余',
        cents: this.remainingCents,
        tone: this.remainingCents < 0 ? MoneyTone.Expense : MoneyTone.Good
      })
    }
    .width('100%')
    .padding({ left: 0, right: 0, top: 13, bottom: 13 })
    .borderRadius(Radius.card)
    .backgroundColor($r('app.color.surface'))
    .border({ width: 1, color: $r('app.color.line') })
    .margin({ left: Space.page, right: Space.page })
  }
}
