import { preferences } from '@kit.ArkData';

const STORE_NAME: string = 'moremoney_settings';

export class SettingsService {
  private static store: preferences.Preferences | null = null;

  static async init(context: Context): Promise<void> {
    if (SettingsService.store !== null) {
      return;
    }
    SettingsService.store = await preferences.getPreferences(context, STORE_NAME);
  }

  static isReady(): boolean {
    return SettingsService.store !== null;
  }

  static getNumber(key: string, fallback: number): number {
    const store: preferences.Preferences | null = SettingsService.store;
    if (store === null) {
      return fallback;
    }
    const value: preferences.ValueType = store.getSync(key, fallback);
    return typeof value === 'number' ? value : fallback;
  }

  static getString(key: string, fallback: string): string {
    const store: preferences.Preferences | null = SettingsService.store;
    if (store === null) {
      return fallback;
    }
    const value: preferences.ValueType = store.getSync(key, fallback);
    return typeof value === 'string' ? value : fallback;
  }

  static async setNumber(key: string, value: number): Promise<void> {
    const store: preferences.Preferences | null = SettingsService.store;
    if (store === null) {
      return;
    }
    await store.put(key, value);
    await store.flush();
  }

  static async setString(key: string, value: string): Promise<void> {
    const store: preferences.Preferences | null = SettingsService.store;
    if (store === null) {
      return;
    }
    await store.put(key, value);
    await store.flush();
  }

  static async flush(): Promise<void> {
    const store: preferences.Preferences | null = SettingsService.store;
    if (store !== null) {
      await store.flush();
    }
  }
}
