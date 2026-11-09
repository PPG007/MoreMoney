export class CsvExportRow {
  date: string = '';
  time: string = '';
  type: string = 'expense';
  book: string = '';
  group: string = '';
  category: string = '';
  member: string = '';
  amount: string = '';
  note: string = '';
  id: string = '';
}

export class CsvFormat {
  static readonly header: string = 'date,time,type,book,group,category,member,amount,note,id';
  static readonly bom: string = '\uFEFF';
  static readonly crlf: string = '\r\n';

  static escape(field: string): string {
    let value: string = field;
    const first: string = value.length > 0 ? value.substring(0, 1) : '';
    if (first === '=' || first === '+' || first === '-' || first === '@') {
      value = '\''.concat(value);
    }
    let needsQuote: boolean = false;
    for (let i = 0; i < value.length; i++) {
      const ch: string = value.substring(i, i + 1);
      if (ch === ',' || ch === '"' || ch === '\n' || ch === '\r') {
        needsQuote = true;
        break;
      }
    }
    if (needsQuote) {
      return '"'.concat(value.replace(/"/g, '""')).concat('"');
    }
    return value;
  }

  static row(item: CsvExportRow): string {
    const cells: string[] = [item.date, item.time, item.type, item.book, item.group, item.category,
      item.member, item.amount, item.note, item.id];
    const escaped: string[] = [];
    for (const cell of cells) {
      escaped.push(CsvFormat.escape(cell));
    }
    return escaped.join(',');
  }

  static build(rows: CsvExportRow[]): string {
    let text: string = CsvFormat.bom.concat(CsvFormat.header).concat(CsvFormat.crlf);
    for (const row of rows) {
      text = text.concat(CsvFormat.row(row)).concat(CsvFormat.crlf);
    }
    return text;
  }

  static formatAmount(cents: number): string {
    const abs: number = Math.abs(Math.round(cents));
    const yuan: number = Math.floor(abs / 100);
    const fraction: number = abs % 100;
    return yuan.toString().concat('.').concat(fraction.toString().padStart(2, '0'));
  }

  static pad2(value: number): string {
    return value.toString().padStart(2, '0');
  }

  static dateText(timestamp: number): string {
    const date: Date = new Date(timestamp);
    return date.getFullYear().toString().concat('-').concat(CsvFormat.pad2(date.getMonth() + 1))
      .concat('-').concat(CsvFormat.pad2(date.getDate()));
  }

  static timeText(timestamp: number): string {
    const date: Date = new Date(timestamp);
    return CsvFormat.pad2(date.getHours()).concat(':').concat(CsvFormat.pad2(date.getMinutes()));
  }

  static fileName(timestamp: number): string {
    const date: Date = new Date(timestamp);
    return 'MoreMoney_'.concat(date.getFullYear().toString())
      .concat(CsvFormat.pad2(date.getMonth() + 1))
      .concat(CsvFormat.pad2(date.getDate()))
      .concat('_')
      .concat(CsvFormat.pad2(date.getHours()))
      .concat(CsvFormat.pad2(date.getMinutes()))
      .concat('.csv');
  }
}
