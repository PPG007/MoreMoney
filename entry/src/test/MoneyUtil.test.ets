import { describe, expect, it } from '@ohos/hypium';
import { formatCents, formatYuan, MoneyFormatOptions, parseYuanToCents, roundHalfUp } from '../main/ets/utils/MoneyUtil';

export default function moneyUtilTest() {
  describe('MoneyUtil', () => {
    it('formats cents with symbol and grouping', 0, () => {
      expect(formatCents(128640)).assertEqual('¥1,286.40');
      const options: MoneyFormatOptions = new MoneyFormatOptions();
      options.symbol = false;
      expect(formatCents(128640, options)).assertEqual('1,286.40');
      expect(formatCents(0)).assertEqual('¥0.00');
      expect(formatCents(-1200)).assertEqual('−¥12.00');
    });

    it('formats yuan for input without symbol', 0, () => {
      expect(formatYuan(1230)).assertEqual('12.30');
      expect(formatYuan(5)).assertEqual('0.05');
    });

    it('parses yuan text to cents', 0, () => {
      expect(parseYuanToCents('12.3')).assertEqual(1230);
      expect(parseYuanToCents('.5')).assertEqual(500);
      expect(parseYuanToCents('12')).assertEqual(1200);
      expect(parseYuanToCents('12.345')).assertNull();
      expect(parseYuanToCents('-1')).assertNull();
      expect(parseYuanToCents('abc')).assertNull();
      expect(parseYuanToCents('')).assertNull();
      expect(parseYuanToCents('1.2.3')).assertNull();
    });

    it('rounds half up', 0, () => {
      expect(roundHalfUp(1.5)).assertEqual(2);
      expect(roundHalfUp(1.49)).assertEqual(1);
      expect(roundHalfUp(-1.5)).assertEqual(-2);
      expect(roundHalfUp(-1.49)).assertEqual(-1);
    });
  });
}
