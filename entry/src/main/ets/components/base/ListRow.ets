import { AppFont, Radius } from '../../theme/Theme';
import { IconSize } from '../../theme/IconSize';

@ComponentV2
export struct ListRow {
  @Param icon: Resource | undefined = undefined;
  @Param title: string = '';
  @Param subtitle: string = '';
  @Param trailingText: string = '';
  @Param showArrow: boolean = true;
  @Event onTap: () => void = () => {
  };

  build() {
    Row({ space: 11 }) {
      if (this.icon !== undefined) {
        Stack() {
          Image(this.icon)
            .width(16)
            .height(16)
            .fillColor($r('app.color.ink_2'))
        }
        .width(31)
        .height(31)
        .borderRadius(10)
        .backgroundColor($r('app.color.surface_2'))
      }

      Column({ space: 1 }) {
        Text(this.title)
          .fontSize(AppFont.settings)
          .fontWeight(AppFont.medium)
          .fontColor($r('app.color.ink'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.subtitle.length > 0) {
          Text(this.subtitle)
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.ink_3'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.trailingText.length > 0) {
        Text(this.trailingText)
          .fontSize(AppFont.caption)
          .fontColor($r('app.color.ink_3'))
      }

      if (this.showArrow) {
        Image($r('app.media.ic_chevron_right'))
          .width(IconSize.small)
          .height(IconSize.small)
          .fillColor($r('app.color.ink_3'))
      }
    }
    .width('100%')
    .constraintSize({ minHeight: 52 })
    .padding({ left: 13, right: 13, top: 11, bottom: 11 })
    .borderRadius(Radius.card)
    .onClick(() => {
      this.onTap();
    })
  }
}
