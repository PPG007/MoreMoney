import { AppFont, Radius, Space } from '../../theme/Theme';
import { BudgetBookView } from '../../service/BudgetService';
import { PrimaryButton } from '../../components/base/PrimaryButton';

@ComponentV2
export struct UnsetBudgetCard {
  @Param view: BudgetBookView = new BudgetBookView();
  @Event onSet: (bookId: string) => void = (bookId: string) => {
  };

  build() {
    Column({ space: Space.x3 }) {
      Row({ space: 11 }) {
        Stack() {
          Image($r('app.media.' + this.view.icon))
            .width(21)
            .height(21)
            .fillColor($r('app.color.brand_ink'))
        }
        .width(42)
        .height(42)
        .borderRadius(13)
        .backgroundColor($r('app.color.brand_wash'))

        Column({ space: 2 }) {
          Text(this.view.name)
            .fontSize(AppFont.settings)
            .fontWeight(AppFont.bold)
            .fontColor($r('app.color.ink'))
          Text('还没有设置本月预算')
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.ink_2'))
          Text('未设置前不计入合计')
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.ink_3'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      PrimaryButton({
        label: '设置预算',
        buttonHeight: 40,
        onTap: () => {
          this.onSet(this.view.bookId);
        }
      })
    }
    .width('100%')
    .padding(15)
    .borderRadius(Radius.card)
    .backgroundColor($r('app.color.brand_wash'))
    .border({ width: 1.5, color: $r('app.color.line'), style: BorderStyle.Dashed })
  }
}
