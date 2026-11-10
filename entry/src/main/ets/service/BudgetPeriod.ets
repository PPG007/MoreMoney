import { DateRange, DateUtil } from '../utils/DateUtil';

const WEEK_PREFIX: string = 'W';
const YEAR_PREFIX: string = 'Y';
const DAY_MS: number = 24 * 60 * 60 * 1000;

export enum BudgetPeriodType {
  WEEK = 'week',
  MONTH = 'month',
  YEAR = 'year'
}

export class BudgetPeriod {
  static at(index: number): BudgetPeriodType {
    if (index === 0) {
      return BudgetPeriodType.WEEK;
    }
    return index === 2 ? BudgetPeriodType.YEAR : BudgetPeriodType.MONTH;
  }

  static indexOf(type: BudgetPeriodType): number {
    if (type === BudgetPeriodType.WEEK) {
      return 0;
    }
    return type === BudgetPeriodType.YEAR ? 2 : 1;
  }

  static current(type: BudgetPeriodType, date: Date, weekStart: number): string {
    if (type === BudgetPeriodType.WEEK) {
      const start: Date = DateUtil.startOfWeek(date, weekStart);
      return WEEK_PREFIX.concat(DateUtil.dayKey(start));
    }
    if (type === BudgetPeriodType.YEAR) {
      return YEAR_PREFIX.concat(date.getFullYear().toString());
    }
    return DateUtil.monthKey(date);
  }

  static shift(type: BudgetPeriodType, key: string, delta: number, weekStart: number): string {
    if (type === BudgetPeriodType.WEEK) {
      const start: Date = BudgetPeriod.weekStartDate(key);
      const moved: Date = new Date(start.getFullYear(), start.getMonth(), start.getDate() + delta * 7, 0, 0, 0, 0);
      return WEEK_PREFIX.concat(DateUtil.dayKey(moved));
    }
    if (type === BudgetPeriodType.YEAR) {
      return YEAR_PREFIX.concat((BudgetPeriod.yearOf(key) + delta).toString());
    }
    return DateUtil.addMonths(key, delta);
  }

  static range(type: BudgetPeriodType, key: string, weekStart: number): DateRange {
    if (type === BudgetPeriodType.WEEK) {
      const start: Date = BudgetPeriod.weekStartDate(key);
      const range: DateRange = new DateRange();
      range.startMs = new Date(start.getFullYear(), start.getMonth(), start.getDate(), 0, 0, 0, 0).getTime();
      range.endMs = new Date(start.getFullYear(), start.getMonth(), start.getDate() + 6, 23, 59, 59, 999).getTime();
      return range;
    }
    if (type === BudgetPeriodType.YEAR) {
      const year: number = BudgetPeriod.yearOf(key);
      const range: DateRange = new DateRange();
      range.startMs = new Date(year, 0, 1, 0, 0, 0, 0).getTime();
      range.endMs = new Date(year, 11, 31, 23, 59, 59, 999).getTime();
      return range;
    }
    return DateUtil.rangeOfMonth(key);
  }

  static label(type: BudgetPeriodType, key: string): string {
    if (type === BudgetPeriodType.WEEK) {
      const start: Date = BudgetPeriod.weekStartDate(key);
      const end: Date = new Date(start.getFullYear(), start.getMonth(), start.getDate() + 6, 0, 0, 0, 0);
      const startText: string = (start.getMonth() + 1).toString().concat('月').concat(start.getDate().toString()).concat('日');
      const endText: string = start.getMonth() === end.getMonth()
        ? end.getDate().toString().concat('日')
        : (end.getMonth() + 1).toString().concat('月').concat(end.getDate().toString()).concat('日');
      return startText.concat('–').concat(endText);
    }
    if (type === BudgetPeriodType.YEAR) {
      return BudgetPeriod.yearOf(key).toString().concat('年');
    }
    return DateUtil.formatMonthCn(key);
  }

  static noun(type: BudgetPeriodType): string {
    if (type === BudgetPeriodType.WEEK) {
      return '本周';
    }
    if (type === BudgetPeriodType.YEAR) {
      return '本年';
    }
    return '本月';
  }

  static daysLeft(type: BudgetPeriodType, key: string, weekStart: number, now: Date): number {
    const range: DateRange = BudgetPeriod.range(type, key, weekStart);
    const todayMs: number = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0).getTime();
    if (todayMs > range.endMs) {
      return 1;
    }
    const fromMs: number = todayMs > range.startMs ? todayMs : range.startMs;
    const end: Date = new Date(range.endMs);
    const endDayMs: number = new Date(end.getFullYear(), end.getMonth(), end.getDate(), 0, 0, 0, 0).getTime();
    const days: number = Math.round((endDayMs - fromMs) / DAY_MS) + 1;
    return days < 1 ? 1 : days;
  }

  static anchor(type: BudgetPeriodType, key: string, weekStart: number, now: Date): Date {
    const range: DateRange = BudgetPeriod.range(type, key, weekStart);
    if (now.getTime() >= range.startMs && now.getTime() <= range.endMs) {
      return now;
    }
    return new Date(range.startMs);
  }

  static validate(weekCents: number, monthCents: number, yearCents: number): string {
    if (weekCents > 0 && monthCents > 0 && weekCents * 4 > monthCents) {
      return '周预算 × 4 不能超过月预算';
    }
    if (weekCents > 0 && yearCents > 0 && weekCents * 52 > yearCents) {
      return '周预算 × 52 不能超过年预算';
    }
    if (monthCents > 0 && yearCents > 0 && monthCents * 12 > yearCents) {
      return '月预算 × 12 不能超过年预算';
    }
    return '';
  }

  static weekStartDate(key: string): Date {
    const raw: string = key.startsWith(WEEK_PREFIX) ? key.substring(WEEK_PREFIX.length) : key;
    return DateUtil.parseDayKey(raw);
  }

  private static yearOf(key: string): number {
    const raw: string = key.startsWith(YEAR_PREFIX) ? key.substring(YEAR_PREFIX.length) : key;
    const year: number = Number(raw);
    return Number.isNaN(year) ? new Date().getFullYear() : year;
  }
}
