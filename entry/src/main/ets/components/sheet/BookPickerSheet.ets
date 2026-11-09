import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { Book } from '../../models/Entities';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
export struct BookPickerSheet {
  @Param visible: boolean = false;
  @Param books: Book[] = [];
  @Param selectedId: string = '';
  @Param lockedIds: string[] = [];
  @Event onSelect: (bookId: string) => void = (bookId: string) => {
  };
  @Event onClose: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();

  private isLocked(bookId: string): boolean {
    return this.lockedIds.indexOf(bookId) >= 0;
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
          Text('选择账本')
            .fontSize(AppFont.subTitle)
            .fontWeight(AppFont.bold)
            .fontColor($r('app.color.ink'))
            .width('100%')

          ForEach(this.books, (book: Book) => {
            Row({ space: 11 }) {
              Stack() {
                Image($r('app.media.' + book.icon))
                  .width(19)
                  .height(19)
                  .fillColor(book.color)
              }
              .width(34)
              .height(34)
              .borderRadius(11)
              .backgroundColor($r('app.color.surface_2'))
              Text(book.name)
                .fontSize(AppFont.row)
                .fontWeight(AppFont.semibold)
                .fontColor($r('app.color.ink'))
                .layoutWeight(1)
              if (this.isLocked(book.id)) {
                Image($r('app.media.ic_lock'))
                  .width(15)
                  .height(15)
                  .fillColor($r('app.color.warn'))
              }
              if (this.selectedId === book.id) {
                Image($r('app.media.ic_check'))
                  .width(16)
                  .height(16)
                  .fillColor($r('app.color.brand_ink'))
              }
            }
            .width('100%')
            .height(52)
            .padding({ left: 12, right: 12 })
            .borderRadius(Radius.input)
            .backgroundColor(this.selectedId === book.id ? $r('app.color.brand_wash') : Color.Transparent)
            .onClick(() => {
              this.onSelect(book.id);
            })
          }, (book: Book) => book.id)
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
