import { ChartColors } from './ChartColors';
import { ChartCanvas } from './ChartCanvas';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

export class TrendPoint {
  key: string = '';
  label: string = '';
  cents: number = 0;
}

const PAD_LEFT: number = 26;
const PAD_RIGHT: number = 12;
const PAD_TOP: number = 34;
const PAD_BOTTOM: number = 16;

@ComponentV2
export struct TrendChart {
  @Param points: TrendPoint[] = [];
  @Param hidden: boolean = false;
  @Param selectedIndex: number = -1;
  @Param redrawKey: number = 0;
  @Event onSelect: (index: number) => void = (index: number) => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();

  private niceMax(): number {
    let max: number = 0;
    for (const point of this.points) {
      if (point.cents > max) {
        max = point.cents;
      }
    }
    const target: number = Math.max(max, 10000);
    const exponent: number = Math.floor(Math.log10(target));
    const base: number = Math.pow(10, exponent);
    const fraction: number = target / base;
    let nice: number = 10;
    if (fraction <= 1) {
      nice = 1;
    } else if (fraction <= 2) {
      nice = 2;
    } else if (fraction <= 5) {
      nice = 5;
    }
    return nice * base;
  }

  private plotWidth(width: number): number {
    return width - PAD_LEFT - PAD_RIGHT;
  }

  private plotHeight(height: number): number {
    return height - PAD_TOP - PAD_BOTTOM;
  }

  private xOf(index: number, width: number): number {
    if (this.points.length <= 1) {
      return width / 2;
    }
    return PAD_LEFT + this.plotWidth(width) * index / (this.points.length - 1);
  }

  private yOf(cents: number, height: number): number {
    const max: number = this.niceMax();
    const ratio: number = max > 0 ? cents / max : 0;
    return PAD_TOP + this.plotHeight(height) * (1 - ratio);
  }

  private draw(ctx: CanvasRenderingContext2D, width: number, height: number): void {
    ctx.clearRect(0, 0, width, height);
    if (this.points.length === 0) {
      return;
    }
    const dark: boolean = this.ui.isDark;
    const max: number = this.niceMax();
    const bottom: number = PAD_TOP + this.plotHeight(height);

    ctx.lineWidth = 1;
    ctx.strokeStyle = ChartColors.lineSoft(dark);
    for (let i = 1; i <= 3; i++) {
      const y: number = PAD_TOP + this.plotHeight(height) * i / 4;
      ctx.beginPath();
      ctx.moveTo(PAD_LEFT, y);
      ctx.lineTo(width - PAD_RIGHT, y);
      ctx.stroke();
    }

    if (this.points.length > 1) {
      const gradient: CanvasGradient = ctx.createLinearGradient(0, PAD_TOP, 0, bottom);
      gradient.addColorStop(0, ChartColors.brandArea(dark));
      gradient.addColorStop(1, ChartColors.brandAreaEnd(dark));
      ctx.beginPath();
      ctx.moveTo(this.xOf(0, width), bottom);
      for (let i = 0; i < this.points.length; i++) {
        ctx.lineTo(this.xOf(i, width), this.yOf(this.points[i].cents, height));
      }
      ctx.lineTo(this.xOf(this.points.length - 1, width), bottom);
      ctx.closePath();
      ctx.fillStyle = gradient;
      ctx.fill();

      ctx.beginPath();
      for (let i = 0; i < this.points.length; i++) {
        const x: number = this.xOf(i, width);
        const y: number = this.yOf(this.points[i].cents, height);
        if (i === 0) {
          ctx.moveTo(x, y);
        } else {
          ctx.lineTo(x, y);
        }
      }
      ctx.lineWidth = 2;
      ctx.lineJoin = 'round';
      ctx.strokeStyle = ChartColors.brandInk(dark);
      ctx.stroke();
    }

    for (let i = 0; i < this.points.length; i++) {
      const x: number = this.xOf(i, width);
      const y: number = this.yOf(this.points[i].cents, height);
      const isLast: boolean = i === this.points.length - 1;
      ctx.beginPath();
      ctx.arc(x, y, isLast ? 4.6 : 3.4, 0, Math.PI * 2);
      ctx.fillStyle = ChartColors.surface(dark);
      ctx.fill();
      ctx.lineWidth = 2;
      ctx.strokeStyle = ChartColors.brandInk(dark);
      ctx.stroke();
    }

    if (!this.hidden) {
      let maxIndex: number = 0;
      for (let i = 1; i < this.points.length; i++) {
        if (this.points[i].cents > this.points[maxIndex].cents) {
          maxIndex = i;
        }
      }
      this.drawBubble(ctx, width, height, maxIndex, this.amountText(this.points[maxIndex].cents), false);
    }

    if (this.selectedIndex >= 0 && this.selectedIndex < this.points.length) {
      const x: number = this.xOf(this.selectedIndex, width);
      ctx.beginPath();
      ctx.moveTo(x, PAD_TOP);
      ctx.lineTo(x, bottom);
      ctx.lineWidth = 1;
      ctx.strokeStyle = ChartColors.brandSoft(dark);
      ctx.stroke();
      if (!this.hidden) {
        const point: TrendPoint = this.points[this.selectedIndex];
        this.drawBubble(ctx, width, height, this.selectedIndex,
          point.label.concat('  ').concat(this.amountText(point.cents)), true);
      }
    }

    this.drawAxisLabels(ctx, width, height);
    ctx.fillStyle = ChartColors.ink3(dark);
    ctx.font = '10px sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText('¥'.concat(this.yuanText(max)), PAD_LEFT, 18);
  }

  private drawAxisLabels(ctx: CanvasRenderingContext2D, width: number, height: number): void {
    if (this.points.length === 0) {
      return;
    }
    ctx.fillStyle = ChartColors.ink3(this.ui.isDark);
    ctx.font = '10px sans-serif';
    ctx.textAlign = 'center';
    const labelY: number = PAD_TOP + this.plotHeight(height) + 14;
    if (this.points.length <= 6) {
      for (let i = 0; i < this.points.length; i++) {
        const x: number = this.xOf(i, width);
        ctx.fillText(this.points[i].label, this.clampLabelX(x, width), labelY);
      }
      return;
    }
    const count: number = 6;
    for (let i = 0; i < count; i++) {
      const index: number = Math.round((this.points.length - 1) * i / (count - 1));
      const x: number = this.xOf(index, width);
      ctx.fillText(this.points[index].label, this.clampLabelX(x, width), labelY);
    }
  }

  private clampLabelX(x: number, width: number): number {
    const min: number = PAD_LEFT + 8;
    const max: number = width - PAD_RIGHT - 8;
    return Math.min(max, Math.max(min, x));
  }

  private amountText(cents: number): string {
    return '¥'.concat(this.yuanText(cents));
  }

  private yuanText(cents: number): string {
    const yuan: number = Math.round(cents / 100);
    return yuan.toString();
  }

  private drawBubble(ctx: CanvasRenderingContext2D, width: number, height: number, index: number,
    text: string, force: boolean): void {
    const x: number = this.xOf(index, width);
    const y: number = this.yOf(this.points[index].cents, height);
    ctx.font = 'bold 10px sans-serif';
    const textWidth: number = ctx.measureText(text).width;
    const boxWidth: number = textWidth + 12;
    const boxHeight: number = 20;
    let boxX: number = x - boxWidth / 2;
    boxX = Math.min(width - PAD_RIGHT - boxWidth, Math.max(PAD_LEFT, boxX));
    let boxY: number = y - boxHeight - 10;
    if (boxY < 2) {
      boxY = y + 10;
    }
    ctx.fillStyle = ChartColors.scrimPill(this.ui.isDark);
    ctx.fillRect(boxX, boxY, boxWidth, boxHeight);
    ctx.strokeStyle = ChartColors.line(this.ui.isDark);
    ctx.lineWidth = 1;
    ctx.strokeRect(boxX, boxY, boxWidth, boxHeight);
    ctx.fillStyle = ChartColors.ink(this.ui.isDark);
    ctx.textAlign = 'center';
    ctx.fillText(text, boxX + boxWidth / 2, boxY + 14);
    if (force) {
      ctx.beginPath();
      ctx.arc(x, y, 5, 0, Math.PI * 2);
      ctx.fillStyle = ChartColors.brandInk(this.ui.isDark);
      ctx.fill();
    }
  }

  private hitTest(x: number, width: number): void {
    if (this.points.length === 0) {
      this.onSelect(-1);
      return;
    }
    let best: number = -1;
    let bestDistance: number = 17;
    for (let i = 0; i < this.points.length; i++) {
      const distance: number = Math.abs(this.xOf(i, width) - x);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    this.onSelect(best);
  }

  build() {
    Stack() {
      ChartCanvas({
        redrawKey: this.redrawKey + this.selectedIndex,
        onDraw: (ctx: CanvasRenderingContext2D, w: number, h: number) => {
          this.draw(ctx, w, h);
        },
        onTapPoint: (x: number, y: number, w: number, h: number) => {
          this.hitTest(x, w);
        }
      })
    }
    .width('100%')
    .height('100%')
  }
}
