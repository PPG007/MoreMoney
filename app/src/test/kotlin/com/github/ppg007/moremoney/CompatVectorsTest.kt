package com.github.ppg007.moremoney

import com.github.ppg007.moremoney.util.CalcEngine
import com.github.ppg007.moremoney.util.CalcError
import com.github.ppg007.moremoney.util.MoneyUtil
import com.github.ppg007.moremoney.util.Operator
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * 历史回归测试向量：固定输入与输出，防止金额/表达式行为漂移。
 *
 * 资源文件位于 `app/src/test/resources/compat/`。
 */
class CompatVectorsTest {
  private fun readVectors(name: String): List<List<String>> {
    val text =
      javaClass.classLoader!!.getResourceAsStream("compat/$name")!!.bufferedReader(Charsets.UTF_8).use { it.readText() }
    return text.lines()
      .filter { it.isNotBlank() && !it.startsWith("#") }
      .map { it.split("\t") }
  }

  @Test
  fun moneyVectorsMatchHarmonyOs() {
    for (row in readVectors("money.tsv")) {
      val cents = row[0].trim().toLong()
      assertEquals("formatCents($cents)", row[1], MoneyUtil.formatCents(cents))
      assertEquals("formatYuan($cents)", row[2], MoneyUtil.formatYuan(cents))
    }
  }

  @Test
  fun expressionVectorsMatchHarmonyOs() {
    for (row in readVectors("expression.tsv")) {
      val expression = row[0]
      val expected = row[1]
      val engine = CalcEngine()
      for (ch in expression) {
        applyKey(engine, ch.toString())
      }
      val result = engine.evaluate()
      if (expected.startsWith("OK:")) {
        assertTrue("$expression should be ok", result.ok)
        assertEquals(expression, expected.removePrefix("OK:").toLong(), result.cents)
      } else {
        assertEquals(expression, CalcError.valueOf(expected.removePrefix("ERROR:")), result.error)
      }
    }
  }

  private fun applyKey(engine: CalcEngine, key: String) {
    when (key) {
      "+" -> engine.appendOperator(Operator.PLUS)
      "−", "-" -> engine.appendOperator(Operator.MINUS)
      "×" -> engine.appendOperator(Operator.MULTIPLY)
      "÷" -> engine.appendOperator(Operator.DIVIDE)
      else -> engine.appendDigit(key)
    }
  }
}
