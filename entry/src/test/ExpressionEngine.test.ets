import { describe, expect, it } from '@ohos/hypium';
import { CalcError, CalcResult, Operator } from '../main/ets/utils/CalcTypes';
import { CalcEngine } from '../main/ets/utils/ExpressionEngine';

function applyKey(engine: CalcEngine, key: string): void {
  if (key === '+') {
    engine.appendOperator(Operator.PLUS);
  } else if (key === '−' || key === '-') {
    engine.appendOperator(Operator.MINUS);
  } else if (key === '×') {
    engine.appendOperator(Operator.MULTIPLY);
  } else if (key === '÷') {
    engine.appendOperator(Operator.DIVIDE);
  } else {
    engine.appendDigit(key);
  }
}

function run(expression: string): CalcResult {
  const engine: CalcEngine = new CalcEngine();
  for (let i = 0; i < expression.length; i++) {
    applyKey(engine, expression.substring(i, i + 1));
  }
  return engine.evaluate();
}

export default function expressionEngineTest() {
  describe('ExpressionEngine', () => {
    it('evaluates addition', 0, () => {
      const result: CalcResult = run('12+3');
      expect(result.ok).assertTrue();
      expect(result.cents).assertEqual(1500);
    });

    it('respects multiply precedence', 0, () => {
      expect(run('1+2×3').cents).assertEqual(700);
    });

    it('evaluates subtraction', 0, () => {
      expect(run('10−4').cents).assertEqual(600);
    });

    it('evaluates division with rounding', 0, () => {
      expect(run('10÷4').cents).assertEqual(250);
      expect(run('10÷3').cents).assertEqual(333);
      expect(run('1÷3×3').cents).assertEqual(100);
    });

    it('avoids floating point drift', 0, () => {
      expect(run('0.1+0.2').cents).assertEqual(30);
    });

    it('ignores the second decimal point', 0, () => {
      const engine: CalcEngine = new CalcEngine();
      for (let i = 0; i < '12..3'.length; i++) {
        engine.appendDigit('12..3'.substring(i, i + 1));
      }
      expect(engine.expression).assertEqual('12.3');
      expect(engine.evaluate().cents).assertEqual(1230);
    });

    it('reports negative results', 0, () => {
      const result: CalcResult = run('5−8');
      expect(result.ok).assertFalse();
      expect(result.error).assertEqual(CalcError.NEGATIVE);
    });

    it('reports zero results', 0, () => {
      expect(run('0').error).assertEqual(CalcError.ZERO);
      expect(run('00').error).assertEqual(CalcError.ZERO);
    });

    it('reports divide by zero', 0, () => {
      expect(run('1÷0').error).assertEqual(CalcError.DIVIDE_BY_ZERO);
    });

    it('reports invalid expressions', 0, () => {
      expect(run('3×').error).assertEqual(CalcError.INVALID);
    });

    it('evaluates large amounts', 0, () => {
      const result: CalcResult = run('999999.99×9');
      expect(result.ok).assertTrue();
      expect(result.cents).assertEqual(899999991);
    });

    it('reports empty expression', 0, () => {
      expect(run('').error).assertEqual(CalcError.EMPTY);
    });

    it('backspace removes the trailing operator', 0, () => {
      const engine: CalcEngine = new CalcEngine();
      applyKey(engine, '1');
      applyKey(engine, '2');
      applyKey(engine, '+');
      engine.backspace();
      expect(engine.expression).assertEqual('12');
      expect(engine.evaluate().cents).assertEqual(1200);
    });

    it('replaces consecutive operators', 0, () => {
      const engine: CalcEngine = new CalcEngine();
      applyKey(engine, '+');
      applyKey(engine, '×');
      expect(engine.expression).assertEqual('0×');
    });

    it('is deterministic', 0, () => {
      const first: CalcResult = run('12+3×4−5÷2');
      for (let i = 0; i < 100; i++) {
        const next: CalcResult = run('12+3×4−5÷2');
        expect(next.ok).assertEqual(first.ok);
        expect(next.cents).assertEqual(first.cents);
        expect(next.error).assertEqual(first.error);
      }
    });

    it('builds preview text', 0, () => {
      const engine: CalcEngine = new CalcEngine();
      applyKey(engine, '1');
      applyKey(engine, '5');
      expect(engine.preview().text).assertEqual('合计 ¥15.00');
      expect(engine.preview().valid).assertTrue();
      const empty: CalcEngine = new CalcEngine();
      expect(empty.preview().text).assertEqual('请输入金额');
      expect(run('0').error).assertEqual(CalcError.ZERO);
    });
  });
}
