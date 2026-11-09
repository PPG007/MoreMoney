import { AppFont, Radius } from '../../theme/Theme';

@ComponentV2
export struct SecondaryButton {
  @Param label: string = '';
  @Param isEnabled: boolean = true;
  @Event onTap: () => void = () => {
  };

  build() {
    Button(this.label, { type: ButtonType.Normal })
      .type(ButtonType.Normal)
      .width('100%')
      .height(46)
      .borderRadius(Radius.button)
      .backgroundColor($r('app.color.surface'))
      .fontColor($r('app.color.ink'))
      .fontSize(AppFont.settings)
      .fontWeight(AppFont.semibold)
      .enabled(this.isEnabled)
      .opacity(this.isEnabled ? 1 : 0.4)
      .border({ width: 1, color: $r('app.color.line') })
      .onClick(() => {
        if (this.isEnabled) {
          this.onTap();
        }
      })
  }
}
