import { AppFont, Radius, Space } from '../../theme/Theme';
import { IconSize } from '../../theme/IconSize';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
export struct PageHeader {
  @Param title: string = '';
  @Event onBack: () => void = () => {
  };
  @BuilderParam trailing: () => void = this.emptyTrailing;
  @Local ui: GlobalUiStore = UiStore.instance();

  @Builder
  emptyTrailing() {
  }

  build() {
    Row({ space: Space.x1 }) {
      Stack() {
        Image($r('app.media.ic_back'))
          .width(IconSize.back)
          .height(IconSize.back)
          .fillColor($r('app.color.ink'))
      }
      .width(34)
      .height(34)
      .borderRadius(Radius.pill)
      .backgroundColor($r('app.color.surface'))
      .border({ width: 1, color: $r('app.color.line') })
      .onClick(() => {
        this.onBack();
      })

      Text(this.title)
        .fontSize(AppFont.subTitle)
        .fontWeight(AppFont.bold)
        .fontColor($r('app.color.ink'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)

      this.trailing()
    }
    .width('100%')
    .height(52 + this.ui.topInset)
    .padding({
      top: this.ui.topInset,
      left: Space.page,
      right: Space.page
    })
    .alignItems(VerticalAlign.Center)
  }
}
