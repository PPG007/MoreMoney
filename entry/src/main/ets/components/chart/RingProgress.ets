import { AppFont, Radius } from '../../theme/Theme';
import { RingColors } from '../../theme/Palette';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
export struct RingProgress {
  @Param percent: number = 0;
  @Param ringSize: number = 116;
  @Param strokeWidth: number = 11;
  @Param hideFill: boolean = false;
  @Param isExpense: boolean = false;
  @Param centerText: string = '';
  @Local ui: GlobalUiStore = UiStore.instance();
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));

  @Monitor('percent', 'hideFill', 'isExpense', 'ui.isDark')
  onValueChanged(): void {
    this.draw();
  }

  private draw(): void {
    const size: number = this.ringSize;
    const center: number = size / 2;
    const radius: number = center - this.strokeWidth / 2 - 2;
    this.ctx.clearRect(0, 0, size, size);
    this.ctx.lineWidth = this.strokeWidth;
    this.ctx.lineCap = 'round';
    this.ctx.beginPath();
    this.ctx.arc(center, center, radius, 0, Math.PI * 2);
    this.ctx.strokeStyle = RingColors.track(this.ui.isDark);
    this.ctx.stroke();
    if (this.hideFill || this.percent <= 0) {
      return;
    }
    let ratio: number = this.percent;
    if (ratio > 1) {
      ratio = 1;
    }
    const start: number = -Math.PI / 2;
    const end: number = start + Math.PI * 2 * ratio;
    this.ctx.beginPath();
    this.ctx.arc(center, center, radius, start, end);
    if (this.isExpense) {
      this.ctx.strokeStyle = RingColors.expense(this.ui.isDark);
    } else {
      const gradient: CanvasGradient = this.ctx.createLinearGradient(0, 0, size, size);
      gradient.addColorStop(0, RingColors.brandStart(this.ui.isDark));
      gradient.addColorStop(1, RingColors.brandEnd(this.ui.isDark));
      this.ctx.strokeStyle = gradient;
    }
    this.ctx.stroke();
  }

  build() {
    Stack() {
      Canvas(this.ctx)
        .width(this.ringSize)
        .height(this.ringSize)
        .onReady(() => {
          this.draw();
        })
      Text(this.centerText)
        .fontSize(AppFont.ringCenter)
        .fontWeight(AppFont.bold)
        .fontColor(this.isExpense ? $r('app.color.expense') : $r('app.color.ink'))
        .fontFeature(AppFont.tnum)
    }
    .width(this.ringSize)
    .height(this.ringSize)
    .borderRadius(Radius.pill)
  }
}
