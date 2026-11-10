@ObservedV2
export class SnackBarState {
  @Trace message: string = '';
  @Trace actionLabel: string = '';
  @Trace tone: string = 'info';
  @Trace visible: boolean = false;
  @Trace token: number = 0;
}

@ObservedV2
export class GlobalUiStore {
  @Trace hideAmount: boolean = false;
  @Trace isDark: boolean = false;
  @Trace topInset: number = 0;
  @Trace bottomInset: number = 0;
  @Trace snackbar: SnackBarState = new SnackBarState();
  @Trace unlockVersion: number = 0;
  @Trace txnVersion: number = 0;
  @Trace budgetVersion: number = 0;
  @Trace bookVersion: number = 0;

  notifyTxnChanged(): void {
    this.txnVersion += 1;
  }

  notifyBudgetChanged(): void {
    this.budgetVersion += 1;
  }

  notifyBookChanged(): void {
    this.bookVersion += 1;
  }

  unlockedUntil: Record<string, number> = {};

  isBookUnlocked(bookId: string): boolean {
    const until: number | undefined = this.unlockedUntil[bookId];
    return until !== undefined && until > Date.now();
  }

  unlockBook(bookId: string, minutes: number = 5): void {
    this.unlockedUntil[bookId] = Date.now() + minutes * 60 * 1000;
    this.unlockVersion += 1;
  }

  lockBook(bookId: string): void {
    this.unlockedUntil[bookId] = 0;
    this.unlockVersion += 1;
  }

  lockAllPrivate(): void {
    this.unlockedUntil = {};
    this.unlockVersion += 1;
  }
}
