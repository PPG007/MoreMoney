import { AppFont, Radius } from '../../theme/Theme';
import { OverlayColors } from '../../theme/Palette';
import { DonutSegment } from './DonutChart';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

const BASE_SIZE: number = 280;
const START_ANGLE: number = -Math.PI / 2;
const CHIP_SIZE: number = 40;

class LabelPlacement {
  segment: DonutSegment = new DonutSegment();
  x: number = 0;
  y: number = 0;
  percentX: number = 0;
  percentY: number = 0;
  percentText: string = '';
  showPercent: boolean = false;
}

@ComponentV2
export struct DonutLabels {
  @Param segments: DonutSegment[] = [];
  @Param selectedIndex: number = -1;
  @Param hidden: boolean = false;
  @Local ui: GlobalUiStore = UiStore.instance();

  private placements(): LabelPlacement[] {
    const list: LabelPlacement[] = [];
    const cx: number = BASE_SIZE / 2;
    const cy: number = BASE_SIZE / 2;
    let angle: number = START_ANGLE;
    for (let i = 0; i < this.segments.length; i++) {
      const segment: DonutSegment = this.segments[i];
      const middle: number = angle + Math.PI * segment.percent;
      const placement: LabelPlacement = new LabelPlacement();
      placement.segment = segment;
      const outerX: number = cx + Math.cos(middle) * (92 + 26);
      const outerY: number = cy + Math.sin(middle) * (92 + 26);
      placement.x = Math.min(BASE_SIZE - CHIP_SIZE - 2, Math.max(2, outerX - CHIP_SIZE / 2));
      placement.y = Math.min(BASE_SIZE - CHIP_SIZE - 2, Math.max(2, outerY - CHIP_SIZE / 2));
      const innerX: number = cx + Math.cos(middle) * 92;
      const innerY: number = cy + Math.sin(middle) * 92;
      placement.percentX = innerX;
      placement.percentY = innerY;
      placement.percentText = Math.round(segment.percent * 100).toString().concat('%');
      placement.showPercent = i < 4 && segment.percent >= 0.03 && segment.categoryId !== '__other__';
      list.push(placement);
      angle += Math.PI * 2 * segment.percent;
    }
    return list;
  }

  build() {
    Stack() {
      ForEach(this.placements(), (placement: LabelPlacement) => {
        Stack() {
          Image($r('app.media.' + placement.segment.icon))
            .width(19)
            .height(19)
            .fillColor(placement.segment.color)
        }
        .width(CHIP_SIZE)
        .height(CHIP_SIZE)
        .borderRadius(CHIP_SIZE / 2)
        .backgroundColor($r('app.color.surface'))
        .border({
          width: this.selectedIndex === this.segments.indexOf(placement.segment) ? 3 : 2,
          color: placement.segment.color
        })
        .position({ x: placement.x, y: placement.y })
      }, (placement: LabelPlacement) => placement.segment.categoryId)

      if (!this.hidden) {
        ForEach(this.placements(), (placement: LabelPlacement) => {
          if (placement.showPercent) {
            Text(placement.percentText)
              .fontSize(8)
              .fontWeight(AppFont.bold)
              .fontColor($r('app.color.on_hero'))
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .borderRadius(Radius.pill)
              .backgroundColor(OverlayColors.percentPill())
              .position({ x: placement.percentX - 12, y: placement.percentY - 8 })
          }
        }, (placement: LabelPlacement) => 'p'.concat(placement.segment.categoryId))
      }
    }
    .width(BASE_SIZE)
    .height(BASE_SIZE)
    .hitTestBehavior(HitTestMode.None)
  }
}
