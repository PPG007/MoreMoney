import { describe, expect, it } from '@ohos/hypium';
import { CsvExportRow, CsvFormat } from '../main/ets/service/CsvFormat';

export default function csvFormatTest() {
  describe('CsvFormat', () => {
    it('escapes commas, quotes and newlines', 0, () => {
      expect(CsvFormat.escape('午餐,饮料')).assertEqual('"午餐,饮料"');
      expect(CsvFormat.escape('说"你好"')).assertEqual('"说""你好"""');
      expect(CsvFormat.escape('第一行\n第二行')).assertEqual('"第一行\n第二行"');
      expect(CsvFormat.escape('普通备注')).assertEqual('普通备注');
    });

    it('escapes formula injection', 0, () => {
      expect(CsvFormat.escape('=SUM(A1)')).assertEqual("'=SUM(A1)");
      expect(CsvFormat.escape('+1')).assertEqual("'+1");
      expect(CsvFormat.escape('-1')).assertEqual("'-1");
      expect(CsvFormat.escape('@cmd')).assertEqual("'@cmd");
    });

    it('formats amounts and dates', 0, () => {
      expect(CsvFormat.formatAmount(3200)).assertEqual('32.00');
      expect(CsvFormat.formatAmount(5)).assertEqual('0.05');
      const time: number = new Date(2026, 10, 9, 12, 30, 0, 0).getTime();
      expect(CsvFormat.dateText(time)).assertEqual('2026-11-09');
      expect(CsvFormat.timeText(time)).assertEqual('12:30');
    });

    it('builds header with bom and crlf', 0, () => {
      const row: CsvExportRow = new CsvExportRow();
      row.date = '2026-11-09';
      row.time = '12:30';
      row.type = 'expense';
      row.book = '日常账本';
      row.group = '餐饮';
      row.category = '餐饮';
      row.member = '自己';
      row.amount = '32.00';
      row.note = '午餐';
      row.id = 'txn_1';
      const text: string = CsvFormat.build([row]);
      expect(text.startsWith('\uFEFFdate,time,type,book,group,category,member,amount,note,id\r\n')).assertTrue();
      expect(text.endsWith('\r\n')).assertTrue();
      expect(text.indexOf('2026-11-09,12:30,expense,日常账本,餐饮,餐饮,自己,32.00,午餐,txn_1')).assertTrue();
    });
  });
}
