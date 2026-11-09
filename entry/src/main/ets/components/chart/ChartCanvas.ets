@ComponentV2
export struct ChartCanvas {
  @Param redrawKey: number = 0;
  @Event onDraw: (ctx: CanvasRenderingContext2D, w: number, h: number) => void =
    (ctx: CanvasRenderingContext2D, w: number, h: number) => {
    };
  @Event onTapPoint: (x: number, y: number, w: number, h: number) => void =
    (x: number, y: number, w: number, h: number) => {
    };
  @Local canvasWidth: number = 0;
  @Local canvasHeight: number = 0;
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));

  @Monitor('redrawKey')
  onRedrawRequested(): void {
    this.redraw();
  }

  private redraw(): void {
    if (this.canvasWidth <= 0 || this.canvasHeight <= 0) {
      return;
    }
    this.ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
    this.onDraw(this.ctx, this.canvasWidth, this.canvasHeight);
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height('100%')
      .onReady(() => {
        this.redraw();
      })
      .onAreaChange((oldValue: Area, newValue: Area) => {
        this.canvasWidth = Number(newValue.width);
        this.canvasHeight = Number(newValue.height);
        this.redraw();
      })
      .onClick((event: ClickEvent) => {
        this.onTapPoint(event.x, event.y, this.canvasWidth, this.canvasHeight);
      })
  }
}
