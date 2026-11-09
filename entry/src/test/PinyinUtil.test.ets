import { describe, expect, it } from '@ohos/hypium';
import { pinyinKey } from '../main/ets/utils/PinyinUtil';

export default function pinyinUtilTest() {
  describe('PinyinUtil', () => {
    it('transliterates chinese names', 0, () => {
      expect(pinyinKey('餐饮')).assertEqual('canyin');
      expect(pinyinKey('出行')).assertEqual('chuxing');
    });

    it('keeps english and numbers lowercase', 0, () => {
      expect(pinyinKey('Food')).assertEqual('food');
      expect(pinyinKey('123')).assertEqual('123');
      expect(pinyinKey('A1')).assertEqual('a1');
    });

    it('handles empty and spaces', 0, () => {
      expect(pinyinKey('')).assertEqual('');
      expect(pinyinKey('   ')).assertEqual('');
    });
  });
}
