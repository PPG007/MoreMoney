import { userAuth } from '@kit.UserAuthenticationKit';
import { Book } from '../models/Entities';
import { BookDao } from '../data/db/BookDao';
import { CryptoUtil } from '../utils/CryptoUtil';
import { UiStore } from '../state/UiStore';
import { GlobalUiStore } from '../state/GlobalUiStore';
import { SettingsService } from './SettingsService';

const DEFAULT_ITERATIONS: number = 10000;
const SALT_LENGTH: number = 16;
const MAX_FAILURES: number = 5;
const LOCK_SECONDS: number = 30;
const BIOMETRIC_TIMEOUT_MS: number = 60000;

export class BiometricCapability {
  available: boolean = false;
  changed: boolean = false;
  enrolled: boolean = false;
  authTypes: userAuth.UserAuthType[] = [];
  trustLevel: userAuth.AuthTrustLevel = userAuth.AuthTrustLevel.ATL2;
  label: string = '';
}

export class PrivateBookService {
  private static failures: Record<string, number> = {};
  private static lockedUntil: Record<string, number> = {};
  private static authPromise: Promise<boolean> | null = null;
  private static authInstance: userAuth.UserAuthInstance | null = null;
  private static authFinish: ((ok: boolean) => void) | null = null;
  private static authTimer: number = -1;

  static async setPassword(bookId: string, password: string): Promise<void> {
    const book: Book | null = await BookDao.get(bookId);
    if (book === null) {
      throw new Error('账本不存在');
    }
    const salt: Uint8Array = CryptoUtil.randomBytes(SALT_LENGTH);
    const hash: Uint8Array = await CryptoUtil.deriveKey(password, salt, DEFAULT_ITERATIONS);
    const updated: Book = PrivateBookService.copyBook(book);
    updated.isPrivate = true;
    updated.pwdHash = CryptoUtil.base64(hash);
    updated.pwdSalt = CryptoUtil.base64(salt);
    updated.pwdIter = DEFAULT_ITERATIONS;
    updated.updatedAt = Date.now();
    await BookDao.update(updated);
    await PrivateBookService.rememberBiometric();
  }

  static async verify(bookId: string, password: string): Promise<boolean> {
    if (PrivateBookService.remainingLockSeconds(bookId) > 0) {
      return false;
    }
    const book: Book | null = await BookDao.get(bookId);
    if (book === null || book.pwdHash === null || book.pwdSalt === null) {
      return false;
    }
    const salt: Uint8Array = CryptoUtil.fromBase64(book.pwdSalt);
    const expected: Uint8Array = CryptoUtil.fromBase64(book.pwdHash);
    const actual: Uint8Array = await CryptoUtil.deriveKey(password, salt, book.pwdIter);
    const matched: boolean = CryptoUtil.constantTimeEquals(actual, expected);
    if (matched) {
      PrivateBookService.failures[bookId] = 0;
      PrivateBookService.lockedUntil[bookId] = 0;
      return true;
    }
    PrivateBookService.recordFailure(bookId);
    return false;
  }

  static async changePassword(bookId: string, oldPwd: string, newPwd: string): Promise<boolean> {
    const ok: boolean = await PrivateBookService.verify(bookId, oldPwd);
    if (!ok) {
      return false;
    }
    await PrivateBookService.setPassword(bookId, newPwd);
    return true;
  }

  static async clearPassword(bookId: string, password: string): Promise<boolean> {
    const ok: boolean = await PrivateBookService.verify(bookId, password);
    if (!ok) {
      return false;
    }
    const book: Book | null = await BookDao.get(bookId);
    if (book === null) {
      return false;
    }
    const updated: Book = PrivateBookService.copyBook(book);
    updated.isPrivate = false;
    updated.pwdHash = null;
    updated.pwdSalt = null;
    updated.pwdIter = DEFAULT_ITERATIONS;
    updated.updatedAt = Date.now();
    await BookDao.update(updated);
    UiStore.instance().lockBook(bookId);
    return true;
  }

  static async disablePrivate(bookId: string): Promise<void> {
    const book: Book | null = await BookDao.get(bookId);
    if (book === null) {
      return;
    }
    const updated: Book = PrivateBookService.copyBook(book);
    updated.isPrivate = false;
    updated.pwdHash = null;
    updated.pwdSalt = null;
    updated.pwdIter = DEFAULT_ITERATIONS;
    updated.updatedAt = Date.now();
    await BookDao.update(updated);
    UiStore.instance().lockBook(bookId);
  }

  static async isLocked(bookId: string): Promise<boolean> {
    const book: Book | null = await BookDao.get(bookId);
    if (book === null || !book.isPrivate) {
      return false;
    }
    return !UiStore.instance().isBookUnlocked(bookId);
  }

  static async lockedBookIds(): Promise<string[]> {
    const books: Book[] = await BookDao.list();
    const ui: GlobalUiStore = UiStore.instance();
    const result: string[] = [];
    for (const book of books) {
      if (book.isPrivate && !book.archived && !ui.isBookUnlocked(book.id)) {
        result.push(book.id);
      }
    }
    return result;
  }

  static async privateBookIds(): Promise<string[]> {
    const books: Book[] = await BookDao.list();
    return books
      .filter((book: Book): boolean => book.isPrivate)
      .map((book: Book): string => book.id);
  }

  static remainingLockSeconds(bookId: string): number {
    const until: number | undefined = PrivateBookService.lockedUntil[bookId];
    if (until === undefined) {
      return 0;
    }
    const remain: number = Math.ceil((until - Date.now()) / 1000);
    return remain > 0 ? remain : 0;
  }

  static remainingAttempts(bookId: string): number {
    const failures: number | undefined = PrivateBookService.failures[bookId];
    if (failures === undefined) {
      return MAX_FAILURES;
    }
    const remain: number = MAX_FAILURES - failures;
    return remain > 0 ? remain : 0;
  }

  static biometricCapability(): BiometricCapability {
    const capability: BiometricCapability = new BiometricCapability();
    capability.enrolled = PrivateBookService.currentDigest(userAuth.UserAuthType.FACE).length > 0 ||
      PrivateBookService.currentDigest(userAuth.UserAuthType.FINGERPRINT).length > 0;
    const atl3Types: userAuth.UserAuthType[] = PrivateBookService.availableTypes(userAuth.AuthTrustLevel.ATL3);
    const atl2Types: userAuth.UserAuthType[] = PrivateBookService.availableTypes(userAuth.AuthTrustLevel.ATL2);
    if (atl3Types.length > 0 && atl3Types.length === atl2Types.length) {
      capability.authTypes = atl3Types;
      capability.trustLevel = userAuth.AuthTrustLevel.ATL3;
    } else if (atl2Types.length > 0) {
      capability.authTypes = atl2Types;
      capability.trustLevel = userAuth.AuthTrustLevel.ATL2;
    }
    if (capability.authTypes.length === 0) {
      return capability;
    }
    capability.label = PrivateBookService.authLabel(capability.authTypes);
    if (PrivateBookService.biometricChanged(capability.authTypes)) {
      capability.changed = true;
      return capability;
    }
    capability.available = true;
    return capability;
  }

  static authenticateBiometric(context: Context): Promise<boolean> {
    if (PrivateBookService.authPromise !== null) {
      return PrivateBookService.authPromise;
    }
    const capability: BiometricCapability = PrivateBookService.biometricCapability();
    if (!capability.available) {
      return Promise.resolve(false);
    }
    const promise: Promise<boolean> = PrivateBookService.runBiometric(capability, context);
    PrivateBookService.authPromise = promise;
    promise.then(() => {
      if (PrivateBookService.authPromise === promise) {
        PrivateBookService.authPromise = null;
      }
    });
    return promise;
  }

  static cancelBiometric(): void {
    const finish: ((ok: boolean) => void) | null = PrivateBookService.authFinish;
    const instance: userAuth.UserAuthInstance | null = PrivateBookService.authInstance;
    if (finish !== null) {
      finish(false);
    }
    if (instance !== null) {
      try {
        instance.cancel();
      } catch (error) {
      }
    }
  }

  static async rememberBiometric(): Promise<void> {
    await PrivateBookService.storeDigest(userAuth.UserAuthType.FACE);
    await PrivateBookService.storeDigest(userAuth.UserAuthType.FINGERPRINT);
  }

  private static runBiometric(capability: BiometricCapability, context: Context): Promise<boolean> {
    return new Promise<boolean>((resolve: (value: boolean) => void) => {
      let settled: boolean = false;
      let instance: userAuth.UserAuthInstance | null = null;
      let callback: userAuth.IAuthCallback | null = null;
      const finish = (ok: boolean): void => {
        if (settled) {
          return;
        }
        settled = true;
        if (PrivateBookService.authTimer !== -1) {
          clearTimeout(PrivateBookService.authTimer);
          PrivateBookService.authTimer = -1;
        }
        if (instance !== null && callback !== null) {
          try {
            instance.off('result', callback);
          } catch (error) {
          }
        }
        if (PrivateBookService.authInstance === instance) {
          PrivateBookService.authInstance = null;
        }
        PrivateBookService.authFinish = null;
        resolve(ok);
      };
      PrivateBookService.authFinish = finish;
      const authParam: userAuth.AuthParam = {
        challenge: CryptoUtil.randomBytes(16),
        authType: capability.authTypes,
        authTrustLevel: capability.trustLevel
      };
      const widgetParam: userAuth.WidgetParam = {
        title: '解锁私密账本',
        navigationButtonText: '使用密码',
        uiContext: context
      };
      try {
        instance = userAuth.getUserAuthInstance(authParam, widgetParam);
        PrivateBookService.authInstance = instance;
        callback = {
          onResult: (result: userAuth.UserAuthResult): void => {
            finish(result.result === userAuth.UserAuthResultCode.SUCCESS);
          }
        };
        instance.on('result', callback);
        PrivateBookService.authTimer = setTimeout(() => {
          finish(false);
          if (instance !== null) {
            try {
              instance.cancel();
            } catch (error) {
            }
          }
        }, BIOMETRIC_TIMEOUT_MS);
        instance.start();
      } catch (error) {
        finish(false);
      }
    });
  }

  private static availableTypes(level: userAuth.AuthTrustLevel): userAuth.UserAuthType[] {
    const types: userAuth.UserAuthType[] = [];
    if (PrivateBookService.supports(userAuth.UserAuthType.FINGERPRINT, level)) {
      types.push(userAuth.UserAuthType.FINGERPRINT);
    }
    if (PrivateBookService.supports(userAuth.UserAuthType.FACE, level)) {
      types.push(userAuth.UserAuthType.FACE);
    }
    return types;
  }

  private static supports(type: userAuth.UserAuthType, level: userAuth.AuthTrustLevel): boolean {
    try {
      userAuth.getAvailableStatus(type, level);
      return true;
    } catch (error) {
      return false;
    }
  }

  private static authLabel(types: userAuth.UserAuthType[]): string {
    const hasFace: boolean = types.indexOf(userAuth.UserAuthType.FACE) >= 0;
    const hasFinger: boolean = types.indexOf(userAuth.UserAuthType.FINGERPRINT) >= 0;
    if (hasFace && hasFinger) {
      return '指纹/面容';
    }
    return hasFace ? '面容' : '指纹';
  }

  private static biometricChanged(types: userAuth.UserAuthType[]): boolean {
    for (const type of types) {
      const stored: string = SettingsService.getString(PrivateBookService.digestKey(type), '');
      if (stored.length === 0) {
        continue;
      }
      const current: string = PrivateBookService.currentDigest(type);
      if (current.length > 0 && current !== stored) {
        return true;
      }
    }
    return false;
  }

  private static async storeDigest(type: userAuth.UserAuthType): Promise<void> {
    const current: string = PrivateBookService.currentDigest(type);
    if (current.length > 0) {
      await SettingsService.setString(PrivateBookService.digestKey(type), current);
    }
  }

  private static currentDigest(type: userAuth.UserAuthType): string {
    try {
      const state: userAuth.EnrolledState = userAuth.getEnrolledState(type);
      if (state.credentialCount <= 0 || state.credentialDigest === 0) {
        return '';
      }
      return state.credentialDigest.toString();
    } catch (error) {
      return '';
    }
  }

  private static digestKey(type: userAuth.UserAuthType): string {
    return type === userAuth.UserAuthType.FACE ? 'biometric_face_digest' : 'biometric_fingerprint_digest';
  }

  private static recordFailure(bookId: string): void {
    const current: number | undefined = PrivateBookService.failures[bookId];
    const next: number = current === undefined ? 1 : current + 1;
    PrivateBookService.failures[bookId] = next;
    if (next >= MAX_FAILURES) {
      PrivateBookService.lockedUntil[bookId] = Date.now() + LOCK_SECONDS * 1000;
      PrivateBookService.failures[bookId] = 0;
    }
  }

  private static copyBook(book: Book): Book {
    const copy: Book = {
      id: book.id,
      name: book.name,
      icon: book.icon,
      color: book.color,
      isPrivate: book.isPrivate,
      pwdHash: book.pwdHash,
      pwdSalt: book.pwdSalt,
      pwdIter: book.pwdIter,
      isDefault: book.isDefault,
      sort: book.sort,
      archived: book.archived,
      createdAt: book.createdAt,
      updatedAt: book.updatedAt
    };
    return copy;
  }
}
