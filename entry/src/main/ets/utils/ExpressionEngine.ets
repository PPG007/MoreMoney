import { CalcError, CalcPreview, CalcResult, Operator } from './CalcTypes';
import { formatCents, roundHalfUp } from './MoneyUtil';

const SCALE: number = 1000000;
const MAX_CENTS: number = 9999999999;
const MAX_EXPRESSION: number = 24;
const MAX_INT_DIGITS: number = 9;
const MAX_DECIMALS: number = 2;
const MAX_MICRO: number = 1e16;

class EvalValue {
  micro: number = 0;
  error: CalcError = CalcError.NONE;
}

export class CalcEngine {
  expression: string = '';

  appendDigit(d: string): void {
    if (d === '00') {
      this.appendDigit('0');
      this.appendDigit('0');
      return;
    }
    if (d.length !== 1) {
      return;
    }
    if (this.expression.length >= MAX_EXPRESSION) {
      return;
    }
    const segment: string = this.expression.substring(CalcEngine.numberStart(this.expression));
    if (d === '.') {
      if (segment.indexOf('.') >= 0) {
        return;
      }
      if (segment.length === 0) {
        this.expression = this.expression.concat('0.');
      } else {
        this.expression = this.expression.concat('.');
      }
      return;
    }
    if (d < '0' || d > '9') {
      return;
    }
    const dot: number = segment.indexOf('.');
    if (dot >= 0) {
      if (segment.length - dot - 1 >= MAX_DECIMALS) {
        return;
      }
    } else if (segment.length >= MAX_INT_DIGITS) {
      return;
    }
    this.expression = this.expression.concat(d);
  }

  appendOperator(op: Operator): void {
    if (op !== Operator.PLUS && op !== Operator.MINUS && op !== Operator.MULTIPLY && op !== Operator.DIVIDE) {
      return;
    }
    let expr: string = this.expression;
    if (expr.length === 0) {
      this.expression = '0'.concat(op);
      return;
    }
    if (expr.substring(expr.length - 1) === '.') {
      expr = expr.substring(0, expr.length - 1);
    }
    if (expr.length === 0) {
      this.expression = '0'.concat(op);
      return;
    }
    if (isOperatorChar(expr.substring(expr.length - 1))) {
      this.expression = expr.substring(0, expr.length - 1).concat(op);
      return;
    }
    if (expr.length >= MAX_EXPRESSION) {
      return;
    }
    this.expression = expr.concat(op);
  }

  backspace(): void {
    if (this.expression.length === 0) {
      return;
    }
    this.expression = this.expression.substring(0, this.expression.length - 1);
  }

  clear(): void {
    this.expression = '';
  }

  evaluate(): CalcResult {
    const result: CalcResult = new CalcResult();
    if (this.expression.length === 0) {
      result.error = CalcError.EMPTY;
      return result;
    }
    const evaluated: EvalValue = CalcEngine.evaluateExpression(this.expression);
    if (evaluated.error !== CalcError.NONE) {
      result.error = evaluated.error;
      return result;
    }
    const cents: number = roundHalfUp(evaluated.micro / 10000);
    if (cents < 0) {
      result.error = CalcError.NEGATIVE;
      return result;
    }
    if (cents === 0) {
      result.error = CalcError.ZERO;
      return result;
    }
    if (cents > MAX_CENTS) {
      result.error = CalcError.TOO_LARGE;
      return result;
    }
    result.ok = true;
    result.cents = cents;
    return result;
  }

  preview(): CalcPreview {
    const preview: CalcPreview = new CalcPreview();
    const result: CalcResult = this.evaluate();
    if (result.ok) {
      preview.text = '合计 '.concat(formatCents(result.cents));
      preview.valid = true;
      return preview;
    }
    if (result.error === CalcError.EMPTY) {
      preview.text = '请输入金额';
    } else if (result.error === CalcError.ZERO) {
      preview.text = '金额需大于 0';
    } else if (result.error === CalcError.NEGATIVE) {
      preview.text = '金额不能为负';
    } else {
      preview.text = '无法计算';
    }
    preview.valid = false;
    return preview;
  }

  private static numberStart(expr: string): number {
    for (let i = expr.length - 1; i >= 0; i--) {
      if (isOperatorChar(expr.substring(i, i + 1))) {
        return i + 1;
      }
    }
    return 0;
  }

  private static evaluateExpression(expr: string): EvalValue {
    const outcome: EvalValue = new EvalValue();
    const numbers: number[] = [];
    const operators: string[] = [];
    let i: number = 0;
    let expectNumber: boolean = true;
    while (i < expr.length) {
      const ch: string = expr.substring(i, i + 1);
      if (isOperatorChar(ch)) {
        if (expectNumber) {
          outcome.error = CalcError.INVALID;
          return outcome;
        }
        operators.push(ch);
        expectNumber = true;
        i += 1;
        continue;
      }
      let j: number = i;
      while (j < expr.length && !isOperatorChar(expr.substring(j, j + 1))) {
        j += 1;
      }
      const text: string = expr.substring(i, j);
      const micro: number = CalcEngine.parseMicro(text);
      if (micro < 0) {
        outcome.error = CalcError.INVALID;
        return outcome;
      }
      numbers.push(micro);
      expectNumber = false;
      i = j;
    }
    if (expectNumber || numbers.length === 0 || operators.length !== numbers.length - 1) {
      outcome.error = CalcError.INVALID;
      return outcome;
    }
    const values: number[] = [];
    const additive: string[] = [];
    values.push(numbers[0]);
    for (let k = 0; k < operators.length; k++) {
      const op: string = operators[k];
      const rhs: number = numbers[k + 1];
      if (op === Operator.MULTIPLY) {
        const product: number = values[values.length - 1] * rhs;
        if (!Number.isFinite(product) || Math.abs(product) > MAX_MICRO * SCALE) {
          outcome.error = CalcError.TOO_LARGE;
          return outcome;
        }
        values[values.length - 1] = Math.round(product / SCALE);
      } else if (op === Operator.DIVIDE) {
        if (rhs === 0) {
          outcome.error = CalcError.DIVIDE_BY_ZERO;
          return outcome;
        }
        values[values.length - 1] = Math.round(values[values.length - 1] * SCALE / rhs);
      } else {
        additive.push(op);
        values.push(rhs);
      }
      if (Math.abs(values[values.length - 1]) > MAX_MICRO) {
        outcome.error = CalcError.TOO_LARGE;
        return outcome;
      }
    }
    let acc: number = values[0];
    for (let m = 0; m < additive.length; m++) {
      if (additive[m] === Operator.PLUS) {
        acc += values[m + 1];
      } else {
        acc -= values[m + 1];
      }
      if (Math.abs(acc) > MAX_MICRO) {
        outcome.error = CalcError.TOO_LARGE;
        return outcome;
      }
    }
    outcome.micro = acc;
    return outcome;
  }

  private static parseMicro(text: string): number {
    if (text.length === 0) {
      return -1;
    }
    let intPart: string = '';
    let fracPart: string = '';
    let dotSeen: boolean = false;
    let digits: number = 0;
    for (let i = 0; i < text.length; i++) {
      const ch: string = text.substring(i, i + 1);
      if (ch === '.') {
        if (dotSeen) {
          return -1;
        }
        dotSeen = true;
        continue;
      }
      if (ch < '0' || ch > '9') {
        return -1;
      }
      digits += 1;
      if (dotSeen) {
        fracPart = fracPart.concat(ch);
      } else {
        intPart = intPart.concat(ch);
      }
    }
    if (digits === 0 || fracPart.length > MAX_DECIMALS || intPart.length > MAX_INT_DIGITS) {
      return -1;
    }
    const intValue: number = intPart.length === 0 ? 0 : Number(intPart);
    const fracValue: number = fracPart.length === 0 ? 0 : Number(fracPart.padEnd(6, '0'));
    if (Number.isNaN(intValue) || Number.isNaN(fracValue)) {
      return -1;
    }
    return intValue * SCALE + fracValue;
  }
}

function isOperatorChar(ch: string): boolean {
  return ch === Operator.PLUS || ch === Operator.MINUS || ch === Operator.MULTIPLY || ch === Operator.DIVIDE
    || ch === '-';
}
