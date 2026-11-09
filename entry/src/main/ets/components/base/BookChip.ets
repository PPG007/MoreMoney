import { AppFont, Radius } from '../../theme/Theme';
import { Book } from '../../models/Entities';

@ComponentV2
export struct BookChip {
  @Param book: Book | null = null;
  @Param label: string = '';
  @Param isSelected: boolean = false;
  @Param isLocked: boolean = false;
  @Param onHero: boolean = false;
  @Event onTap: () => void = () => {
  };

  build() {
    Row({ space: 6 }) {
      if (this.book !== null) {
        Image($r('app.media.' + this.book.icon))
          .width(22)
          .height(22)
          .fillColor($r('app.color.on_hero'))
          .borderRadius(7)
          .backgroundColor($r('app.color.hero_glass'))
          .padding(4)
      }
      Text(this.label)
        .fontSize(AppFont.micro)
        .fontWeight(AppFont.semibold)
        .fontColor(this.onHero ? $r('app.color.on_hero') : $r('app.color.ink'))
        .maxLines(1)
      if (this.isLocked) {
        Image($r('app.media.ic_lock'))
          .width(12)
          .height(12)
          .fillColor(this.onHero ? $r('app.color.on_hero') : $r('app.color.warn'))
      }
    }
    .height(34)
    .padding({ left: 6, right: 10, top: 6, bottom: 6 })
    .borderRadius(Radius.chip)
    .backgroundColor(this.isSelected
      ? (this.onHero ? $r('app.color.hero_glass') : $r('app.color.brand_wash'))
      : Color.Transparent)
    .border({
      width: 1,
      color: this.onHero
        ? $r('app.color.hero_line')
        : (this.isSelected ? $r('app.color.brand_soft') : $r('app.color.line'))
    })
    .onClick(() => {
      this.onTap();
    })
  }
}
