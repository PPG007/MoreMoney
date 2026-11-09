import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { ChartPalette, SeedColors } from '../../theme/Palette';
import { CategoryGroup } from '../../models/Entities';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { PrimaryButton } from '../../components/base/PrimaryButton';

export class CategoryDraft {
  id: string = '';
  name: string = '';
  groupId: string = '';
  icon: string = 'ic_cat_other';
  color: string = SeedColors.neutral;
}

class CategoryIconOption {
  name: string = '';
}

class CategoryColorOption {
  value: string = '';
}

@ComponentV2
export struct CategoryEditSheet {
  @Param visible: boolean = false;
  @Param isEdit: boolean = false;
  @Param initialId: string = '';
  @Param initialName: string = '';
  @Param initialGroupId: string = '';
  @Param initialIcon: string = 'ic_cat_other';
  @Param initialColor: string = SeedColors.neutral;
  @Param groups: CategoryGroup[] = [];
  @Event onSave: (draft: CategoryDraft) => void = (draft: CategoryDraft) => {
  };
  @Event onClose: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local name: string = '';
  @Local groupId: string = '';
  @Local icon: string = 'ic_cat_other';
  @Local color: string = SeedColors.neutral;
  @Local errorText: string = '';

  @Monitor('visible')
  onVisibleChanged(): void {
    if (this.visible) {
      this.name = this.initialName;
      this.groupId = this.initialGroupId.length > 0
        ? this.initialGroupId
        : (this.groups.length > 0 ? this.groups[0].id : '');
      this.icon = this.initialIcon;
      this.color = this.initialColor;
      this.errorText = '';
    }
  }

  private icons(): CategoryIconOption[] {
    const names: string[] = ['ic_cat_food', 'ic_cat_transport', 'ic_cat_home', 'ic_cat_shopping',
      'ic_cat_entertain', 'ic_cat_medical', 'ic_cat_study', 'ic_cat_water', 'ic_cat_phone',
      'ic_cat_other', 'ic_cat_repair', 'ic_cat_travel', 'ic_cat_power'];
    const list: CategoryIconOption[] = [];
    for (const name of names) {
      const option: CategoryIconOption = new CategoryIconOption();
      option.name = name;
      list.push(option);
    }
    return list;
  }

  private colors(): CategoryColorOption[] {
    const values: string[] = [];
    for (let i = 0; i < ChartPalette.slotCount; i++) {
      values.push(ChartPalette.slot(i, this.ui.isDark));
    }
    values.push(SeedColors.c6);
    values.push(SeedColors.c7);
    values.push(SeedColors.c8);
    const list: CategoryColorOption[] = [];
    for (const value of values) {
      const option: CategoryColorOption = new CategoryColorOption();
      option.value = value;
      list.push(option);
    }
    return list;
  }

  private submit(): void {
    const trimmed: string = this.name.trim();
    if (trimmed.length === 0) {
      this.errorText = '请输入分类名称';
      return;
    }
    if (trimmed.length > 8) {
      this.errorText = '名称最多 8 个字';
      return;
    }
    if (this.groupId.length === 0) {
      this.errorText = '请选择分组';
      return;
    }
    const draft: CategoryDraft = new CategoryDraft();
    draft.id = this.initialId;
    draft.name = trimmed;
    draft.groupId = this.groupId;
    draft.icon = this.icon;
    draft.color = this.color;
    this.onSave(draft);
  }

  build() {
    if (this.visible) {
      Stack({ alignContent: Alignment.Bottom }) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.scrim'))
          .onClick(() => {
            this.onClose();
          })

        Scroll() {
          Column({ space: Space.x4 }) {
            Row() {
              Text(this.isEdit ? '编辑分类' : '新建分类')
                .fontSize(AppFont.subTitle)
                .fontWeight(AppFont.bold)
                .fontColor($r('app.color.ink'))
                .layoutWeight(1)
              Text('取消')
                .fontSize(AppFont.settings)
                .fontColor($r('app.color.ink_3'))
                .onClick(() => {
                  this.onClose();
                })
            }
            .width('100%')

            Row({ space: 11 }) {
              Stack() {
                Image($r('app.media.' + this.icon))
                  .width(24)
                  .height(24)
                  .fillColor(this.color)
              }
              .width(44)
              .height(44)
              .borderRadius(Radius.icon)
              .backgroundColor($r('app.color.surface_2'))
              TextInput({ text: this.name, placeholder: '分类名称' })
                .layoutWeight(1)
                .height(44)
                .fontSize(AppFont.row)
                .fontColor($r('app.color.ink'))
                .placeholderColor($r('app.color.ink_3'))
                .backgroundColor($r('app.color.surface_2'))
                .borderRadius(Radius.input)
                .maxLength(8)
                .onChange((value: string) => {
                  this.name = value;
                  this.errorText = '';
                })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            if (this.errorText.length > 0) {
              Text(this.errorText)
                .fontSize(AppFont.micro)
                .fontColor($r('app.color.expense'))
                .width('100%')
            }

            Column({ space: 8 }) {
              Text('分组')
                .fontSize(AppFont.micro)
                .fontColor($r('app.color.ink_3'))
                .width('100%')
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.groups, (group: CategoryGroup) => {
                  Text(group.name)
                    .fontSize(AppFont.caption)
                    .fontWeight(AppFont.medium)
                    .fontColor(this.groupId === group.id ? $r('app.color.brand_ink') : $r('app.color.ink_2'))
                    .padding({ left: 11, right: 11, top: 6, bottom: 6 })
                    .borderRadius(Radius.pill)
                    .backgroundColor(this.groupId === group.id ? $r('app.color.brand_wash') : $r('app.color.surface_2'))
                    .margin({ right: 8, bottom: 8 })
                    .onClick(() => {
                      this.groupId = group.id;
                    })
                }, (group: CategoryGroup) => group.id)
              }
              .width('100%')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            Column({ space: 8 }) {
              Text('图标')
                .fontSize(AppFont.micro)
                .fontColor($r('app.color.ink_3'))
                .width('100%')
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.icons(), (option: CategoryIconOption) => {
                  Stack() {
                    Image($r('app.media.' + option.name))
                      .width(22)
                      .height(22)
                      .fillColor(this.icon === option.name ? this.color : $r('app.color.ink_2'))
                  }
                  .width(42)
                  .height(42)
                  .borderRadius(Radius.icon)
                  .backgroundColor($r('app.color.surface_2'))
                  .border({
                    width: 2,
                    color: this.icon === option.name ? $r('app.color.brand_ink') : Color.Transparent
                  })
                  .margin({ right: 8, bottom: 8 })
                  .onClick(() => {
                    this.icon = option.name;
                  })
                }, (option: CategoryIconOption) => option.name)
              }
              .width('100%')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            Column({ space: 8 }) {
              Text('颜色')
                .fontSize(AppFont.micro)
                .fontColor($r('app.color.ink_3'))
                .width('100%')
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.colors(), (option: CategoryColorOption) => {
                  Stack() {
                    if (this.color === option.value) {
                      Image($r('app.media.ic_check'))
                        .width(15)
                        .height(15)
                        .fillColor($r('app.color.surface'))
                    }
                  }
                  .width(34)
                  .height(34)
                  .borderRadius(17)
                  .backgroundColor(option.value)
                  .border({
                    width: 2,
                    color: this.color === option.value ? $r('app.color.ink') : Color.Transparent
                  })
                  .margin({ right: 10, bottom: 8 })
                  .onClick(() => {
                    this.color = option.value;
                  })
                }, (option: CategoryColorOption) => option.value)
              }
              .width('100%')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            PrimaryButton({
              label: '保存',
              onTap: () => {
                this.submit();
              }
            })
          }
          .width('100%')
          .padding({ left: Space.x7, right: Space.x7, top: 22, bottom: Space.x8 + 10 })
        }
        .width('100%')
        .constraintSize({ maxHeight: '82%' })
        .borderRadius({ topLeft: Radius.sheet, topRight: Radius.sheet })
        .backgroundColor($r('app.color.surface'))
        .shadow(Shadow.sheet(this.ui.isDark))
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
    }
  }
}
