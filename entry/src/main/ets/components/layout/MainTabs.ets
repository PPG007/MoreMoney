import { AppFont, Radius } from '../../theme/Theme';
import { IconSize } from '../../theme/IconSize';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { HomePage } from '../../pages/home/HomePage';
import { BudgetPage } from '../../pages/budget/BudgetPage';
import { ChartsPage } from '../../pages/charts/ChartsPage';
import { SettingsPage } from '../../pages/settings/SettingsPage';

@ComponentV2
export struct MainTabs {
  @Param selectedIndex: number = 0;
  @Param stack: NavPathStack = new NavPathStack();
  @Event onIndexChange: (index: number) => void = (index: number) => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();

  @Builder
  tabItem(index: number, label: string, icon: Resource) {
    Column({ space: 2 }) {
      Stack() {
        Image(icon)
          .width(IconSize.tab)
          .height(IconSize.tab)
          .fillColor(this.selectedIndex === index ? $r('app.color.brand_ink') : $r('app.color.ink_3'))
      }
      .width(38)
      .height(25)
      .borderRadius(Radius.pill)
      .backgroundColor(this.selectedIndex === index ? $r('app.color.brand_soft') : Color.Transparent)

      Text(label)
        .fontSize(AppFont.micro)
        .fontWeight(this.selectedIndex === index ? AppFont.semibold : AppFont.regular)
        .fontColor(this.selectedIndex === index ? $r('app.color.brand_ink') : $r('app.color.ink_3'))
    }
    .width('100%')
    .height(62)
    .padding({ bottom: this.ui.bottomInset })
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.selectedIndex }) {
      TabContent() {
        HomePage()
      }
      .tabBar(this.tabItem(0, '账本', $r('app.media.ic_tab_books')))

      TabContent() {
        BudgetPage()
      }
      .tabBar(this.tabItem(1, '预算', $r('app.media.ic_tab_budget')))

      TabContent() {
        ChartsPage()
      }
      .tabBar(this.tabItem(2, '图表', $r('app.media.ic_tab_charts')))

      TabContent() {
        SettingsPage({ stack: this.stack })
      }
      .tabBar(this.tabItem(3, '设置', $r('app.media.ic_tab_settings')))
    }
    .barHeight(62 + this.ui.bottomInset)
    .barBackgroundColor($r('app.color.tab_bg'))
    .barBackgroundBlurStyle(BlurStyle.COMPONENT_THICK)
    .border({ width: { top: 1 }, color: $r('app.color.line') })
    .scrollable(false)
    .animationDuration(0)
    .onChange((index: number) => {
      this.onIndexChange(index);
    })
    .width('100%')
    .height('100%')
  }
}
