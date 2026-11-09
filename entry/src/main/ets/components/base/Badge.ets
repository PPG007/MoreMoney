import { AppFont, Radius } from '../../theme/Theme';
import { ToneColors } from '../../theme/Palette';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

export enum BadgeTone {
  Brand,
  Warn
}

@ComponentV2
export struct AppBadge {
  @Param text: string = '';
  @Param tone: BadgeTone = BadgeTone.Brand;
  @Local ui: GlobalUiStore = UiStore.instance();

  build() {
    Text(this.text)
      .fontSize(AppFont.micro)
      .fontWeight(AppFont.semibold)
      .fontColor(this.tone === BadgeTone.Warn ? $r('app.color.warn') : $r('app.color.brand_ink'))
      .backgroundColor(this.tone === BadgeTone.Warn ? ToneColors.warnSoft(this.ui.isDark) : $r('app.color.brand_wash'))
      .padding({ left: 6, right: 6, top: 1, bottom: 1 })
      .borderRadius(Radius.pill)
  }
}
