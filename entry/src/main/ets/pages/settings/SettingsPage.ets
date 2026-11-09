import { AppFont, Radius, Space } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { AddTxnParam } from '../add/AddTxnPage';

class DebugRoute {
  name: string = '';
  label: string = '';
}

@ComponentV2
export struct SettingsPage {
  @Param stack: NavPathStack = new NavPathStack();
  @Local ui: GlobalUiStore = UiStore.instance();
  private routes: DebugRoute[] = [];

  aboutToAppear(): void {
    this.routes = SettingsPage.buildRoutes();
  }

  private static buildRoutes(): DebugRoute[] {
    const list: DebugRoute[] = [];
    SettingsPage.pushRoute(list, 'BookManage', '账本管理');
    SettingsPage.pushRoute(list, 'CategoryManage', '分类管理');
    SettingsPage.pushRoute(list, 'MemberManage', '成员管理');
    SettingsPage.pushRoute(list, 'DataBackup', '数据与备份');
    SettingsPage.pushRoute(list, 'Search', '搜索');
    SettingsPage.pushRoute(list, 'AddTxn', '记一笔');
    return list;
  }

  private static pushRoute(list: DebugRoute[], name: string, label: string): void {
    const route: DebugRoute = new DebugRoute();
    route.name = name;
    route.label = label;
    list.push(route);
  }

  private open(route: DebugRoute): void {
    if (route.name === 'AddTxn') {
      this.stack.pushPathByName(route.name, new AddTxnParam());
    } else {
      this.stack.pushPathByName(route.name, '');
    }
  }

  build() {
    Column({ space: Space.x5 }) {
      Text('设置')
        .fontSize(AppFont.pageTitle)
        .fontWeight(AppFont.bold)
        .fontColor($r('app.color.ink'))

      Text('设置页由 T22 实现，以下为二级页路由自检入口')
        .fontSize(AppFont.caption)
        .fontColor($r('app.color.ink_3'))

      Column() {
        ForEach(this.routes, (route: DebugRoute) => {
          Row() {
            Text(route.label)
              .fontSize(AppFont.settings)
              .fontWeight(AppFont.medium)
              .fontColor($r('app.color.ink'))
              .layoutWeight(1)
            Image($r('app.media.ic_chevron_right'))
              .width(13)
              .height(13)
              .fillColor($r('app.color.ink_3'))
          }
          .width('100%')
          .height(52)
          .padding({ left: 13, right: 13 })
          .onClick(() => {
            this.open(route);
          })
        }, (route: DebugRoute) => route.name)
      }
      .width('100%')
      .borderRadius(Radius.card)
      .backgroundColor($r('app.color.surface'))
      .border({ width: 1, color: $r('app.color.line') })
    }
    .width('100%')
    .height('100%')
    .padding({
      left: Space.page,
      right: Space.page,
      top: this.ui.topInset + 10
    })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('app.color.bg'))
  }
}
