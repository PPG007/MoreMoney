import { relationalStore } from '@kit.ArkData';
import { BucketGranularity, BucketSum, CategorySum, DailyStats, DaySum, StatsFilter } from '../models/StatsTypes';
import { DbManager } from '../data/db/DbManager';
import { DateUtil } from '../utils/DateUtil';

export class StatsService {
  static async sum(filter: StatsFilter): Promise<number> {
    const args: Array<relationalStore.ValueType> = [];
    const where: string = StatsService.buildWhere(filter, args, 't.');
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT COALESCE(SUM(t.amount_cents), 0) AS total FROM txn t WHERE ' + where, args
    );
    try {
      if (rs.goToFirstRow()) {
        return rs.getLong(rs.getColumnIndex('total'));
      }
    } finally {
      rs.close();
    }
    return 0;
  }

  static async byCategory(filter: StatsFilter): Promise<CategorySum[]> {
    const args: Array<relationalStore.ValueType> = [];
    const where: string = StatsService.buildWhere(filter, args, 't.');
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT c.id AS category_id, c.name AS category_name, c.icon AS category_icon, ' +
        'c.color AS category_color, SUM(t.amount_cents) AS total ' +
        'FROM txn t INNER JOIN category c ON c.id = t.category_id WHERE ' + where + ' ' +
        'GROUP BY c.id, c.name, c.icon, c.color ORDER BY total DESC, c.name ASC', args
    );
    const list: CategorySum[] = [];
    try {
      while (rs.goToNextRow()) {
        const item: CategorySum = new CategorySum();
        item.categoryId = rs.getString(rs.getColumnIndex('category_id'));
        item.name = rs.getString(rs.getColumnIndex('category_name'));
        item.icon = rs.getString(rs.getColumnIndex('category_icon'));
        item.color = rs.getString(rs.getColumnIndex('category_color'));
        item.cents = rs.getLong(rs.getColumnIndex('total'));
        list.push(item);
      }
    } finally {
      rs.close();
    }
    return list;
  }

  static async byDay(filter: StatsFilter): Promise<DaySum[]> {
    const args: Array<relationalStore.ValueType> = [];
    const where: string = StatsService.buildWhere(filter, args, 't.');
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(
      'SELECT t.day_key AS day_key, SUM(t.amount_cents) AS total FROM txn t WHERE ' + where + ' ' +
        'GROUP BY t.day_key ORDER BY t.day_key ASC', args
    );
    const raw: DaySum[] = [];
    try {
      while (rs.goToNextRow()) {
        const item: DaySum = new DaySum();
        item.dayKey = rs.getString(rs.getColumnIndex('day_key'));
        item.cents = rs.getLong(rs.getColumnIndex('total'));
        raw.push(item);
      }
    } finally {
      rs.close();
    }
    return StatsService.fillDays(filter, raw);
  }

  static async byBucket(filter: StatsFilter, granularity: BucketGranularity): Promise<BucketSum[]> {
    if (granularity === BucketGranularity.DAY) {
      const days: DaySum[] = await StatsService.byDay(filter);
      const result: BucketSum[] = [];
      for (const day of days) {
        const bucket: BucketSum = new BucketSum();
        bucket.key = day.dayKey;
        bucket.label = StatsService.dayLabel(day.dayKey);
        bucket.cents = day.cents;
        result.push(bucket);
      }
      return result;
    }
    if (granularity === BucketGranularity.MONTH) {
      return StatsService.queryBuckets(filter, 'substr(t.day_key, 1, 7)', BucketGranularity.MONTH);
    }
    const target: number = filter.weekStart % 7;
    const expr: string = 'date(t.day_key, \'-\' || ((CAST(strftime(\'%w\', t.day_key) AS INTEGER) - '
      .concat(target.toString())
      .concat(' + 7) % 7) || \' days\')');
    return StatsService.queryBuckets(filter, expr, BucketGranularity.WEEK);
  }

  static async topDays(filter: StatsFilter, n: number): Promise<DaySum[]> {
    const days: DaySum[] = await StatsService.byDay(filter);
    const positive: DaySum[] = days.filter((day: DaySum): boolean => day.cents > 0);
    positive.sort((a: DaySum, b: DaySum): number => {
      if (b.cents !== a.cents) {
        return b.cents - a.cents;
      }
      return a.dayKey.localeCompare(b.dayKey);
    });
    return positive.slice(0, n);
  }

  static async dailyStats(filter: StatsFilter): Promise<DailyStats> {
    const days: DaySum[] = await StatsService.byDay(filter);
    const stats: DailyStats = new DailyStats();
    for (const day of days) {
      if (day.cents <= 0) {
        continue;
      }
      stats.totalCents += day.cents;
      stats.days += 1;
      if (day.cents > stats.maxCents) {
        stats.maxCents = day.cents;
        stats.maxDayKey = day.dayKey;
      }
    }
    if (stats.days > 0) {
      stats.avgCents = Math.floor(stats.totalCents / stats.days);
    }
    return stats;
  }

  static async categoryLegend(filter: StatsFilter): Promise<CategorySum[]> {
    const all: CategorySum[] = await StatsService.byCategory(filter);
    if (all.length <= 5) {
      return all;
    }
    const result: CategorySum[] = [];
    let otherCents: number = 0;
    for (let i = 0; i < all.length; i++) {
      if (i < 5) {
        result.push(all[i]);
      } else {
        otherCents += all[i].cents;
      }
    }
    if (otherCents > 0) {
      const other: CategorySum = new CategorySum();
      other.categoryId = '__other__';
      other.name = '其他';
      other.icon = 'ic_cat_other';
      other.cents = otherCents;
      result.push(other);
    }
    return result;
  }

  private static async queryBuckets(filter: StatsFilter, keyExpr: string,
    granularity: BucketGranularity): Promise<BucketSum[]> {
    const args: Array<relationalStore.ValueType> = [];
    const where: string = StatsService.buildWhere(filter, args, 't.');
    const sql: string = 'SELECT ' + keyExpr + ' AS bucket_key, SUM(t.amount_cents) AS total ' +
      'FROM txn t WHERE ' + where + ' GROUP BY bucket_key ORDER BY bucket_key ASC';
    const rs: relationalStore.ResultSet = await DbManager.store.querySql(sql, args);
    const list: BucketSum[] = [];
    try {
      while (rs.goToNextRow()) {
        const bucket: BucketSum = new BucketSum();
        bucket.key = rs.getString(rs.getColumnIndex('bucket_key'));
        bucket.cents = rs.getLong(rs.getColumnIndex('total'));
        bucket.label = granularity === BucketGranularity.MONTH
          ? StatsService.monthLabel(bucket.key)
          : StatsService.weekLabel(bucket.key);
        list.push(bucket);
      }
    } finally {
      rs.close();
    }
    return list;
  }

  private static buildWhere(filter: StatsFilter, args: Array<relationalStore.ValueType>, prefix: string): string {
    let where: string = 't.deleted_at IS NULL';
    if (filter.startMs > 0) {
      where += ' AND ' + prefix + 'day_key >= ?';
      args.push(DateUtil.dayKey(new Date(filter.startMs)));
    }
    if (filter.endMs > 0) {
      where += ' AND ' + prefix + 'day_key <= ?';
      args.push(DateUtil.dayKey(new Date(filter.endMs)));
    }
    if (filter.bookIds.length > 0) {
      where += ' AND ' + prefix + 'book_id IN (' + StatsService.marks(filter.bookIds.length) + ')';
      for (const id of filter.bookIds) {
        args.push(id);
      }
    }
    if (filter.excludeBookIds.length > 0) {
      where += ' AND ' + prefix + 'book_id NOT IN (' + StatsService.marks(filter.excludeBookIds.length) + ')';
      for (const id of filter.excludeBookIds) {
        args.push(id);
      }
    }
    if (filter.memberIds.length > 0) {
      where += ' AND ' + prefix + 'member_id IN (' + StatsService.marks(filter.memberIds.length) + ')';
      for (const id of filter.memberIds) {
        args.push(id);
      }
    }
    where += ' AND ' + prefix + 'book_id NOT IN (SELECT id FROM book WHERE archived = 1)';
    return where;
  }

  private static fillDays(filter: StatsFilter, raw: DaySum[]): DaySum[] {
    if (filter.startMs <= 0 || filter.endMs <= 0) {
      return raw;
    }
    const startKey: string = DateUtil.dayKey(new Date(filter.startMs));
    const endKey: string = DateUtil.dayKey(new Date(filter.endMs));
    const start: Date = DateUtil.parseDayKey(startKey);
    const end: Date = DateUtil.parseDayKey(endKey);
    const totalDays: number = Math.floor((end.getTime() - start.getTime()) / (24 * 60 * 60 * 1000)) + 1;
    if (totalDays <= 0 || totalDays > 400) {
      return raw;
    }
    const lookup: Record<string, number> = {};
    for (const item of raw) {
      lookup[item.dayKey] = item.cents;
    }
    const result: DaySum[] = [];
    for (let i = 0; i < totalDays; i++) {
      const date: Date = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i, 0, 0, 0, 0);
      const key: string = DateUtil.dayKey(date);
      const item: DaySum = new DaySum();
      item.dayKey = key;
      const value: number | undefined = lookup[key];
      item.cents = value === undefined ? 0 : value;
      result.push(item);
    }
    return result;
  }

  private static marks(count: number): string {
    const marks: string[] = [];
    for (let i = 0; i < count; i++) {
      marks.push('?');
    }
    return marks.join(', ');
  }

  private static dayLabel(dayKey: string): string {
    const parts: string[] = dayKey.split('-');
    if (parts.length !== 3) {
      return dayKey;
    }
    return Number(parts[1]).toString().concat('/').concat(Number(parts[2]).toString());
  }

  private static weekLabel(dayKey: string): string {
    return StatsService.dayLabel(dayKey).concat('周');
  }

  private static monthLabel(monthKey: string): string {
    const parts: string[] = monthKey.split('-');
    if (parts.length !== 2) {
      return monthKey;
    }
    return Number(parts[1]).toString().concat('月');
  }
}
