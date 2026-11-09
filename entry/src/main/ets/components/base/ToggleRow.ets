import { AppFont } from '../../theme/Theme';

@ComponentV2
export struct ToggleRow {
  @Param title: string = '';
  @Param subtitle: string = '';
  @Param isOn: boolean = false;
  @Event onChange: (isOn: boolean) => void = (isOn: boolean) => {
  };

  build() {
    Row({ space: 11 }) {
      Column({ space: 1 }) {
        Text(this.title)
          .fontSize(AppFont.settings)
          .fontWeight(AppFont.medium)
          .fontColor($r('app.color.ink'))
        if (this.subtitle.length > 0) {
          Text(this.subtitle)
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.ink_3'))
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: this.isOn })
        .selectedColor($r('app.color.btn_bg'))
        .switchPointColor($r('app.color.surface'))
        .onChange((isOn: boolean) => {
          this.onChange(isOn);
        })
    }
    .width('100%')
    .constraintSize({ minHeight: 52 })
    .padding({ left: 13, right: 13, top: 11, bottom: 11 })
    .alignItems(VerticalAlign.Center)
  }
}
