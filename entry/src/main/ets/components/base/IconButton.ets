import { Radius } from '../../theme/Theme';

@ComponentV2
export struct IconButton {
  @Param icon: Resource = $r('app.media.ic_more');
  @Param buttonSize: number = 34;
  @Param iconSize: number = 17;
  @Param tint: ResourceColor = $r('app.color.ink');
  @Event onTap: () => void = () => {
  };

  build() {
    Stack() {
      Image(this.icon)
        .width(this.iconSize)
        .height(this.iconSize)
        .fillColor(this.tint)
    }
    .width(this.buttonSize)
    .height(this.buttonSize)
    .borderRadius(Radius.pill)
    .backgroundColor($r('app.color.surface'))
    .border({ width: 1, color: $r('app.color.line') })
    .responseRegion({
      x: -5,
      y: -5,
      width: this.buttonSize + 10,
      height: this.buttonSize + 10
    })
    .onClick(() => {
      this.onTap();
    })
  }
}
