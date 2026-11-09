export class MoneyFormatOptions {
  symbol: boolean = true;
  grouping: boolean = true;
}

export function roundHalfUp(value: number): number {
  if (value >= 0) {
    return Math.floor(value + 0.5);
  }
  return -Math.floor(-value + 0.5);
}

export function formatCents(cents: number, options?: MoneyFormatOptions): string {
  const opts: MoneyFormatOptions = options === undefined ? new MoneyFormatOptions() : options;
  const negative: boolean = cents < 0;
  const abs: number = Math.abs(roundHalfUp(cents));
  const yuan: number = Math.floor(abs / 100);
  const fraction: number = abs % 100;
  const yuanText: string = opts.grouping ? groupDigits(yuan) : yuan.toString();
  const fractionText: string = fraction.toString().padStart(2, '0');
  const prefix: string = negative ? '−' : '';
  const symbol: string = opts.symbol ? '¥' : '';
  return prefix.concat(symbol).concat(yuanText).concat('.').concat(fractionText);
}

export function formatYuan(cents: number): string {
  const negative: boolean = cents < 0;
  const abs: number = Math.abs(roundHalfUp(cents));
  const yuan: number = Math.floor(abs / 100);
  const fraction: number = abs % 100;
  const prefix: string = negative ? '−' : '';
  return prefix.concat(yuan.toString()).concat('.').concat(fraction.toString().padStart(2, '0'));
}

export function parseYuanToCents(text: string): number | null {
  const raw: string = text.trim();
  if (raw.length === 0) {
    return null;
  }
  let intPart: string = '';
  let fracPart: string = '';
  let dotSeen: boolean = false;
  let digits: number = 0;
  for (let i = 0; i < raw.length; i++) {
    const ch: string = raw.substring(i, i + 1);
    if (ch === '.') {
      if (dotSeen) {
        return null;
      }
      dotSeen = true;
      continue;
    }
    if (ch < '0' || ch > '9') {
      return null;
    }
    digits += 1;
    if (dotSeen) {
      fracPart = fracPart.concat(ch);
    } else {
      intPart = intPart.concat(ch);
    }
  }
  if (digits === 0 || fracPart.length > 2) {
    return null;
  }
  if (intPart.length === 0) {
    const whole: number = Number(fracPart);
    if (Number.isNaN(whole)) {
      return null;
    }
    return whole * 100;
  }
  const yuan: number = Number(intPart);
  if (Number.isNaN(yuan)) {
    return null;
  }
  const frac: number = fracPart.length === 0 ? 0 : Number(fracPart.padEnd(2, '0'));
  if (Number.isNaN(frac)) {
    return null;
  }
  return yuan * 100 + frac;
}

export function yuanTextToCents(text: string): number | null {
  return parseYuanToCents(text);
}

function groupDigits(value: number): string {
  const text: string = value.toString();
  let result: string = '';
  let count: number = 0;
  for (let i = text.length - 1; i >= 0; i--) {
    result = text.substring(i, i + 1).concat(result);
    count += 1;
    if (count % 3 === 0 && i > 0) {
      result = ','.concat(result);
    }
  }
  return result;
}
