import { window } from '@kit.ArkUI';

export class ScreenPrivacyService {
  static async enable(context: Context): Promise<void> {
    try {
      const win: window.Window = await window.getLastWindow(context);
      await win.setWindowPrivacyMode(true);
    } catch (error) {
    }
  }

  static async disable(context: Context): Promise<void> {
    try {
      const win: window.Window = await window.getLastWindow(context);
      await win.setWindowPrivacyMode(false);
    } catch (error) {
    }
  }
}
