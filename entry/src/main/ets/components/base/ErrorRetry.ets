import { AppFont, Radius, Space } from '../../theme/Theme';
import { IconSize } from '../../theme/IconSize';

@ComponentV2
export struct ErrorRetry {
  @Param message: string = '加载失败';
  @Event onRetry: () => void = () => {
  };

  build() {
    Column({ space: Space.x2 }) {
      Image($r('app.media.ic_warning'))
        .width(IconSize.empty)
        .height(IconSize.empty)
        .fillColor($r('app.color.warn'))
        .opacity(0.7)
      Text('加载失败')
        .fontSize(AppFont.row)
        .fontWeight(AppFont.semibold)
        .fontColor($r('app.color.ink'))
      Text(this.message)
        .fontSize(AppFont.caption)
        .fontColor($r('app.color.ink_3'))
        .textAlign(TextAlign.Center)
      Text('重试')
        .fontSize(AppFont.settings)
        .fontWeight(AppFont.semibold)
        .fontColor($r('app.color.brand_ink'))
        .padding({ left: 14, right: 14, top: 7, bottom: 7 })
        .borderRadius(Radius.pill)
        .backgroundColor($r('app.color.brand_wash'))
        .onClick(() => {
          this.onRetry();
        })
    }
    .width('100%')
    .padding({ top: 30, bottom: 30, left: 16, right: 16 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
