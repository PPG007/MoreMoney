import { util } from '@kit.ArkTS';

export class IdUtil {
  static next(): string {
    return util.generateRandomUUID(false);
  }
}
