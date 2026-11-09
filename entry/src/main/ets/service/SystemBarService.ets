import { window } from '@kit.ArkUI';
import { GlobalUiStore } from '../state/GlobalUiStore';
import { BarColors } from '../theme/Palette';

export class SystemBarService {
  static async updateInsets(ui: GlobalUiStore, context: Context): Promise<void> {
    const win: window.Window = await window.getLastWindow(context);
    const systemArea: window.AvoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    const indicatorArea: window.AvoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
    ui.topInset = px2vp(systemArea.topRect.height);
    ui.bottomInset = px2vp(indicatorArea.bottomRect.height);
  }

  static async setStatusBarDarkText(context: Context, dark: boolean): Promise<void> {
    const win: window.Window = await window.getLastWindow(context);
    const properties: window.SystemBarProperties = {
      statusBarContentColor: dark ? BarColors.statusBarDark : BarColors.statusBarLight
    };
    await win.setWindowSystemBarProperties(properties);
  }

  static applyFullScreen(windowStage: window.WindowStage): void {
    const win: window.Window = windowStage.getMainWindowSync();
    win.setWindowLayoutFullScreen(true).catch(() => {
    });
    const properties: window.SystemBarProperties = {
      statusBarContentColor: BarColors.statusBarLight
    };
    win.setWindowSystemBarProperties(properties).catch(() => {
    });
  }
}
