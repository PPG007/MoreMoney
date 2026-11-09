import { describe, expect, it } from '@ohos/hypium';
import { PeriodResolver } from '../main/ets/service/PeriodResolver';
import { BucketGranularity, PeriodRange, PeriodType } from '../main/ets/models/StatsTypes';
import { DateUtil } from '../main/ets/utils/DateUtil';

export default function periodResolverTest() {
  describe('PeriodResolver', () => {
    it('resolves today boundaries', 0, () => {
      const now: Date = new Date(2026, 10, 9, 15, 30, 0, 0);
      const range: PeriodRange = PeriodResolver.resolve(PeriodType.TODAY, now, 1);
      expect(range.startMs).assertEqual(new Date(2026, 10, 9, 0, 0, 0, 0).getTime());
      expect(range.endMs).assertEqual(new Date(2026, 10, 9, 23, 59, 59, 999).getTime());
      expect(range.label).assertEqual('今天');
    });

    it('resolves week starting monday', 0, () => {
      const now: Date = new Date(2026, 10, 9, 15, 30, 0, 0);
      const range: PeriodRange = PeriodResolver.resolve(PeriodType.WEEK, now, 1);
      expect(DateUtil.dayKey(new Date(range.startMs))).assertEqual('2026-11-09');
      expect(DateUtil.dayKey(new Date(range.endMs))).assertEqual('2026-11-15');
    });

    it('resolves week starting sunday', 0, () => {
      const now: Date = new Date(2026, 10, 9, 15, 30, 0, 0);
      const range: PeriodRange = PeriodResolver.resolve(PeriodType.WEEK, now, 7);
      expect(DateUtil.dayKey(new Date(range.startMs))).assertEqual('2026-11-08');
      expect(DateUtil.dayKey(new Date(range.endMs))).assertEqual('2026-11-14');
    });

    it('resolves month boundaries including leap february', 0, () => {
      const normal: PeriodRange = PeriodResolver.resolve(PeriodType.MONTH, new Date(2026, 1, 15), 1);
      expect(DateUtil.dayKey(new Date(normal.startMs))).assertEqual('2026-02-01');
      expect(DateUtil.dayKey(new Date(normal.endMs))).assertEqual('2026-02-28');
      const leap: PeriodRange = PeriodResolver.resolve(PeriodType.MONTH, new Date(2024, 1, 15), 1);
      expect(DateUtil.dayKey(new Date(leap.endMs))).assertEqual('2024-02-29');
    });

    it('resolves year and all', 0, () => {
      const now: Date = new Date(2026, 10, 9, 15, 30, 0, 0);
      const year: PeriodRange = PeriodResolver.resolve(PeriodType.YEAR, now, 1);
      expect(DateUtil.dayKey(new Date(year.startMs))).assertEqual('2026-01-01');
      expect(DateUtil.dayKey(new Date(year.endMs))).assertEqual('2026-12-31');
      const all: PeriodRange = PeriodResolver.resolve(PeriodType.ALL, now, 1);
      expect(all.startMs).assertEqual(0);
      expect(all.endMs).assertEqual(now.getTime());
    });

    it('resolves cross-year custom range', 0, () => {
      const range: PeriodRange = PeriodResolver.custom('2025-12-20', '2026-01-10');
      const start: Date = new Date(range.startMs);
      const end: Date = new Date(range.endMs);
      const days: number = Math.floor((end.getTime() - start.getTime()) / (24 * 60 * 60 * 1000)) + 1;
      expect(DateUtil.dayKey(start)).assertEqual('2025-12-20');
      expect(DateUtil.dayKey(end)).assertEqual('2026-01-10');
      expect(days).assertEqual(22);
    });

    it('rejects reversed custom range', 0, () => {
      let failed: boolean = false;
      try {
        PeriodResolver.custom('2026-01-10', '2025-12-20');
      } catch (error) {
        failed = true;
      }
      expect(failed).assertTrue();
    });

    it('maps bucket granularity by range length', 0, () => {
      const month: PeriodRange = PeriodResolver.resolve(PeriodType.MONTH, new Date(2026, 10, 9), 1);
      expect(PeriodResolver.bucketGranularity(month)).assertEqual(BucketGranularity.DAY);
      const quarter: PeriodRange = PeriodResolver.custom('2026-09-01', '2026-11-30');
      expect(PeriodResolver.bucketGranularity(quarter)).assertEqual(BucketGranularity.WEEK);
      const longRange: PeriodRange = PeriodResolver.custom('2026-01-01', '2026-11-30');
      expect(PeriodResolver.bucketGranularity(longRange)).assertEqual(BucketGranularity.MONTH);
    });
  });
}
