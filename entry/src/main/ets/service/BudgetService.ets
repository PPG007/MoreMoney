import { Book, Budget } from '../models/Entities';
import { BookDao } from '../data/db/BookDao';
import { BudgetDao } from '../data/db/BudgetDao';
import { TxnDao } from '../data/db/TxnDao';
import { TxnFilter } from '../models/Entities';
import { DateRange } from '../utils/DateUtil';
import { UiStore } from '../state/UiStore';
import { GlobalUiStore } from '../state/GlobalUiStore';
import { BudgetPeriod, BudgetPeriodType } from './BudgetPeriod';
import { SettingsService } from './SettingsService';

export class BudgetBookView {
  bookId: string = '';
  name: string = '';
  icon: string = '';
  color: string = '';
  budgetCents: number = 0;
  spentCents: number = 0;
  remainingCents: number = 0;
  percent: number = 0;
  isPrivate: boolean = false;
  isLocked: boolean = false;
}

export class BudgetOverview {
  totalCents: number = 0;
  spentCents: number = 0;
  remainingCents: number = 0;
  perDayCents: number = 0;
  mainBook: BudgetBookView | null = null;
  others: BudgetBookView[] = [];
  unset: BudgetBookView[] = [];
}

export class BookBudgetState {
  weekCents: number = 0;
  monthCents: number = 0;
  yearCents: number = 0;
  weekSpentCents: number = 0;
  monthSpentCents: number = 0;
  yearSpentCents: number = 0;

  amountOf(type: BudgetPeriodType): number {
    if (type === BudgetPeriodType.WEEK) {
      return this.weekCents;
    }
    if (type === BudgetPeriodType.YEAR) {
      return this.yearCents;
    }
    return this.monthCents;
  }

  spentOf(type: BudgetPeriodType): number {
    if (type === BudgetPeriodType.WEEK) {
      return this.weekSpentCents;
    }
    if (type === BudgetPeriodType.YEAR) {
      return this.yearSpentCents;
    }
    return this.monthSpentCents;
  }

  withAmount(type: BudgetPeriodType, cents: number): BookBudgetState {
    const next: BookBudgetState = new BookBudgetState();
    next.weekCents = this.weekCents;
    next.monthCents = this.monthCents;
    next.yearCents = this.yearCents;
    next.weekSpentCents = this.weekSpentCents;
    next.monthSpentCents = this.monthSpentCents;
    next.yearSpentCents = this.yearSpentCents;
    if (type === BudgetPeriodType.WEEK) {
      next.weekCents = cents;
    } else if (type === BudgetPeriodType.YEAR) {
      next.yearCents = cents;
    } else {
      next.monthCents = cents;
    }
    return next;
  }
}

export class BudgetService {
  static async getOverview(type: BudgetPeriodType): Promise<BudgetOverview> {
    const overview: BudgetOverview = new BudgetOverview();
    const books: Book[] = (await BookDao.list()).filter((book: Book): boolean => !book.archived);
    const budgets: Budget[] = await BudgetDao.list(type);
    const weekStart: number = SettingsService.weekStart();
    const now: Date = new Date();
    const periodKey: string = BudgetPeriod.current(type, now, weekStart);
    const range: DateRange = BudgetPeriod.range(type, periodKey, weekStart);
    const unlocked: Map<string, Budget> = new Map<string, Budget>();
    for (const budget of budgets) {
      unlocked.set(budget.bookId, budget);
    }

    const ui: GlobalUiStore = UiStore.instance();
    const budgeted: BudgetBookView[] = [];
    for (const book of books) {
      const locked: boolean = book.isPrivate && !ui.isBookUnlocked(book.id);
      if (locked) {
        continue;
      }
      const budget: Budget | undefined = unlocked.get(book.id);
      const view: BudgetBookView = new BudgetBookView();
      view.bookId = book.id;
      view.name = book.name;
      view.icon = book.icon;
      view.color = book.color;
      view.isPrivate = book.isPrivate;
      view.isLocked = false;
      if (budget !== undefined && budget.amountCents > 0) {
        view.budgetCents = budget.amountCents;
        const filter: TxnFilter = new TxnFilter();
        filter.bookIds = [book.id];
        filter.startMs = range.startMs;
        filter.endMs = range.endMs;
        view.spentCents = await TxnDao.sumRange(filter);
        view.remainingCents = view.budgetCents - view.spentCents;
        view.percent = view.budgetCents > 0 ? view.spentCents / view.budgetCents : 0;
        budgeted.push(view);
      } else {
        view.budgetCents = 0;
        view.spentCents = 0;
        view.remainingCents = 0;
        view.percent = 0;
        overview.unset.push(view);
      }
    }

    let main: BudgetBookView | null = null;
    const defaultBook: Book | undefined = books.find((book: Book): boolean => book.isDefault);
    if (defaultBook !== undefined) {
      const found: BudgetBookView | undefined = budgeted.find(
        (view: BudgetBookView): boolean => view.bookId === defaultBook.id
      );
      main = found === undefined ? null : found;
    }
    if (main === null && budgeted.length > 0) {
      main = budgeted[0];
    }
    overview.mainBook = main;
    for (const view of budgeted) {
      if (main === null || view.bookId !== main.bookId) {
        overview.others.push(view);
      }
      overview.totalCents += view.budgetCents;
      overview.spentCents += view.spentCents;
    }
    overview.remainingCents = overview.totalCents - overview.spentCents;

    const daysLeft: number = BudgetPeriod.daysLeft(type, periodKey, weekStart, now);
    const available: number = overview.remainingCents > 0 ? overview.remainingCents : 0;
    overview.perDayCents = Math.floor(available / daysLeft);
    return overview;
  }

  static async getBookState(bookId: string): Promise<BookBudgetState> {
    const state: BookBudgetState = new BookBudgetState();
    await BudgetService.loadAmounts(state, bookId);
    state.weekSpentCents = await BudgetService.sumCurrent(bookId, BudgetPeriodType.WEEK);
    state.monthSpentCents = await BudgetService.sumCurrent(bookId, BudgetPeriodType.MONTH);
    state.yearSpentCents = await BudgetService.sumCurrent(bookId, BudgetPeriodType.YEAR);
    return state;
  }

  static async getUnsetBooks(): Promise<BudgetBookView[]> {
    const books: Book[] = (await BookDao.list()).filter((book: Book): boolean => !book.archived);
    const budgets: Budget[] = await BudgetDao.listAll();
    const withBudget: Set<string> = new Set<string>();
    for (const budget of budgets) {
      if (budget.amountCents > 0) {
        withBudget.add(budget.bookId);
      }
    }
    const ui: GlobalUiStore = UiStore.instance();
    const list: BudgetBookView[] = [];
    for (const book of books) {
      if (book.isPrivate && !ui.isBookUnlocked(book.id)) {
        continue;
      }
      if (withBudget.has(book.id)) {
        continue;
      }
      const view: BudgetBookView = new BudgetBookView();
      view.bookId = book.id;
      view.name = book.name;
      view.icon = book.icon;
      view.color = book.color;
      view.isPrivate = book.isPrivate;
      list.push(view);
    }
    return list;
  }

  static async setBudget(bookId: string, type: BudgetPeriodType, cents: number): Promise<void> {
    if (cents > 0) {
      const state: BookBudgetState = new BookBudgetState();
      await BudgetService.loadAmounts(state, bookId);
      const next: BookBudgetState = state.withAmount(type, cents);
      const error: string = BudgetPeriod.validate(next.weekCents, next.monthCents, next.yearCents);
      if (error.length > 0) {
        throw new Error(error);
      }
      await BudgetDao.upsert(bookId, type, cents);
    } else {
      await BudgetDao.remove(bookId, type);
    }
    UiStore.instance().notifyBudgetChanged();
  }

  private static async loadAmounts(state: BookBudgetState, bookId: string): Promise<void> {
    const budgets: Budget[] = await BudgetDao.listByBook(bookId);
    for (const budget of budgets) {
      if (budget.period === BudgetPeriodType.WEEK) {
        state.weekCents = budget.amountCents;
      } else if (budget.period === BudgetPeriodType.YEAR) {
        state.yearCents = budget.amountCents;
      } else if (budget.period === BudgetPeriodType.MONTH) {
        state.monthCents = budget.amountCents;
      }
    }
  }

  private static async sumCurrent(bookId: string, type: BudgetPeriodType): Promise<number> {
    const weekStart: number = SettingsService.weekStart();
    const key: string = BudgetPeriod.current(type, new Date(), weekStart);
    const range: DateRange = BudgetPeriod.range(type, key, weekStart);
    const filter: TxnFilter = new TxnFilter();
    filter.bookIds = [bookId];
    filter.startMs = range.startMs;
    filter.endMs = range.endMs;
    return TxnDao.sumRange(filter);
  }
}
