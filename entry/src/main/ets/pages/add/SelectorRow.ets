import { AppFont, Radius, Space } from '../../theme/Theme';

@ComponentV2
struct SelectorItem {
  @Param icon: Resource = $r('app.media.ic_book');
  @Param label: string = '';
  @Event onTap: () => void = () => {
  };

  build() {
    Row({ space: 5 }) {
      Image(this.icon)
        .width(12)
        .height(12)
        .fillColor($r('app.color.ink_2'))
      Text(this.label)
        .fontSize(AppFont.caption)
        .fontWeight(AppFont.medium)
        .fontColor($r('app.color.ink_2'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
    }
    .height(36)
    .padding({ left: 6, right: 6 })
    .borderRadius(Radius.input)
    .backgroundColor($r('app.color.surface'))
    .border({ width: 1, color: $r('app.color.line') })
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.onTap();
    })
  }
}

@ComponentV2
export struct SelectorRow {
  @Param bookName: string = '选择账本';
  @Param memberName: string = '选择成员';
  @Param dayLabel: string = '';
  @Event onBook: () => void = () => {
  };
  @Event onMember: () => void = () => {
  };
  @Event onDate: () => void = () => {
  };

  build() {
    Row({ space: 6 }) {
      SelectorItem({
        icon: $r('app.media.ic_book'),
        label: this.bookName,
        onTap: () => {
          this.onBook();
        }
      })
      SelectorItem({
        icon: $r('app.media.ic_member'),
        label: this.memberName,
        onTap: () => {
          this.onMember();
        }
      })
      SelectorItem({
        icon: $r('app.media.ic_calendar'),
        label: this.dayLabel,
        onTap: () => {
          this.onDate();
        }
      })
    }
    .width('100%')
    .padding({ left: Space.page, right: Space.page })
  }
}
