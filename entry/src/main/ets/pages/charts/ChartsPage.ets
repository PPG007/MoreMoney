import { AppFont, Radius, Space } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
export struct ChartsPage {
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local segment: number = 0;
  private segments: string[] = ['分类', '趋势', '日历'];

  build() {
    Column({ space: Space.x4 }) {
      Text('图表')
        .fontSize(AppFont.pageTitle)
        .fontWeight(AppFont.bold)
        .fontColor($r('app.color.ink'))

      Row() {
        ForEach(this.segments, (item: string, index: number) => {
          Text(item)
            .fontSize(AppFont.micro)
            .fontWeight(this.segment === index ? AppFont.semibold : AppFont.regular)
            .fontColor(this.segment === index ? $r('app.color.brand_ink') : $r('app.color.ink_3'))
            .textAlign(TextAlign.Center)
            .height(30)
            .layoutWeight(1)
            .borderRadius(10)
            .backgroundColor(this.segment === index ? $r('app.color.surface') : Color.Transparent)
            .onClick(() => {
              this.segment = index;
            })
        }, (item: string) => item)
      }
      .width('100%')
      .padding(3)
      .borderRadius(Radius.chip)
      .backgroundColor($r('app.color.surface_2'))

      Text('分类环形图、趋势折线、日历热力由 T15–T17 实现')
        .fontSize(AppFont.caption)
        .fontColor($r('app.color.ink_3'))
    }
    .width('100%')
    .height('100%')
    .padding({
      left: Space.page,
      right: Space.page,
      top: this.ui.topInset + 10
    })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('app.color.bg'))
  }
}
