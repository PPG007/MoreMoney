import { AppStorageV2 } from '@kit.ArkUI';
import { GlobalUiStore } from './GlobalUiStore';

let fallback: GlobalUiStore | undefined = undefined;

export class UiStore {
  static instance(): GlobalUiStore {
    try {
      const shared: GlobalUiStore | undefined = AppStorageV2.connect(
        GlobalUiStore, 'globalUi', () => new GlobalUiStore()
      );
      if (shared !== undefined) {
        return shared;
      }
    } catch (error) {
      fallback = fallback === undefined ? new GlobalUiStore() : fallback;
      return fallback;
    }
    fallback = fallback === undefined ? new GlobalUiStore() : fallback;
    return fallback;
  }
}
