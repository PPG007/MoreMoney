import { AppFont } from '../../theme/Theme';
import { withAlpha } from '../../theme/Palette';

@ComponentV2
export struct MemberDot {
  @Param initial: string = '';
  @Param color: string = '';
  @Param dotSize: number = 15;

  build() {
    Text(this.initial)
      .fontSize(AppFont.micro)
      .fontWeight(AppFont.bold)
      .fontColor(this.color)
      .textAlign(TextAlign.Center)
      .width(this.dotSize)
      .height(this.dotSize)
      .borderRadius(this.dotSize / 2)
      .backgroundColor(withAlpha(this.color, 0.15))
  }
}
