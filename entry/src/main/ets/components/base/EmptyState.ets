import { AppFont, Space } from '../../theme/Theme';
import { IconSize } from '../../theme/IconSize';

@ComponentV2
export struct EmptyState {
  @Param icon: Resource = $r('app.media.ic_file');
  @Param title: string = '';
  @Param description: string = '';
  @Param actionLabel: string = '';
  @Event onAction: () => void = () => {
  };

  build() {
    Column({ space: Space.x2 }) {
      Image(this.icon)
        .width(IconSize.empty)
        .height(IconSize.empty)
        .fillColor($r('app.color.ink_3'))
        .opacity(0.6)
      Text(this.title)
        .fontSize(AppFont.row)
        .fontWeight(AppFont.semibold)
        .fontColor($r('app.color.ink'))
        .textAlign(TextAlign.Center)
      if (this.description.length > 0) {
        Text(this.description)
          .fontSize(AppFont.caption)
          .fontColor($r('app.color.ink_3'))
          .textAlign(TextAlign.Center)
      }
      if (this.actionLabel.length > 0) {
        Text(this.actionLabel)
          .fontSize(AppFont.settings)
          .fontWeight(AppFont.semibold)
          .fontColor($r('app.color.brand_ink'))
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(999)
          .backgroundColor($r('app.color.brand_wash'))
          .onClick(() => {
            this.onAction();
          })
      }
    }
    .width('100%')
    .padding({ top: 28, bottom: 28, left: 16, right: 16 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
