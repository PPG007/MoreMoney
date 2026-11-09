import { Radius } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
export struct EyeButton {
  @Param hero: boolean = false;
  @Local ui: GlobalUiStore = UiStore.instance();

  private buttonSize(): number {
    return this.hero ? 36 : 34;
  }

  build() {
    Stack() {
      Image(this.ui.hideAmount ? $r('app.media.ic_eye_off') : $r('app.media.ic_eye'))
        .width(17)
        .height(17)
        .fillColor(this.hero
          ? $r('app.color.on_hero')
          : (this.ui.hideAmount ? $r('app.color.brand_ink') : $r('app.color.ink')))
    }
    .width(this.buttonSize())
    .height(this.buttonSize())
    .borderRadius(Radius.pill)
    .backgroundColor(this.hero
      ? $r('app.color.hero_glass')
      : (this.ui.hideAmount ? $r('app.color.brand_wash') : $r('app.color.surface')))
    .border({
      width: 1,
      color: this.hero
        ? $r('app.color.hero_line')
        : (this.ui.hideAmount ? $r('app.color.brand_soft') : $r('app.color.line'))
    })
    .responseRegion({ x: -5, y: -5, width: 44, height: 44 })
    .onClick(() => {
      this.ui.hideAmount = !this.ui.hideAmount;
    })
  }
}
