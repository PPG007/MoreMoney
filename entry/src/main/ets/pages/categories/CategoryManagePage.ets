import { AppFont, Space } from '../../theme/Theme';
import { PageHeader } from '../../components/layout/PageHeader';

@Builder
export function CategoryManageBuilder() {
  CategoryManagePage();
}

@ComponentV2
export struct CategoryManagePage {
  stack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      Column({ space: Space.x3 }) {
        PageHeader({
          title: '分类管理',
          onBack: () => {
            this.stack.pop();
          }
        })
        Text('分类管理由 T10 实现')
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
