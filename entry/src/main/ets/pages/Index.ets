import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { GlobalUiStore } from '../state/GlobalUiStore';
import { UiStore } from '../state/UiStore';
import { SystemBarService } from '../service/SystemBarService';
import { DbManager } from '../data/db/DbManager';
import { MainTabs } from '../components/layout/MainTabs';

const DOMAIN: number = 0x0000;
const TAG: string = 'MoreMoneyIndex';

@Entry
@ComponentV2
struct Index {
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local selectedIndex: number = 0;
  @Local dbReady: boolean = false;
  stack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      SystemBarService.updateInsets(this.ui, context).catch(() => {
      });
      SystemBarService.setStatusBarDarkText(context, false).catch(() => {
      });
      DbManager.init(context).then(() => {
        this.dbReady = true;
      }).catch((error: BusinessError) => {
        hilog.error(DOMAIN, TAG, 'DB init failed: %{public}s', error.message);
        this.dbReady = true;
      });
    }
  }

  private onTabChange(index: number): void {
    this.selectedIndex = index;
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      SystemBarService.setStatusBarDarkText(context, index !== 0).catch(() => {
      });
    }
  }

  build() {
    Stack() {
      Navigation(this.stack) {
        MainTabs({
          selectedIndex: this.selectedIndex,
          stack: this.stack,
          onIndexChange: (index: number) => {
            this.onTabChange(index);
          }
        })
      }
      .mode(NavigationMode.Stack)
      .hideTitleBar(true)
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.bg'))

      if (!this.dbReady) {
        Column({ space: 12 }) {
          LoadingProgress()
            .width(32)
            .height(32)
            .color($r('app.color.brand'))
          Text('正在准备账本…')
            .fontSize(10)
            .fontColor($r('app.color.ink_3'))
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('app.color.bg'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg'))
  }
}
