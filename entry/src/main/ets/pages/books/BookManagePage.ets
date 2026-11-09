import { AppFont, Space } from '../../theme/Theme';
import { PageHeader } from '../../components/layout/PageHeader';

@Builder
export function BookManageBuilder() {
  BookManagePage();
}

@ComponentV2
export struct BookManagePage {
  stack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      Column({ space: Space.x3 }) {
        PageHeader({
          title: '账本管理',
          onBack: () => {
            this.stack.pop();
          }
        })
        Text('账本管理由 T08 实现')
          .fontSize(AppFont.caption)
          .fontColor($r('app.color.ink_3'))
          .padding({ left: Space.page, right: Space.page })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg'))
    .onReady((context: NavDestinationContext) => {
      this.stack = context.pathStack;
    })
  }
}
