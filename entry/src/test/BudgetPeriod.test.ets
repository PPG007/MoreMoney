import { describe, expect, it } from '@ohos/hypium';
import { BudgetPeriod, BudgetPeriodType } from '../main/ets/service/BudgetPeriod';
import { DateRange, DateUtil } from '../main/ets/utils/DateUtil';

export default function budgetPeriodTest() {
  describe('BudgetPeriod', () => {
    it('builds month keys and shifts across years', 0, () => {
      const now: Date = new Date(2026, 10, 11, 15, 30, 0, 0);
      expect(BudgetPeriod.current(BudgetPeriodType.MONTH, now, 1)).assertEqual('2026-11');
      expect(BudgetPeriod.shift(BudgetPeriodType.MONTH, '2026-12', 1, 1)).assertEqual('2027-01');
      expect(BudgetPeriod.label(BudgetPeriodType.MONTH, '2026-11')).assertEqual('11月');
    });

    it('builds week keys with monday and sunday starts', 0, () => {
      const now: Date = new Date(2026, 10, 11, 15, 30, 0, 0);
      expect(BudgetPeriod.current(BudgetPeriodType.WEEK, now, 1)).assertEqual('W2026-11-09');
      expect(BudgetPeriod.current(BudgetPeriodType.WEEK, now, 7)).assertEqual('W2026-11-08');
    });

    it('shifts weeks across month boundaries', 0, () => {
      expect(BudgetPeriod.shift(BudgetPeriodType.WEEK, 'W2026-11-09', 1, 1)).assertEqual('W2026-11-16');
      expect(BudgetPeriod.shift(BudgetPeriodType.WEEK, 'W2026-11-09', -1, 1)).assertEqual('W2026-11-02');
      expect(BudgetPeriod.shift(BudgetPeriodType.WEEK, 'W2026-10-26', 1, 1)).assertEqual('W2026-11-02');
    });

    it('resolves week and year ranges', 0, () => {
      const week: DateRange = BudgetPeriod.range(BudgetPeriodType.WEEK, 'W2026-11-09', 1);
      expect(DateUtil.dayKey(new Date(week.startMs))).assertEqual('2026-11-09');
      expect(DateUtil.dayKey(new Date(week.endMs))).assertEqual('2026-11-15');
      const year: DateRange = BudgetPeriod.range(BudgetPeriodType.YEAR, 'Y2026', 1);
      expect(DateUtil.dayKey(new Date(year.startMs))).assertEqual('2026-01-01');
      expect(DateUtil.dayKey(new Date(year.endMs))).assertEqual('2026-12-31');
    });

    it('builds year keys and shifts years', 0, () => {
      const now: Date = new Date(2026, 10, 11, 15, 30, 0, 0);
      expect(BudgetPeriod.current(BudgetPeriodType.YEAR, now, 1)).assertEqual('Y2026');
      expect(BudgetPeriod.shift(BudgetPeriodType.YEAR, 'Y2026', 1, 1)).assertEqual('Y2027');
      expect(BudgetPeriod.label(BudgetPeriodType.YEAR, 'Y2026')).assertEqual('2026年');
    });

    it('formats week labels inside and across months', 0, () => {
      expect(BudgetPeriod.label(BudgetPeriodType.WEEK, 'W2026-11-09')).assertEqual('11月9日–15日');
      expect(BudgetPeriod.label(BudgetPeriodType.WEEK, 'W2026-11-30')).assertEqual('11月30日–12月6日');
    });

    it('uses period nouns for copy', 0, () => {
      expect(BudgetPeriod.noun(BudgetPeriodType.WEEK)).assertEqual('本周');
      expect(BudgetPeriod.noun(BudgetPeriodType.MONTH)).assertEqual('本月');
      expect(BudgetPeriod.noun(BudgetPeriodType.YEAR)).assertEqual('本年');
    });

    it('maps period type indexes', 0, () => {
      expect(BudgetPeriod.at(0)).assertEqual(BudgetPeriodType.WEEK);
      expect(BudgetPeriod.at(1)).assertEqual(BudgetPeriodType.MONTH);
      expect(BudgetPeriod.at(2)).assertEqual(BudgetPeriodType.YEAR);
      expect(BudgetPeriod.indexOf(BudgetPeriodType.WEEK)).assertEqual(0);
      expect(BudgetPeriod.indexOf(BudgetPeriodType.MONTH)).assertEqual(1);
      expect(BudgetPeriod.indexOf(BudgetPeriodType.YEAR)).assertEqual(2);
    });

    it('validates budgets across periods', 0, () => {
      expect(BudgetPeriod.validate(0, 0, 0)).assertEqual('');
      expect(BudgetPeriod.validate(10000, 40000, 0)).assertEqual('');
      expect(BudgetPeriod.validate(10001, 40000, 0)).assertEqual('周预算 × 4 不能超过月预算');
      expect(BudgetPeriod.validate(0, 100000, 1200000)).assertEqual('');
      expect(BudgetPeriod.validate(0, 100001, 1200000)).assertEqual('月预算 × 12 不能超过年预算');
      expect(BudgetPeriod.validate(10000, 0, 520000)).assertEqual('');
      expect(BudgetPeriod.validate(10001, 0, 520000)).assertEqual('周预算 × 52 不能超过年预算');
    });

    it('keeps the viewed date when it falls inside the period', 0, () => {
      const now: Date = new Date(2026, 10, 11, 15, 30, 0, 0);
      expect(DateUtil.dayKey(BudgetPeriod.anchor(BudgetPeriodType.WEEK, 'W2026-11-09', 1, now)))
        .assertEqual('2026-11-11');
      expect(DateUtil.dayKey(BudgetPeriod.anchor(BudgetPeriodType.MONTH, '2026-10', 1, now)))
        .assertEqual('2026-10-01');
    });

    it('counts remaining days including today', 0, () => {
      const now: Date = new Date(2026, 10, 11, 15, 30, 0, 0);
      expect(BudgetPeriod.daysLeft(BudgetPeriodType.WEEK, 'W2026-11-09', 1, now)).assertEqual(5);
      expect(BudgetPeriod.daysLeft(BudgetPeriodType.MONTH, '2026-11', 1, now)).assertEqual(20);
      expect(BudgetPeriod.daysLeft(BudgetPeriodType.YEAR, 'Y2026', 1, now)).assertEqual(51);
      expect(BudgetPeriod.daysLeft(BudgetPeriodType.WEEK, 'W2026-11-02', 1, now)).assertEqual(1);
    });
  });
}
