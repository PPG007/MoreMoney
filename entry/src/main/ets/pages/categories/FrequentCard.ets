import { AppFont, Radius, Space } from '../../theme/Theme';
import { withAlpha } from '../../theme/Palette';
import { Category } from '../../models/Entities';
import { AppBadge } from '../../components/base/Badge';

@ComponentV2
export struct FrequentCard {
  @Param categories: Category[] = [];
  @Event onEditCategory: (category: Category) => void = (category: Category) => {
  };

  @Builder
  chip(category: Category) {
    Row({ space: 6 }) {
      Image($r('app.media.' + category.icon))
        .width(21)
        .height(21)
        .fillColor(category.color)
        .borderRadius(7)
        .padding(3)
        .backgroundColor(withAlpha(category.color, 0.13))
      Text(category.name)
        .fontSize(AppFont.caption)
        .fontWeight(AppFont.medium)
        .fontColor($r('app.color.ink'))
    }
    .padding({ left: 8, right: 11, top: 6, bottom: 6 })
    .borderRadius(Radius.pill)
    .backgroundColor($r('app.color.surface_2'))
    .onClick(() => {
      this.onEditCategory(category);
    })
  }

  build() {
    Column({ space: Space.x3 }) {
      Row({ space: Space.x2 }) {
        Text('常用')
          .fontSize(AppFont.settings)
          .fontWeight(AppFont.bold)
          .fontColor($r('app.color.ink'))
        AppBadge({ text: '动态' })
      }
      .width('100%')

      if (this.categories.length === 0) {
        Text('还没有常用分类')
          .fontSize(AppFont.caption)
          .fontColor($r('app.color.ink_3'))
      } else {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.categories, (category: Category) => {
            Row() {
              this.chip(category)
            }
            .margin({ right: 8, bottom: 8 })
          }, (category: Category) => category.id)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(14)
    .borderRadius(Radius.card)
    .backgroundColor($r('app.color.surface'))
    .border({ width: 1, color: $r('app.color.line') })
  }
}
