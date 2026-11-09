import { AppFont, Radius, Space } from '../../theme/Theme';
import { withAlpha } from '../../theme/Palette';
import { DonutSegment } from '../../components/chart/DonutChart';
import { MoneyText, MoneyTone } from '../../components/base/MoneyText';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
export struct ChartLegend {
  @Param segments: DonutSegment[] = [];
  @Param selectedIndex: number = -1;
  @Event onSelect: (index: number) => void = (index: number) => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();

  private percentText(segment: DonutSegment): string {
    return Math.round(segment.percent * 100).toString().concat('%');
  }

  build() {
    Column() {
      ForEach(this.segments, (segment: DonutSegment, index: number) => {
        Row({ space: 9 }) {
          Row()
            .width(8)
            .height(8)
            .borderRadius(4)
            .backgroundColor(segment.color)
          Stack() {
            Image($r('app.media.' + segment.icon))
              .width(15)
              .height(15)
              .fillColor(segment.color)
          }
          .width(28)
          .height(28)
          .borderRadius(8)
          .backgroundColor(withAlpha(segment.color, 0.13))

          Text(segment.name)
            .fontSize(AppFont.legend)
            .fontWeight(AppFont.medium)
            .fontColor($r('app.color.ink'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (!this.ui.hideAmount) {
            Text(this.percentText(segment))
              .fontSize(AppFont.caption)
              .fontColor($r('app.color.ink_3'))
          }
          MoneyText({
            cents: segment.cents,
            fontSize: AppFont.settings,
            weight: AppFont.bold,
            tone: MoneyTone.Ink
          })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 9, bottom: 9 })
        .borderRadius(Radius.chip)
        .backgroundColor(this.selectedIndex === index ? $r('app.color.brand_wash') : Color.Transparent)
        .onClick(() => {
          this.onSelect(index);
        })
      }, (segment: DonutSegment) => segment.categoryId)
    }
    .width('100%')
  }
}
