export class CsvRow {
  cells: string[] = [];
  lineNumber: number = 0;
}

export class CsvSyntaxError extends Error {
  line: number = 0;

  constructor(message: string, line: number) {
    super(message);
    this.line = line;
  }
}

export class CsvParser {
  static parse(text: string): CsvRow[] {
    const rows: CsvRow[] = [];
    let cells: string[] = [];
    let field: string = '';
    let inQuotes: boolean = false;
    let afterQuote: boolean = false;
    let line: number = 1;
    let rowStart: number = 1;
    let i: number = 0;

    while (i < text.length) {
      const ch: string = text.substring(i, i + 1);
      if (inQuotes) {
        if (ch === '"') {
          const next: string = text.substring(i + 1, i + 2);
          if (next === '"') {
            field = field.concat('"');
            i += 2;
          } else {
            inQuotes = false;
            afterQuote = true;
            i += 1;
          }
        } else {
          if (ch === '\n') {
            line += 1;
          }
          field = field.concat(ch);
          i += 1;
        }
        continue;
      }
      if (afterQuote) {
        if (ch === ',') {
          cells.push(field);
          field = '';
          afterQuote = false;
          i += 1;
        } else if (ch === '\r' || ch === '\n') {
          cells.push(field);
          field = '';
          afterQuote = false;
          CsvParser.pushRow(rows, cells, rowStart);
          cells = [];
          if (ch === '\r' && text.substring(i + 1, i + 2) === '\n') {
            i += 2;
          } else {
            i += 1;
          }
          line += 1;
          rowStart = line;
        } else {
          throw new CsvSyntaxError('引号后出现非法字符', line);
        }
        continue;
      }
      if (ch === '"' && field.length === 0) {
        inQuotes = true;
        i += 1;
        continue;
      }
      if (ch === ',') {
        cells.push(field);
        field = '';
        i += 1;
        continue;
      }
      if (ch === '\r' || ch === '\n') {
        cells.push(field);
        field = '';
        CsvParser.pushRow(rows, cells, rowStart);
        cells = [];
        if (ch === '\r' && text.substring(i + 1, i + 2) === '\n') {
          i += 2;
        } else {
          i += 1;
        }
        line += 1;
        rowStart = line;
        continue;
      }
      field = field.concat(ch);
      i += 1;
    }

    if (inQuotes) {
      throw new CsvSyntaxError('引号未闭合', rowStart);
    }
    if (afterQuote || field.length > 0 || cells.length > 0) {
      cells.push(field);
      CsvParser.pushRow(rows, cells, rowStart);
    }
    return rows;
  }

  private static pushRow(rows: CsvRow[], cells: string[], lineNumber: number): void {
    if (cells.length === 1 && cells[0].length === 0) {
      return;
    }
    const row: CsvRow = new CsvRow();
    row.cells = cells;
    row.lineNumber = lineNumber;
    rows.push(row);
  }
}
