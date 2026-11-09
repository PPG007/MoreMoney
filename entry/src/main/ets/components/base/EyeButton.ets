import { Radius } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
export struct EyeButton {
  @Local ui: GlobalUiStore = UiStore.instance();

  build() {
    Stack() {
      Image(this.ui.hideAmount ? $r('app.media.ic_eye_off') : $r('app.media.ic_eye'))
        .width(17)
        .height(17)
        .fillColor(this.ui.hideAmount ? $r('app.color.brand_ink') : $r('app.color.ink'))
    }
    .width(34)
    .height(34)
    .borderRadius(Radius.pill)
    .backgroundColor(this.ui.hideAmount ? $r('app.color.brand_wash') : $r('app.color.surface'))
    .border({
      width: 1,
      color: this.ui.hideAmount ? $r('app.color.brand_soft') : $r('app.color.line')
    })
    .responseRegion({ x: -5, y: -5, width: 44, height: 44 })
    .onClick(() => {
      this.ui.hideAmount = !this.ui.hideAmount;
    })
  }
}
