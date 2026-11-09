const WEEK_NAMES: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

export class DateUtil {
  static dayKey(date: Date): string {
    const month: string = (date.getMonth() + 1).toString().padStart(2, '0');
    const day: string = date.getDate().toString().padStart(2, '0');
    return date.getFullYear().toString().concat('-').concat(month).concat('-').concat(day);
  }

  static monthKey(date: Date): string {
    const month: string = (date.getMonth() + 1).toString().padStart(2, '0');
    return date.getFullYear().toString().concat('-').concat(month);
  }

  static parseDayKey(key: string): Date {
    const parts: string[] = key.split('-');
    if (parts.length !== 3) {
      return new Date(0);
    }
    return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]), 0, 0, 0, 0);
  }

  static daysInMonth(year: number, month1to12: number): number {
    return new Date(year, month1to12, 0).getDate();
  }

  static startOfWeek(date: Date, weekStart: number): Date {
    const normalized: number = weekStart < 1 ? 1 : (weekStart > 7 ? 7 : weekStart);
    const target: number = normalized === 7 ? 0 : normalized;
    const diff: number = (date.getDay() - target + 7) % 7;
    return new Date(date.getFullYear(), date.getMonth(), date.getDate() - diff, 0, 0, 0, 0);
  }

  static rangeOfMonth(monthKey: string): DateRange {
    const parts: string[] = monthKey.split('-');
    const year: number = Number(parts[0]);
    const month: number = Number(parts[1]);
    const start: Date = new Date(year, month - 1, 1, 0, 0, 0, 0);
    const end: Date = new Date(year, month, 0, 23, 59, 59, 999);
    const range: DateRange = new DateRange();
    range.startMs = start.getTime();
    range.endMs = end.getTime();
    return range;
  }

  static addMonths(monthKey: string, delta: number): string {
    const parts: string[] = monthKey.split('-');
    const base: Date = new Date(Number(parts[0]), Number(parts[1]) - 1 + delta, 1, 0, 0, 0, 0);
    return DateUtil.monthKey(base);
  }

  static formatMonthCn(monthKey: string): string {
    const parts: string[] = monthKey.split('-');
    return Number(parts[1]).toString().concat('月');
  }

  static formatDayCn(dayKey: string): string {
    const date: Date = DateUtil.parseDayKey(dayKey);
    const month: string = (date.getMonth() + 1).toString();
    const day: string = date.getDate().toString();
    return month.concat('月').concat(day).concat('日 ').concat(WEEK_NAMES[date.getDay()]);
  }
}

export class DateRange {
  startMs: number = 0;
  endMs: number = 0;
}
