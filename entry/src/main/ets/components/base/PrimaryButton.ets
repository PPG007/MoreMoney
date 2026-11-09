import { AppFont, Radius } from '../../theme/Theme';

@ComponentV2
export struct PrimaryButton {
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
      .backgroundColor($r('app.color.btn_bg'))
      .fontColor($r('app.color.btn_fg'))
      .fontSize(AppFont.row)
      .fontWeight(AppFont.bold)
      .enabled(this.isEnabled)
      .opacity(this.isEnabled ? 1 : 0.4)
      .onClick(() => {
        if (this.isEnabled) {
          this.onTap();
        }
      })
  }
}
