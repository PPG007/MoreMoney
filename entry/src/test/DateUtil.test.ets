import { describe, expect, it } from '@ohos/hypium';
import { DateUtil, DateRange } from '../main/ets/utils/DateUtil';

export default function dateUtilTest() {
  describe('DateUtil', () => {
    it('formats day and month keys', 0, () => {
      const date: Date = new Date(2026, 10, 9, 15, 30, 0, 0);
      expect(DateUtil.dayKey(date)).assertEqual('2026-11-09');
      expect(DateUtil.monthKey(date)).assertEqual('2026-11');
      expect(DateUtil.formatMonthCn('2026-11')).assertEqual('11月');
      expect(DateUtil.formatDayCn('2026-11-09')).assertEqual('11月9日 周一');
    });

    it('computes days in month including leap years', 0, () => {
      expect(DateUtil.daysInMonth(2026, 2)).assertEqual(28);
      expect(DateUtil.daysInMonth(2024, 2)).assertEqual(29);
      expect(DateUtil.daysInMonth(2026, 11)).assertEqual(30);
      expect(DateUtil.daysInMonth(2026, 12)).assertEqual(31);
    });

    it('computes week start for monday and sunday', 0, () => {
      const date: Date = new Date(2026, 10, 9, 15, 30, 0, 0);
      expect(DateUtil.dayKey(DateUtil.startOfWeek(date, 1))).assertEqual('2026-11-09');
      expect(DateUtil.dayKey(DateUtil.startOfWeek(date, 7))).assertEqual('2026-11-08');
      const sunday: Date = new Date(2026, 10, 8, 10, 0, 0, 0);
      expect(DateUtil.dayKey(DateUtil.startOfWeek(sunday, 1))).assertEqual('2026-11-02');
    });

    it('resolves month range boundaries', 0, () => {
      const range: DateRange = DateUtil.rangeOfMonth('2026-02');
      expect(DateUtil.dayKey(new Date(range.startMs))).assertEqual('2026-02-01');
      expect(DateUtil.dayKey(new Date(range.endMs))).assertEqual('2026-02-28');
      expect(new Date(range.startMs).getHours()).assertEqual(0);
      expect(new Date(range.endMs).getHours()).assertEqual(23);
    });

    it('adds months across year boundary', 0, () => {
      expect(DateUtil.addMonths('2026-01', -1)).assertEqual('2025-12');
      expect(DateUtil.addMonths('2026-12', 1)).assertEqual('2027-01');
      expect(DateUtil.addMonths('2026-11', 2)).assertEqual('2027-01');
    });

    it('parses day keys to local dates', 0, () => {
      const date: Date = DateUtil.parseDayKey('2026-11-09');
      expect(date.getFullYear()).assertEqual(2026);
      expect(date.getMonth()).assertEqual(10);
      expect(date.getDate()).assertEqual(9);
      expect(DateUtil.dayKey(DateUtil.parseDayKey('bad'))).assertEqual('1970-01-01');
    });
  });
}
