import { AppStorageV2 } from '@kit.ArkUI';
import { GlobalUiStore } from './GlobalUiStore';

let shared: GlobalUiStore | undefined = undefined;

export class UiStore {
  static instance(): GlobalUiStore {
    if (shared !== undefined) {
      return shared;
    }
    let connected: GlobalUiStore | undefined = undefined;
    try {
      connected = AppStorageV2.connect(GlobalUiStore, 'globalUi', () => new GlobalUiStore());
    } catch (error) {
      connected = undefined;
    }
    shared = connected === undefined ? new GlobalUiStore() : connected;
    return shared;
  }
}
