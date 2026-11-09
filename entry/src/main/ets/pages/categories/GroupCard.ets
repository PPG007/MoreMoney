import { AppFont, Radius, Space } from '../../theme/Theme';
import { withAlpha } from '../../theme/Palette';
import { Category, CategoryGroup } from '../../models/Entities';

export class CategoryGroupView {
  group: CategoryGroup = {
    id: '',
    name: '',
    sort: 0,
    isSystem: false
  };
  categories: Category[] = [];
}

@ComponentV2
export struct GroupCard {
  @Param data: CategoryGroupView = new CategoryGroupView();
  @Param editMode: boolean = false;
  @Event onEditGroup: (group: CategoryGroup) => void = (group: CategoryGroup) => {
  };
  @Event onDeleteGroup: (group: CategoryGroup) => void = (group: CategoryGroup) => {
  };
  @Event onEditCategory: (category: Category) => void = (category: Category) => {
  };
  @Event onDeleteCategory: (category: Category) => void = (category: Category) => {
  };
  @Event onAddCategory: (groupId: string) => void = (groupId: string) => {
  };

  @Builder
  chip(category: Category) {
    Stack({ alignContent: Alignment.TopEnd }) {
      Row({ space: 6 }) {
        Image($r('app.media.' + category.icon))
          .width(19)
          .height(19)
          .fillColor(category.color)
        Text(category.name)
          .fontSize(AppFont.caption)
          .fontWeight(AppFont.medium)
          .fontColor($r('app.color.ink'))
      }
      .padding({ left: 8, right: 10, top: 6, bottom: 6 })
      .borderRadius(Radius.pill)
      .backgroundColor($r('app.color.surface_2'))

      if (this.editMode) {
        Stack() {
          Image($r('app.media.ic_close'))
            .width(8)
            .height(8)
            .fillColor($r('app.color.surface'))
        }
        .width(15)
        .height(15)
        .borderRadius(8)
        .backgroundColor($r('app.color.expense'))
        .offset({ x: 4, y: -4 })
        .onClick(() => {
          this.onDeleteCategory(category);
        })
      }
    }
  }

  build() {
    Column({ space: Space.x3 }) {
      Row({ space: Space.x2 }) {
        Text(this.data.group.name)
          .fontSize(AppFont.settings)
          .fontWeight(AppFont.bold)
          .fontColor($r('app.color.ink'))
        Text(this.data.categories.length.toString())
          .fontSize(AppFont.caption)
          .fontColor($r('app.color.ink_3'))
        Blank()
        if (this.editMode) {
          Text('重命名')
            .fontSize(AppFont.caption)
            .fontWeight(AppFont.semibold)
            .fontColor($r('app.color.brand_ink'))
            .padding({ left: 6, right: 6, top: 3, bottom: 3 })
            .onClick(() => {
              this.onEditGroup(this.data.group);
            })
          if (!this.data.group.isSystem) {
            Text('删除')
              .fontSize(AppFont.caption)
              .fontWeight(AppFont.semibold)
              .fontColor($r('app.color.expense'))
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })
              .onClick(() => {
                this.onDeleteGroup(this.data.group);
              })
          }
        } else {
          Text('编辑')
            .fontSize(AppFont.caption)
            .fontWeight(AppFont.semibold)
            .fontColor($r('app.color.brand_ink'))
            .onClick(() => {
              this.onEditGroup(this.data.group);
            })
        }
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.data.categories, (category: Category) => {
          Row() {
            this.chip(category)
          }
          .margin({ right: 8, bottom: 8 })
          .onClick(() => {
            if (this.editMode) {
              this.onEditCategory(category);
            }
          })
        }, (category: Category) => category.id)
        Row({ space: 4 }) {
          Text('+')
            .fontSize(AppFont.legend)
            .fontWeight(AppFont.bold)
            .fontColor($r('app.color.ink_3'))
          Text('新建分类')
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.ink_3'))
        }
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .borderRadius(Radius.pill)
        .border({ width: 1, color: $r('app.color.line'), style: BorderStyle.Dashed })
        .margin({ right: 8, bottom: 8 })
        .onClick(() => {
          this.onAddCategory(this.data.group.id);
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(13)
    .borderRadius(Radius.cardSm)
    .backgroundColor($r('app.color.surface'))
    .border({ width: 1, color: $r('app.color.line') })
  }
}
