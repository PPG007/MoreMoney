import { describe, expect, it } from '@ohos/hypium';
import { BackupCounts, BackupDocument, BackupFormat, BackupLine } from '../main/ets/service/BackupFormat';

function sampleLine(): BackupLine {
  const line: BackupLine = new BackupLine();
  line.type = 'BOOK';
  line.cells = ['aWQ=', '5pel5bi46LSm5pys', 'aWNfYm9va19kYWlseQ==', 'IzJBNzhENg==', '0', '', '',
    '10000', '1', '0', '0', '1', '2'];
  return line;
}

export default function backupFormatTest() {
  describe('BackupFormat', () => {
    it('builds body text in order', 0, () => {
      const body: string = BackupFormat.buildBody([sampleLine()]);
      expect(body.startsWith('BOOK\taWQ=\t5pel5bi46LSm5pys')).assertTrue();
      expect(body.indexOf('\t10000\t1\t0\t0\t1\t2')).assertTrue();
    });

    it('wraps and parses document', 0, () => {
      const counts: BackupCounts = new BackupCounts();
      counts.books = 3;
      counts.members = 2;
      counts.categories = 9;
      counts.txns = 128;
      counts.budgets = 2;
      counts.privateBooks = 1;
      const body: string = BackupFormat.buildBody([sampleLine()]);
      const text: string = BackupFormat.wrap(body, 'abcdef', counts, 1762656000000, '1.0.0');
      const doc: BackupDocument = BackupFormat.parse(text);
      expect(doc.format).assertEqual(1);
      expect(doc.schemaVersion).assertEqual(1);
      expect(doc.createdAt).assertEqual(1762656000000);
      expect(doc.appVersion).assertEqual('1.0.0');
      expect(doc.counts.books).assertEqual(3);
      expect(doc.counts.txns).assertEqual(128);
      expect(doc.checksum).assertEqual('abcdef');
      expect(doc.body).assertEqual(body);
      expect(doc.lines.length).assertEqual(1);
      expect(doc.lines[0].type).assertEqual('BOOK');
      expect(doc.lines[0].cells.length).assertEqual(12);
    });

    it('keeps multiline body identical', 0, () => {
      const body: string = 'TXN\tYQ==\tYg==\tc3RhcnQ=\nMEMBER\tYw==\tZA==\teQ==\teg==\t0\t0\t0';
      const counts: BackupCounts = new BackupCounts();
      const text: string = BackupFormat.wrap(body, 'x', counts, 0, '1.0.0');
      const doc: BackupDocument = BackupFormat.parse(text);
      expect(doc.body).assertEqual(body);
      expect(doc.lines.length).assertEqual(2);
    });

    it('rejects invalid magic', 0, () => {
      let failed: boolean = false;
      try {
        BackupFormat.parse('NOT_A_BACKUP\n');
      } catch (error) {
        failed = true;
      }
      expect(failed).assertTrue();
    });

    it('rejects unsupported schema version', 0, () => {
      const counts: BackupCounts = new BackupCounts();
      const text: string = BackupFormat.wrap('body', 'x', counts, 0, '1.0.0').replace('schemaVersion=1',
        'schemaVersion=9');
      let failed: boolean = false;
      try {
        BackupFormat.parse(text);
      } catch (error) {
        failed = true;
      }
      expect(failed).assertTrue();
    });

    it('rejects missing body marker', 0, () => {
      let failed: boolean = false;
      try {
        BackupFormat.parse('MOREMONEY_BACKUP\nformat=1\n');
      } catch (error) {
        failed = true;
      }
      expect(failed).assertTrue();
    });

    it('ignores unknown line types on parse', 0, () => {
      const body: string = 'UNKNOWN\ta\nBOOK\tb';
      const counts: BackupCounts = new BackupCounts();
      const doc: BackupDocument = BackupFormat.parse(BackupFormat.wrap(body, 'x', counts, 0, '1.0.0'));
      expect(doc.lines.length).assertEqual(2);
      expect(BackupFormat.isKnownType(doc.lines[0].type)).assertFalse();
    });
  });
}
