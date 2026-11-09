import { AppFont, Radius, Space } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

export class AddTxnParam {
  bookId: string = '';
  dayKey: string = '';
}

@Builder
export function AddTxnBuilder() {
  AddTxnPage();
}

@ComponentV2
export struct AddTxnPage {
  stack: NavPathStack = new NavPathStack();
  @Local param: AddTxnParam = new AddTxnParam();
  @Local ui: GlobalUiStore = UiStore.instance();

  build() {
    NavDestination() {
      Column({ space: Space.x3 }) {
        Row() {
          Blank()
          Stack() {
            Image($r('app.media.ic_close'))
              .width(17)
              .height(17)
              .fillColor($r('app.color.ink'))
          }
          .width(34)
          .height(34)
          .borderRadius(Radius.pill)
          .backgroundColor($r('app.color.surface'))
          .border({ width: 1, color: $r('app.color.line') })
          .onClick(() => {
            this.stack.pop();
          })
        }
        .width('100%')

        Text('记一笔（占位）')
          .fontSize(AppFont.pageTitle)
          .fontWeight(AppFont.bold)
          .fontColor($r('app.color.ink'))

        Text('账本：' + this.param.bookId + '　日期：' + this.param.dayKey)
          .fontSize(AppFont.caption)
          .fontColor($r('app.color.ink_3'))

        Text('记一笔面板由 T07 实现')
          .fontSize(AppFont.caption)
          .fontColor($r('app.color.ink_3'))
      }
      .width('100%')
      .height('100%')
      .padding({
        left: Space.page,
        right: Space.page,
        top: Space.x3 + this.ui.topInset
      })
      .alignItems(HorizontalAlign.Start)
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg'))
    .onReady((context: NavDestinationContext) => {
      this.stack = context.pathStack;
      if (context.pathInfo.param instanceof AddTxnParam) {
        this.param = context.pathInfo.param;
      }
    })
  }
}
