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

  static defaultBookId(): string {
    return SettingsService.getString('defaultBookId', '');
  }

  static async setDefaultBookId(bookId: string): Promise<void> {
    await SettingsService.setString('defaultBookId', bookId);
  }

  static weekStart(): number {
    const value: number = SettingsService.getNumber('weekStart', 1);
    return value < 1 || value > 7 ? 1 : value;
  }

  static async setWeekStart(value: number): Promise<void> {
    await SettingsService.setNumber('weekStart', value);
  }

  static appearance(): number {
    const value: number = SettingsService.getNumber('appearance', 0);
    return value < 0 || value > 2 ? 0 : value;
  }

  static async setAppearance(value: number): Promise<void> {
    await SettingsService.setNumber('appearance', value);
  }

  static recentSearches(): string[] {
    const raw: string = SettingsService.getString('recentSearches', '');
    if (raw.length === 0) {
      return [];
    }
    const list: string[] = [];
    for (const item of raw.split('\n')) {
      if (item.length > 0) {
        list.push(item);
      }
    }
    return list;
  }

  static async setRecentSearches(list: string[]): Promise<void> {
    await SettingsService.setString('recentSearches', list.join('\n'));
  }

  static lastBackupAt(): number {
    return SettingsService.getNumber('lastBackupAt', 0);
  }

  static lastBackupName(): string {
    return SettingsService.getString('lastBackupName', '');
  }

  static async setLastBackup(at: number, name: string): Promise<void> {
    await SettingsService.setNumber('lastBackupAt', at);
    await SettingsService.setString('lastBackupName', name);
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
