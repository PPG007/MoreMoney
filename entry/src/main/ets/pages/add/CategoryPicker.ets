import { AppFont, Radius, Space } from '../../theme/Theme';
import { Category } from '../../models/Entities';
import { withAlpha } from '../../theme/Palette';

export class CategoryGroupData {
  groupId: string = '';
  name: string = '';
  hint: string = '';
  categories: Category[] = [];
}

@ComponentV2
export struct CategoryPicker {
  @Param groups: CategoryGroupData[] = [];
  @Param selectedId: string = '';
  @Event onSelect: (categoryId: string) => void = (categoryId: string) => {
  };

  @Builder
  groupHeader(group: CategoryGroupData) {
    Row({ space: Space.x2 }) {
      Text(group.name)
        .fontSize(AppFont.legend)
        .fontWeight(AppFont.bold)
        .fontColor($r('app.color.ink'))
      Blank()
      Text(group.hint)
        .fontSize(AppFont.caption)
        .fontColor($r('app.color.ink_3'))
    }
    .width('100%')
    .padding({ left: 2, right: 2, top: 8, bottom: 6 })
    .backgroundColor($r('app.color.bg'))
  }

  @Builder
  categoryButton(category: Category) {
    Column({ space: 5 }) {
      Stack() {
        Image($r('app.media.' + category.icon))
          .width(26)
          .height(26)
          .fillColor(category.color)
      }
      .width(52)
      .height(52)
      .borderRadius(Radius.icon)
      .backgroundColor(withAlpha(category.color, 0.13))
      .border({
        width: this.selectedId === category.id ? 2 : 0,
        color: $r('app.color.brand_soft')
      })
      Text(category.name)
        .fontSize(AppFont.caption)
        .fontWeight(AppFont.medium)
        .fontColor(this.selectedId === category.id ? $r('app.color.brand_ink') : $r('app.color.ink_2'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('25%')
    .constraintSize({ minHeight: 78 })
    .padding({ left: 2, right: 2, top: 7, bottom: 7 })
    .borderRadius(Radius.chip)
    .backgroundColor(this.selectedId === category.id ? $r('app.color.surface') : Color.Transparent)
    .border({
      width: this.selectedId === category.id ? 1 : 0,
      color: $r('app.color.brand_ink')
    })
    .onClick(() => {
      this.onSelect(category.id);
    })
  }

  build() {
    List() {
      ForEach(this.groups, (group: CategoryGroupData) => {
        ListItemGroup({ header: this.groupHeader(group) }) {
          ListItem() {
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(group.categories, (category: Category) => {
                this.categoryButton(category)
              }, (category: Category) => category.id)
            }
            .width('100%')
          }
        }
      }, (group: CategoryGroupData) => group.groupId)
    }
    .width('100%')
    .height('100%')
    .padding({ left: Space.page, right: Space.page })
    .sticky(StickyStyle.Header)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}
