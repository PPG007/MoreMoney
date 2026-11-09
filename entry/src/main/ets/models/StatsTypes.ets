export enum PeriodType {
  TODAY = 'today',
  WEEK = 'week',
  MONTH = 'month',
  YEAR = 'year',
  ALL = 'all',
  CUSTOM = 'custom'
}

export enum BucketGranularity {
  DAY = 'day',
  WEEK = 'week',
  MONTH = 'month'
}

export class StatsFilter {
  bookIds: string[] = [];
  memberIds: string[] = [];
  startMs: number = 0;
  endMs: number = 0;
  excludeBookIds: string[] = [];
  weekStart: number = 1;
}

export class PeriodRange {
  startMs: number = 0;
  endMs: number = 0;
  label: string = '';
}

export class CategorySum {
  categoryId: string = '';
  name: string = '';
  icon: string = '';
  color: string = '';
  cents: number = 0;
}

export class DaySum {
  dayKey: string = '';
  cents: number = 0;
}

export class BucketSum {
  key: string = '';
  label: string = '';
  cents: number = 0;
}

export class DailyStats {
  totalCents: number = 0;
  avgCents: number = 0;
  maxCents: number = 0;
  maxDayKey: string = '';
  days: number = 0;
}
