import { describe, expect, it } from '@ohos/hypium';
import { CsvParser, CsvRow, CsvSyntaxError } from '../main/ets/service/CsvParser';

export default function csvParserTest() {
  describe('CsvParser', () => {
    it('parses simple rows', 0, () => {
      const rows: CsvRow[] = CsvParser.parse('a,b\nc,d\n');
      expect(rows.length).assertEqual(2);
      expect(rows[0].cells.join('|')).assertEqual('a|b');
      expect(rows[1].cells.join('|')).assertEqual('c|d');
      expect(rows[0].lineNumber).assertEqual(1);
      expect(rows[1].lineNumber).assertEqual(2);
    });

    it('parses quoted commas, quotes and newlines', 0, () => {
      const rows: CsvRow[] = CsvParser.parse('"a,b","say ""hi""","line1\nline2"\n');
      expect(rows.length).assertEqual(1);
      expect(rows[0].cells.length).assertEqual(3);
      expect(rows[0].cells[0]).assertEqual('a,b');
      expect(rows[0].cells[1]).assertEqual('say "hi"');
      expect(rows[0].cells[2]).assertEqual('line1\nline2');
    });

    it('parses crlf and skips blank lines', 0, () => {
      const rows: CsvRow[] = CsvParser.parse('a,b\r\n\r\nc,d\r\n');
      expect(rows.length).assertEqual(2);
      expect(rows[0].cells.join('|')).assertEqual('a|b');
      expect(rows[1].cells.join('|')).assertEqual('c|d');
    });

    it('reports unclosed quote', 0, () => {
      let failed: boolean = false;
      let line: number = 0;
      try {
        CsvParser.parse('a,"b\nc');
      } catch (error) {
        if (error instanceof CsvSyntaxError) {
          failed = true;
          line = error.line;
        }
      }
      expect(failed).assertTrue();
      expect(line).assertEqual(1);
    });

    it('reports text after closing quote', 0, () => {
      let failed: boolean = false;
      try {
        CsvParser.parse('a,"b"x\n');
      } catch (error) {
        failed = error instanceof CsvSyntaxError;
      }
      expect(failed).assertTrue();
    });

    it('keeps empty cells', 0, () => {
      const rows: CsvRow[] = CsvParser.parse('a,,c\n');
      expect(rows.length).assertEqual(1);
      expect(rows[0].cells.length).assertEqual(3);
      expect(rows[0].cells[1]).assertEqual('');
    });
  });
}
