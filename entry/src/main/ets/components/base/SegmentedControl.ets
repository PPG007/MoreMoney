import { AppFont, Radius } from '../../theme/Theme';

@ComponentV2
export struct SegmentedControl {
  @Param options: string[] = [];
  @Param selectedIndex: number = 0;
  @Event onChange: (index: number) => void = (index: number) => {
  };

  build() {
    Row() {
      ForEach(this.options, (option: string, index: number) => {
        Text(option)
          .fontSize(AppFont.micro)
          .fontWeight(this.selectedIndex === index ? AppFont.semibold : AppFont.regular)
          .fontColor(this.selectedIndex === index ? $r('app.color.ink') : $r('app.color.ink_3'))
          .textAlign(TextAlign.Center)
          .height(30)
          .layoutWeight(1)
          .borderRadius(10)
          .backgroundColor(this.selectedIndex === index ? $r('app.color.surface') : Color.Transparent)
          .onClick(() => {
            this.onChange(index);
          })
      }, (option: string) => option)
    }
    .width('100%')
    .padding(3)
    .borderRadius(13)
    .backgroundColor($r('app.color.surface_2'))
  }
}
