export enum CalcError {
  NONE = 'none',
  EMPTY = 'empty',
  INVALID = 'invalid',
  ZERO = 'zero',
  NEGATIVE = 'negative',
  DIVIDE_BY_ZERO = 'divide_by_zero',
  TOO_LARGE = 'too_large'
}

export enum Operator {
  PLUS = '+',
  MINUS = '−',
  MULTIPLY = '×',
  DIVIDE = '÷'
}

export class CalcToken {
  text: string = '';
  isOperator: boolean = false;
}

export class CalcResult {
  ok: boolean = false;
  cents: number = 0;
  error: CalcError = CalcError.NONE;
}

export class CalcPreview {
  text: string = '';
  valid: boolean = false;
}
