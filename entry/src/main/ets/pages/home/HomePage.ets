import { AppFont, Space } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
export struct HomePage {
  @Local ui: GlobalUiStore = UiStore.instance();

  build() {
    Column({ space: Space.x3 }) {
      Text('记账本')
        .fontSize(AppFont.pageTitle)
        .fontWeight(AppFont.bold)
        .fontColor($r('app.color.ink'))
      Text('月度概览与流水由 T06 实现')
        .fontSize(AppFont.caption)
        .fontColor($r('app.color.ink_3'))
    }
    .width('100%')
    .height('100%')
    .padding({
      left: Space.page,
      right: Space.page,
      top: this.ui.topInset + Space.x4
    })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('app.color.bg'))
  }
}
