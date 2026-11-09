import { userAuth } from '@kit.UserAuthenticationKit';
import { Book } from '../models/Entities';
import { BookDao } from '../data/db/BookDao';
import { CryptoUtil } from '../utils/CryptoUtil';
import { UiStore } from '../state/UiStore';
import { GlobalUiStore } from '../state/GlobalUiStore';

const DEFAULT_ITERATIONS: number = 10000;
const SALT_LENGTH: number = 16;
const MAX_FAILURES: number = 5;
const LOCK_SECONDS: number = 30;

export class PrivateBookService {
  private static failures: Record<string, number> = {};
  private static lockedUntil: Record<string, number> = {};

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

  static biometricAvailable(): boolean {
    try {
      userAuth.getAvailableStatus(userAuth.UserAuthType.FACE, userAuth.AuthTrustLevel.ATL3);
      return true;
    } catch (faceError) {
      try {
        userAuth.getAvailableStatus(userAuth.UserAuthType.FINGERPRINT, userAuth.AuthTrustLevel.ATL3);
        return true;
      } catch (fingerError) {
        return false;
      }
    }
  }

  static async authenticateBiometric(context: Context): Promise<boolean> {
    return new Promise<boolean>((resolve: (value: boolean) => void) => {
      const authParam: userAuth.AuthParam = {
        challenge: CryptoUtil.randomBytes(16),
        authType: [userAuth.UserAuthType.FACE, userAuth.UserAuthType.FINGERPRINT],
        authTrustLevel: userAuth.AuthTrustLevel.ATL3
      };
      const widgetParam: userAuth.WidgetParam = {
        title: '解锁私密账本',
        uiContext: context
      };
      try {
        const instance: userAuth.UserAuthInstance = userAuth.getUserAuthInstance(authParam, widgetParam);
        const callback: userAuth.IAuthCallback = {
          onResult: (result: userAuth.UserAuthResult): void => {
            resolve(result.result === userAuth.UserAuthResultCode.SUCCESS);
          }
        };
        instance.on('result', callback);
        instance.start();
      } catch (error) {
        resolve(false);
      }
    });
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
