import { Book, Budget } from '../models/Entities';
import { BookDao } from '../data/db/BookDao';
import { BudgetDao } from '../data/db/BudgetDao';
import { TxnDao } from '../data/db/TxnDao';
import { TxnFilter } from '../models/Entities';
import { DateUtil, DateRange } from '../utils/DateUtil';
import { UiStore } from '../state/UiStore';
import { GlobalUiStore } from '../state/GlobalUiStore';

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

export class BudgetService {
  static async getOverview(monthKey: string): Promise<BudgetOverview> {
    const overview: BudgetOverview = new BudgetOverview();
    const books: Book[] = (await BookDao.list()).filter((book: Book): boolean => !book.archived);
    const budgets: Budget[] = await BudgetDao.list(monthKey);
    const range: DateRange = DateUtil.rangeOfMonth(monthKey);
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

    const parts: string[] = monthKey.split('-');
    const year: number = Number(parts[0]);
    const month: number = Number(parts[1]);
    const totalDays: number = DateUtil.daysInMonth(year, month);
    const now: Date = new Date();
    let daysLeft: number = totalDays;
    if (now.getFullYear() === year && now.getMonth() + 1 === month) {
      daysLeft = totalDays - now.getDate() + 1;
    }
    if (daysLeft < 1) {
      daysLeft = 1;
    }
    const available: number = overview.remainingCents > 0 ? overview.remainingCents : 0;
    overview.perDayCents = Math.floor(available / daysLeft);
    return overview;
  }

  static async setBudget(bookId: string, period: string, cents: number): Promise<void> {
    await BudgetDao.upsert(bookId, period, cents);
  }

  static async removeBudget(bookId: string, period: string): Promise<void> {
    await BudgetDao.remove(bookId, period);
  }
}
