import { AppFont, Radius, Space } from '../../theme/Theme';
import { SnackColors } from '../../theme/Palette';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { SnackBarService } from '../../service/SnackBarService';

@ComponentV2
export struct SnackBarHost {
  @Local ui: GlobalUiStore = UiStore.instance();

  build() {
    if (this.ui.snackbar.visible) {
      Column() {
        Row({ space: Space.x3 }) {
          Text(this.ui.snackbar.message)
            .fontSize(AppFont.legend)
            .fontColor(SnackColors.text(this.ui.isDark))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (this.ui.snackbar.actionLabel.length > 0) {
            Text(this.ui.snackbar.actionLabel)
              .fontSize(AppFont.legend)
              .fontWeight(AppFont.bold)
              .fontColor($r('app.color.brand'))
              .onClick(() => {
                SnackBarService.runAction();
              })
          }
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 12, bottom: 12 })
        .borderRadius(Radius.chip)
        .backgroundColor(SnackColors.background(this.ui.isDark))
      }
      .width('100%')
      .padding({ left: Space.page, right: Space.page })
      .margin({ bottom: this.ui.bottomInset + 76 })
    }
  }
}
