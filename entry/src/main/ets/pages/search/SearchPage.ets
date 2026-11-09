import { AppFont, Space } from '../../theme/Theme';
import { PageHeader } from '../../components/layout/PageHeader';

@Builder
export function SearchBuilder() {
  SearchPage();
}

@ComponentV2
export struct SearchPage {
  stack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      Column({ space: Space.x3 }) {
        PageHeader({
          title: '搜索',
          onBack: () => {
            this.stack.pop();
          }
        })
        Text('全局搜索由 T18 实现')
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
