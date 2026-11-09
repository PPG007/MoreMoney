import { AppFont } from '../../theme/Theme';

@ComponentV2
export struct SectionHeader {
  @Param title: string = '';
  @BuilderParam trailing: () => void = this.emptyTrailing;

  @Builder
  emptyTrailing() {
  }

  build() {
    Row() {
      Text(this.title)
        .fontSize(AppFont.body)
        .fontWeight(AppFont.bold)
        .fontColor($r('app.color.ink'))
        .layoutWeight(1)
      this.trailing()
    }
    .width('100%')
    .height(20)
    .alignItems(VerticalAlign.Center)
  }
}
