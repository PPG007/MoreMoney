export class BackupLine {
  type: string = '';
  cells: string[] = [];
}

export class BackupCounts {
  books: number = 0;
  members: number = 0;
  categories: number = 0;
  txns: number = 0;
  budgets: number = 0;
  privateBooks: number = 0;
}

export class BackupDocument {
  format: number = 0;
  schemaVersion: number = 0;
  createdAt: number = 0;
  appVersion: string = '';
  counts: BackupCounts = new BackupCounts();
  checksum: string = '';
  body: string = '';
  lines: BackupLine[] = [];
  rawText: string = '';
}

const MAGIC: string = 'MOREMONEY_BACKUP';
const FORMAT_VERSION: number = 1;
const SCHEMA_VERSION: number = 1;

export class BackupFormat {
  static buildBody(lines: BackupLine[]): string {
    const parts: string[] = [];
    for (const line of lines) {
      parts.push(line.type.concat('\t').concat(line.cells.join('\t')));
    }
    return parts.join('\n');
  }

  static wrap(body: string, checksum: string, counts: BackupCounts, createdAt: number,
    appVersion: string): string {
    const header: string[] = [
      MAGIC,
      'format='.concat(FORMAT_VERSION.toString()),
      'schemaVersion='.concat(SCHEMA_VERSION.toString()),
      'createdAt='.concat(createdAt.toString()),
      'appVersion='.concat(appVersion),
      'books='.concat(counts.books.toString()),
      'members='.concat(counts.members.toString()),
      'categories='.concat(counts.categories.toString()),
      'txns='.concat(counts.txns.toString()),
      'budgets='.concat(counts.budgets.toString()),
      'privateBooks='.concat(counts.privateBooks.toString()),
      'checksum='.concat(checksum)
    ];
    return header.join('\n').concat('\n[BODY]\n').concat(body).concat('\n[END]\n');
  }

  static parse(text: string): BackupDocument {
    const doc: BackupDocument = new BackupDocument();
    doc.rawText = text;
    const lines: string[] = text.split('\n');
    if (lines.length === 0 || lines[0].trim() !== MAGIC) {
      throw new Error('不是有效的 MoreMoney 备份文件');
    }
    let bodyStart: number = -1;
    let bodyEnd: number = -1;
    for (let i = 1; i < lines.length; i++) {
      const line: string = lines[i].trim();
      if (line === '[BODY]') {
        bodyStart = i + 1;
        break;
      }
      BackupFormat.applyHeader(doc, line);
    }
    if (bodyStart < 0) {
      throw new Error('备份文件缺少数据段');
    }
    for (let i = bodyStart; i < lines.length; i++) {
      if (lines[i].trim() === '[END]') {
        bodyEnd = i;
        break;
      }
    }
    if (bodyEnd < 0) {
      throw new Error('备份文件缺少结束标记');
    }
    if (doc.format !== FORMAT_VERSION) {
      throw new Error('不支持的备份格式版本');
    }
    if (doc.schemaVersion !== SCHEMA_VERSION) {
      throw new Error('备份数据版本不兼容，请升级应用');
    }
    if (doc.checksum.length === 0) {
      throw new Error('备份文件缺少校验和');
    }
    const bodyLines: string[] = [];
    for (let i = bodyStart; i < bodyEnd; i++) {
      bodyLines.push(lines[i]);
    }
    doc.body = bodyLines.join('\n');
    doc.lines = BackupFormat.parseBody(doc.body);
    return doc;
  }

  static parseBody(body: string): BackupLine[] {
    const result: BackupLine[] = [];
    if (body.length === 0) {
      return result;
    }
    const rawLines: string[] = body.split('\n');
    for (const raw of rawLines) {
      if (raw.length === 0) {
        continue;
      }
      const cells: string[] = raw.split('\t');
      const line: BackupLine = new BackupLine();
      line.type = cells[0];
      line.cells = cells.slice(1);
      result.push(line);
    }
    return result;
  }

  static isKnownType(type: string): boolean {
    return type === 'BOOK' || type === 'MEMBER' || type === 'GROUP' || type === 'CATEGORY' ||
      type === 'TXN' || type === 'BUDGET' || type === 'PRIVATE';
  }

  private static applyHeader(doc: BackupDocument, line: string): void {
    if (line.length === 0) {
      return;
    }
    const index: number = line.indexOf('=');
    if (index < 0) {
      return;
    }
    const key: string = line.substring(0, index);
    const value: string = line.substring(index + 1);
    if (key === 'format') {
      doc.format = Number(value);
    } else if (key === 'schemaVersion') {
      doc.schemaVersion = Number(value);
    } else if (key === 'createdAt') {
      doc.createdAt = Number(value);
    } else if (key === 'appVersion') {
      doc.appVersion = value;
    } else if (key === 'books') {
      doc.counts.books = Number(value);
    } else if (key === 'members') {
      doc.counts.members = Number(value);
    } else if (key === 'categories') {
      doc.counts.categories = Number(value);
    } else if (key === 'txns') {
      doc.counts.txns = Number(value);
    } else if (key === 'budgets') {
      doc.counts.budgets = Number(value);
    } else if (key === 'privateBooks') {
      doc.counts.privateBooks = Number(value);
    } else if (key === 'checksum') {
      doc.checksum = value.trim();
    }
  }
}
