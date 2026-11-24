package com.github.ppg007.moremoney.util

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ExpressionEngineTest {
  private fun applyKey(engine: CalcEngine, key: String) {
    when (key) {
      "+" -> engine.appendOperator(Operator.PLUS)
      "−", "-" -> engine.appendOperator(Operator.MINUS)
      "×" -> engine.appendOperator(Operator.MULTIPLY)
      "÷" -> engine.appendOperator(Operator.DIVIDE)
      else -> engine.appendDigit(key)
    }
  }

  private fun run(expression: String): CalcResult {
    val engine = CalcEngine()
    expression.forEach { applyKey(engine, it.toString()) }
    return engine.evaluate()
  }

  @Test
  fun evaluatesAddition() {
    val result = run("12+3")
    assertTrue(result.ok)
    assertEquals(1500L, result.cents)
  }

  @Test
  fun respectsMultiplyPrecedence() {
    assertEquals(700L, run("1+2×3").cents)
  }

  @Test
  fun evaluatesSubtraction() {
    assertEquals(600L, run("10−4").cents)
  }

  @Test
  fun evaluatesDivisionWithRounding() {
    assertEquals(250L, run("10÷4").cents)
    assertEquals(333L, run("10÷3").cents)
    assertEquals(100L, run("1÷3×3").cents)
  }

  @Test
  fun avoidsFloatingPointDrift() {
    assertEquals(30L, run("0.1+0.2").cents)
  }

  @Test
  fun ignoresSecondDecimalPoint() {
    val engine = CalcEngine()
    "12..3".forEach { engine.appendDigit(it.toString()) }
    assertEquals("12.3", engine.expression)
    assertEquals(1230L, engine.evaluate().cents)
  }

  @Test
  fun reportsNegativeResults() {
    val result = run("5−8")
    assertFalse(result.ok)
    assertEquals(CalcError.NEGATIVE, result.error)
  }

  @Test
  fun reportsZeroResults() {
    assertEquals(CalcError.ZERO, run("0").error)
    assertEquals(CalcError.ZERO, run("00").error)
  }

  @Test
  fun reportsDivideByZero() {
    assertEquals(CalcError.DIVIDE_BY_ZERO, run("1÷0").error)
  }

  @Test
  fun reportsInvalidExpressions() {
    assertEquals(CalcError.INVALID, run("3×").error)
  }

  @Test
  fun evaluatesLargeAmounts() {
    val result = run("999999.99×9")
    assertTrue(result.ok)
    assertEquals(899999991L, result.cents)
  }

  @Test
  fun reportsEmptyExpression() {
    assertEquals(CalcError.EMPTY, run("").error)
  }

  @Test
  fun capsIntegerDigitsAtEight() {
    val engine = CalcEngine()
    "123456789".forEach { engine.appendDigit(it.toString()) }
    assertEquals("12345678", engine.expression)
    assertTrue(engine.evaluate().ok)
  }

  @Test
  fun capsDecimalsAtTwo() {
    val engine = CalcEngine()
    "1.2345".forEach { engine.appendDigit(it.toString()) }
    assertEquals("1.23", engine.expression)
  }

  @Test
  fun backspaceRemovesTrailingOperator() {
    val engine = CalcEngine()
    applyKey(engine, "1")
    applyKey(engine, "2")
    applyKey(engine, "+")
    engine.backspace()
    assertEquals("12", engine.expression)
    assertEquals(1200L, engine.evaluate().cents)
  }

  @Test
  fun replacesConsecutiveOperators() {
    val engine = CalcEngine()
    applyKey(engine, "+")
    applyKey(engine, "×")
    assertEquals("0×", engine.expression)
  }

  @Test
  fun isDeterministic() {
    val first = run("12+3×4−5÷2")
    repeat(100) {
      val next = run("12+3×4−5÷2")
      assertEquals(first.ok, next.ok)
      assertEquals(first.cents, next.cents)
      assertEquals(first.error, next.error)
    }
  }

  @Test
  fun buildsPreviewText() {
    val engine = CalcEngine()
    applyKey(engine, "1")
    applyKey(engine, "5")
    assertEquals("合计 ¥15.00", engine.preview().text)
    assertTrue(engine.preview().valid)
    assertEquals("请输入金额", CalcEngine().preview().text)
    assertEquals(CalcError.ZERO, run("0").error)
  }
}
