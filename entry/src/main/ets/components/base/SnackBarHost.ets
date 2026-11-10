import { AppFont, Radius, Space } from '../../theme/Theme';
import { SnackColors } from '../../theme/Palette';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { SnackBarService } from '../../service/SnackBarService';

@ComponentV2
export struct SnackBarHost {
  @Local ui: GlobalUiStore = UiStore.instance();

  private tone(): string {
    return this.ui.snackbar.tone;
  }

  private accent(): string {
    return SnackColors.accent(this.tone(), this.ui.isDark);
  }

  private icon(): Resource {
    if (this.tone() === 'success') {
      return $r('app.media.ic_check');
    }
    if (this.tone() === 'error') {
      return $r('app.media.ic_close');
    }
    if (this.tone() === 'warning') {
      return $r('app.media.ic_warning');
    }
    return $r('app.media.ic_info');
  }

  build() {
    if (this.ui.snackbar.visible) {
      Column() {
        Row({ space: 10 }) {
          Stack() {
            Image(this.icon())
              .width(17)
              .height(17)
              .fillColor(this.accent())
          }
          .width(32)
          .height(32)
          .borderRadius(Radius.pill)
          .backgroundColor(SnackColors.iconWash(this.tone(), this.ui.isDark))

          Text(this.ui.snackbar.message)
            .fontSize(AppFont.legend)
            .fontWeight(AppFont.semibold)
            .fontColor(SnackColors.text(this.ui.isDark))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (this.ui.snackbar.actionLabel.length > 0) {
            Text(this.ui.snackbar.actionLabel)
              .fontSize(AppFont.caption)
              .fontWeight(AppFont.bold)
              .fontColor(this.accent())
              .padding({ left: 11, right: 11, top: 6, bottom: 6 })
              .borderRadius(Radius.pill)
              .backgroundColor(SnackColors.iconWash(this.tone(), this.ui.isDark))
              .onClick(() => {
                SnackBarService.runAction();
              })
          }

          Stack() {
            Image($r('app.media.ic_close'))
              .width(12)
              .height(12)
              .fillColor(SnackColors.muted(this.ui.isDark))
          }
          .width(26)
          .height(26)
          .borderRadius(Radius.pill)
          .backgroundColor(SnackColors.closeWash(this.ui.isDark))
          .responseRegion({ x: -6, y: -6, width: 38, height: 38 })
          .onClick(() => {
            SnackBarService.dismiss();
          })
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 9, bottom: 9 })
        .borderRadius(16)
        .backgroundColor(SnackColors.surface(this.tone(), this.ui.isDark))
        .border({ width: 1, color: SnackColors.border(this.tone(), this.ui.isDark) })
        .shadow({
          radius: 18,
          offsetX: 0,
          offsetY: 8,
          color: this.ui.isDark ? 'rgba(0,0,0,0.45)' : 'rgba(39,34,49,0.16)'
        })
      }
      .width('100%')
      .padding({ left: Space.page, right: Space.page })
      .margin({ top: this.ui.topInset + 8 })
      .transition(TransitionEffect.OPACITY.animation({ duration: 180, curve: Curve.EaseOut })
        .combine(TransitionEffect.translate({ y: -14 })))
    }
  }
}
