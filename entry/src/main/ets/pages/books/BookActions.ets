import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { Book } from '../../models/Entities';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
export struct BookActions {
  @Param visible: boolean = false;
  @Param book: Book | null = null;
  @Param canDelete: boolean = true;
  @Event onSetDefault: (bookId: string) => void = (bookId: string) => {
  };
  @Event onArchive: (bookId: string) => void = (bookId: string) => {
  };
  @Event onDelete: (bookId: string) => void = (bookId: string) => {
  };
  @Event onClose: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();

  private bookId(): string {
    return this.book === null ? '' : this.book.id;
  }

  private bookName(): string {
    return this.book === null ? '' : this.book.name;
  }

  private isDefault(): boolean {
    return this.book === null ? false : this.book.isDefault;
  }

  @Builder
  actionRow(label: string, color: ResourceColor, enabled: boolean, note: string, onTap: () => void) {
    Column({ space: 2 }) {
      Text(label)
        .fontSize(AppFont.row)
        .fontWeight(AppFont.medium)
        .fontColor(color)
        .opacity(enabled ? 1 : 0.35)
      if (note.length > 0) {
        Text(note)
          .fontSize(AppFont.micro)
          .fontColor($r('app.color.ink_3'))
      }
    }
    .width('100%')
    .height(note.length > 0 ? 56 : 50)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (enabled) {
        onTap();
      }
    })
  }

  build() {
    if (this.visible && this.book !== null) {
      Stack({ alignContent: Alignment.Bottom }) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.scrim'))
          .onClick(() => {
            this.onClose();
          })

        Column() {
          Row() {
            Text(this.bookName())
              .fontSize(AppFont.body)
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
          .height(52)
          .padding({ left: 16, right: 16 })
          .border({ width: { bottom: 1 }, color: $r('app.color.line') })

          if (!this.isDefault()) {
            this.actionRow('设为默认', $r('app.color.ink'), true, '', () => {
              this.onSetDefault(this.bookId());
            })
          }
          this.actionRow('归档', $r('app.color.ink'), true, '归档后不再出现在记账和统计中', () => {
            this.onArchive(this.bookId());
          })
          this.actionRow('删除', $r('app.color.expense'), this.canDelete,
            this.canDelete ? '' : '该账本已有流水，请使用归档', () => {
              this.onDelete(this.bookId());
            })
        }
        .width('100%')
        .padding({ bottom: Space.x8 + 10 })
        .borderRadius({ topLeft: Radius.sheet, topRight: Radius.sheet })
        .backgroundColor($r('app.color.surface'))
        .shadow(Shadow.sheet(this.ui.isDark))
      }
      .width('100%')
      .height('100%')
    }
  }
}
