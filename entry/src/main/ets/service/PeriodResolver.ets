import { BucketGranularity, PeriodRange, PeriodType } from '../models/StatsTypes';
import { DateUtil } from '../utils/DateUtil';

const DAY_MS: number = 24 * 60 * 60 * 1000;

export class PeriodResolver {
  static resolve(type: PeriodType, now: Date, weekStart: number): PeriodRange {
    const range: PeriodRange = new PeriodRange();
    if (type === PeriodType.TODAY) {
      range.startMs = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0).getTime();
      range.endMs = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999).getTime();
      range.label = '今天';
      return range;
    }
    if (type === PeriodType.WEEK) {
      const start: Date = DateUtil.startOfWeek(now, weekStart);
      const end: Date = new Date(start.getFullYear(), start.getMonth(), start.getDate() + 6, 23, 59, 59, 999);
      range.startMs = start.getTime();
      range.endMs = end.getTime();
      range.label = '本周';
      return range;
    }
    if (type === PeriodType.MONTH) {
      range.startMs = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0, 0).getTime();
      range.endMs = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999).getTime();
      range.label = (now.getMonth() + 1).toString().concat('月');
      return range;
    }
    if (type === PeriodType.YEAR) {
      range.startMs = new Date(now.getFullYear(), 0, 1, 0, 0, 0, 0).getTime();
      range.endMs = new Date(now.getFullYear(), 11, 31, 23, 59, 59, 999).getTime();
      range.label = now.getFullYear().toString().concat('年');
      return range;
    }
    if (type === PeriodType.ALL) {
      range.startMs = 0;
      range.endMs = now.getTime();
      range.label = '全部';
      return range;
    }
    range.startMs = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0).getTime();
    range.endMs = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999).getTime();
    range.label = '自定义';
    return range;
  }

  static custom(startDayKey: string, endDayKey: string): PeriodRange {
    const start: Date = DateUtil.parseDayKey(startDayKey);
    const endBase: Date = DateUtil.parseDayKey(endDayKey);
    if (start.getTime() > endBase.getTime()) {
      throw new Error('开始日期不能晚于结束日期');
    }
    const range: PeriodRange = new PeriodRange();
    range.startMs = new Date(start.getFullYear(), start.getMonth(), start.getDate(), 0, 0, 0, 0).getTime();
    range.endMs = new Date(endBase.getFullYear(), endBase.getMonth(), endBase.getDate(), 23, 59, 59, 999).getTime();
    range.label = PeriodResolver.shortDay(startDayKey).concat('–').concat(PeriodResolver.shortDay(endDayKey));
    return range;
  }

  static bucketGranularity(range: PeriodRange): BucketGranularity {
    const start: number = range.startMs;
    const end: number = range.endMs;
    const days: number = Math.floor((end - start) / DAY_MS) + 1;
    if (days <= 31) {
      return BucketGranularity.DAY;
    }
    if (days <= 120) {
      return BucketGranularity.WEEK;
    }
    return BucketGranularity.MONTH;
  }

  static shortDay(dayKey: string): string {
    const parts: string[] = dayKey.split('-');
    if (parts.length !== 3) {
      return dayKey;
    }
    return Number(parts[1]).toString().concat('月').concat(Number(parts[2]).toString()).concat('日');
  }
}
