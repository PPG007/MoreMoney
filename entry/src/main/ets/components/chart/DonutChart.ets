import { ChartCanvas } from './ChartCanvas';
import { ChartColors } from './ChartColors';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

export class DonutSegment {
  categoryId: string = '';
  name: string = '';
  icon: string = '';
  cents: number = 0;
  percent: number = 0;
  color: string = '';
}

export class DonutLayout {
  radius: number = 92;
  stroke: number = 30;
  centerX: number = 140;
  centerY: number = 140;
}

const BASE_SIZE: number = 280;
const START_ANGLE: number = -Math.PI / 2;
const GAP_VP: number = 2;

@ComponentV2
export struct DonutChart {
  @Param segments: DonutSegment[] = [];
  @Param selectedIndex: number = -1;
  @Param redrawKey: number = 0;
  @Event onSelect: (index: number) => void = (index: number) => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();

  static layout(): DonutLayout {
    const layout: DonutLayout = new DonutLayout();
    layout.radius = 92;
    layout.stroke = 30;
    layout.centerX = BASE_SIZE / 2;
    layout.centerY = BASE_SIZE / 2;
    return layout;
  }

  private drawDonut(ctx: CanvasRenderingContext2D, width: number, height: number): void {
    const size: number = Math.min(width, height);
    const scale: number = size / BASE_SIZE;
    const cx: number = width / 2;
    const cy: number = height / 2;
    const radius: number = 92 * scale;
    const stroke: number = 30 * scale;
    ctx.clearRect(0, 0, width, height);
    if (this.segments.length === 0) {
      return;
    }
    ctx.lineWidth = stroke;
    ctx.lineCap = 'butt';
    const gapAngle: number = GAP_VP / radius;
    let angle: number = START_ANGLE;
    for (let i = 0; i < this.segments.length; i++) {
      const segment: DonutSegment = this.segments[i];
      const sweep: number = Math.max(0, Math.PI * 2 * segment.percent - gapAngle);
      const start: number = angle + gapAngle / 2;
      const end: number = start + sweep;
      ctx.beginPath();
      ctx.arc(cx, cy, radius, start, end);
      ctx.strokeStyle = segment.color;
      ctx.globalAlpha = this.selectedIndex >= 0 && this.selectedIndex !== i ? 0.55 : 1;
      ctx.stroke();
      angle += Math.PI * 2 * segment.percent;
    }
    ctx.globalAlpha = 1;
  }

  private hitTest(x: number, y: number): void {
    const cx: number = BASE_SIZE / 2;
    const cy: number = BASE_SIZE / 2;
    const dx: number = x - cx;
    const dy: number = y - cy;
    const dist: number = Math.sqrt(dx * dx + dy * dy);
    if (Math.abs(dist - 92) > 15 + 8) {
      this.onSelect(-1);
      return;
    }
    let angle: number = Math.atan2(dy, dx) - START_ANGLE;
    while (angle < 0) {
      angle += Math.PI * 2;
    }
    angle = angle % (Math.PI * 2);
    let cursor: number = 0;
    for (let i = 0; i < this.segments.length; i++) {
      const sweep: number = Math.PI * 2 * this.segments[i].percent;
      if (angle >= cursor && angle < cursor + sweep) {
        this.onSelect(i);
        return;
      }
      cursor += sweep;
    }
    this.onSelect(-1);
  }

  build() {
    Stack() {
      ChartCanvas({
        redrawKey: this.redrawKey + this.selectedIndex,
        onDraw: (ctx: CanvasRenderingContext2D, w: number, h: number) => {
          this.drawDonut(ctx, w, h);
        },
        onTapPoint: (x: number, y: number, w: number, h: number) => {
          this.hitTest(x, y);
        }
      })
    }
    .width(BASE_SIZE)
    .height(BASE_SIZE)
  }
}
