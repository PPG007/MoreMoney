import { AppFont, Radius, Space } from '../../theme/Theme';
import { AmountBar, AmountTone } from '../../components/base/AmountBar';
import { MoneyText, MoneyTone } from '../../components/base/MoneyText';
import { BudgetBookView } from '../../service/BudgetService';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
export struct BudgetBookRow {
  @Param view: BudgetBookView = new BudgetBookView();
  @Event onTap: (bookId: string) => void = (bookId: string) => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();

  private percentText(): string {
    const percent: number = Math.round(this.view.percent * 100);
    if (percent > 999) {
      return '999%+';
    }
    return percent.toString().concat('%');
  }

  build() {
    Row({ space: 11 }) {
      Stack() {
        Image($r('app.media.' + this.view.icon))
          .width(19)
          .height(19)
          .fillColor(this.view.color)
      }
      .width(36)
      .height(36)
      .borderRadius(Radius.chip)
      .backgroundColor($r('app.color.surface_2'))

      Column({ space: 4 }) {
        Text(this.view.name)
          .fontSize(AppFont.row)
          .fontWeight(AppFont.bold)
          .fontColor($r('app.color.ink'))
          .maxLines(1)
        AmountBar({
          percent: this.ui.hideAmount ? 0 : this.view.percent,
          barHeight: 5,
          tone: this.view.remainingCents < 0 ? AmountTone.Expense : AmountTone.Brand
        })
        Row({ space: 4 }) {
          Text('已用')
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.ink_3'))
          MoneyText({
            cents: this.view.spentCents,
            fontSize: AppFont.caption,
            weight: AppFont.regular,
            tone: MoneyTone.Ink
          })
          Text('· 剩余')
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.ink_3'))
          MoneyText({
            cents: this.view.remainingCents,
            fontSize: AppFont.caption,
            weight: AppFont.regular,
            tone: this.view.remainingCents < 0 ? MoneyTone.Expense : MoneyTone.Ink
          })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.ui.hideAmount) {
        Text('••')
          .fontSize(AppFont.body)
          .fontWeight(AppFont.bold)
          .fontColor($r('app.color.ink'))
      } else {
        Text(this.percentText())
          .fontSize(AppFont.body)
          .fontWeight(AppFont.bold)
          .fontColor(this.view.remainingCents < 0 ? $r('app.color.expense') : $r('app.color.ink'))
          .fontFeature(AppFont.tnum)
      }
    }
    .width('100%')
    .padding({ left: 13, right: 13, top: 12, bottom: 12 })
    .borderRadius(Radius.card)
    .backgroundColor($r('app.color.surface'))
    .border({ width: 1, color: $r('app.color.line') })
    .onClick(() => {
      this.onTap(this.view.bookId);
    })
  }
}
