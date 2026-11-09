import { Radius } from '../../theme/Theme';
import { LineColors } from '../../theme/Palette';
import { Shadow } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
export struct AppCard {
  @Param contentPadding: number = 19;
  @BuilderParam content: () => void = this.defaultContent;
  @Local ui: GlobalUiStore = UiStore.instance();

  @Builder
  defaultContent() {
  }

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .padding(this.contentPadding)
    .borderRadius(Radius.cardLg)
    .backgroundColor($r('app.color.surface'))
    .border({ width: 1, color: LineColors.cardBorder(this.ui.isDark) })
    .shadow(Shadow.card(this.ui.isDark))
  }
}
