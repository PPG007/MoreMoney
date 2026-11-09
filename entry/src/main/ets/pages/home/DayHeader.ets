import { AppFont, Space } from '../../theme/Theme';
import { MoneyText, MoneyTone } from '../../components/base/MoneyText';
import { DateUtil } from '../../utils/DateUtil';

@ComponentV2
export struct DayHeader {
  @Param dayKey: string = '';
  @Param cents: number = 0;
  @Param locked: boolean = false;

  build() {
    Row({ space: Space.x2 }) {
      Row()
        .width(5)
        .height(5)
        .borderRadius(3)
        .backgroundColor($r('app.color.brand'))
      Text(DateUtil.formatDayCn(this.dayKey))
        .fontSize(AppFont.micro)
        .fontWeight(AppFont.semibold)
        .fontColor($r('app.color.ink_2'))
        .layoutWeight(1)
      MoneyText({
        cents: this.cents,
        fontSize: AppFont.micro,
        weight: AppFont.semibold,
        tone: MoneyTone.Ink,
        locked: this.locked,
        showSymbol: true
      })
    }
    .width('100%')
    .height(26)
    .padding({ left: 2, right: 2 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.bg'))
  }
}
