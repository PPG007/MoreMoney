import { AppFont, Space } from '../../theme/Theme';
import { PageHeader } from '../../components/layout/PageHeader';

@Builder
export function DataBackupBuilder() {
  DataBackupPage();
}

@ComponentV2
export struct DataBackupPage {
  stack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      Column({ space: Space.x3 }) {
        PageHeader({
          title: '数据与备份',
          onBack: () => {
            this.stack.pop();
          }
        })
        Text('数据导入导出与备份由 T19–T22 实现')
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
