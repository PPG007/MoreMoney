import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { ImportError, ImportPreview } from '../../service/CsvImportService';
import { PrimaryButton } from '../../components/base/PrimaryButton';
import { SecondaryButton } from '../../components/base/SecondaryButton';

@ComponentV2
export struct ImportPreviewSheet {
  @Param visible: boolean = false;
  @Param preview: ImportPreview | null = null;
  @Param busy: boolean = false;
  @Event onConfirm: () => void = () => {
  };
  @Event onClose: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();

  private totalText(): string {
    return this.preview === null ? '0' : this.preview.total.toString();
  }

  private insertText(): string {
    return this.preview === null ? '0' : this.preview.toInsert.toString();
  }

  private duplicateText(): string {
    return this.preview === null ? '0' : this.preview.duplicates.toString();
  }

  private errorCount(): number {
    return this.preview === null ? 0 : this.preview.errors.length;
  }

  private newBooks(): string[] {
    return this.preview === null ? [] : this.preview.newBooks;
  }

  private newCategories(): string[] {
    return this.preview === null ? [] : this.preview.newCategories;
  }

  private newMembers(): string[] {
    return this.preview === null ? [] : this.preview.newMembers;
  }

  private errors(): ImportError[] {
    return this.preview === null ? [] : this.preview.errors;
  }

  private canConfirm(): boolean {
    return this.preview !== null && this.errorCount() === 0 && this.preview.toInsert > 0 && !this.busy;
  }

  @Builder
  stat(label: string, value: string) {
    Column({ space: 2 }) {
      Text(value)
        .fontSize(AppFont.subTitle)
        .fontWeight(AppFont.bold)
        .fontColor($r('app.color.ink'))
      Text(label)
        .fontSize(AppFont.caption)
        .fontColor($r('app.color.ink_3'))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  chipList(label: string, items: string[]) {
    if (items.length > 0) {
      Column({ space: 5 }) {
        Text(label)
          .fontSize(AppFont.micro)
          .fontColor($r('app.color.ink_3'))
          .width('100%')
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(items, (item: string) => {
            Text(item)
              .fontSize(AppFont.caption)
              .fontColor($r('app.color.brand_ink'))
              .padding({ left: 9, right: 9, top: 4, bottom: 4 })
              .borderRadius(Radius.pill)
              .backgroundColor($r('app.color.brand_wash'))
              .margin({ right: 6, bottom: 6 })
          }, (item: string) => item)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
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

        Column({ space: Space.x3 }) {
          Row() {
            Text('导入预览')
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

          Row() {
            this.stat('总行数', this.totalText())
            this.stat('可导入', this.insertText())
            this.stat('重复', this.duplicateText())
            this.stat('错误', this.errorCount().toString())
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 })
          .borderRadius(Radius.card)
          .backgroundColor($r('app.color.surface_2'))

          this.chipList('新账本', this.newBooks())
          this.chipList('新分类', this.newCategories())
          this.chipList('新成员', this.newMembers())

          if (this.errors().length > 0) {
            Column({ space: 5 }) {
              Text('错误列表')
                .fontSize(AppFont.micro)
                .fontWeight(AppFont.semibold)
                .fontColor($r('app.color.expense'))
                .width('100%')
              List() {
                ForEach(this.errors().slice(0, 10), (error: ImportError) => {
                  ListItem() {
                    Text('第 '.concat(error.line.toString()).concat(' 行：').concat(error.message))
                      .fontSize(AppFont.caption)
                      .fontColor($r('app.color.expense'))
                      .width('100%')
                  }
                }, (error: ImportError) => error.line.toString().concat(error.message))
              }
              .width('100%')
              .height(Math.min(140, this.errors().length * 24))
              .scrollBar(BarState.Auto)
              if (this.errors().length > 10) {
                Text('还有 '.concat((this.errors().length - 10).toString()).concat(' 条'))
                  .fontSize(AppFont.micro)
                  .fontColor($r('app.color.ink_3'))
                  .width('100%')
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }

          PrimaryButton({
            label: this.busy ? '导入中…' : '确认导入',
            isEnabled: this.canConfirm(),
            onTap: () => {
              if (this.canConfirm()) {
                this.onConfirm();
              }
            }
          })
          SecondaryButton({
            label: '取消',
            onTap: () => {
              this.onClose();
            }
          })
        }
        .width('100%')
        .padding({ left: Space.x7, right: Space.x7, top: 22, bottom: Space.x8 + 10 })
        .borderRadius({ topLeft: Radius.sheet, topRight: Radius.sheet })
        .backgroundColor($r('app.color.surface'))
        .shadow(Shadow.sheet(this.ui.isDark))
      }
      .width('100%')
      .height('100%')
    }
  }
}
