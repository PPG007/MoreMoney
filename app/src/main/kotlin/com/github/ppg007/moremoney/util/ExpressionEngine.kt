package com.github.ppg007.moremoney.util

/**
 * 记账金额表达式引擎。
 *
 * 内部用 1e-6 元的整数微元计算，保证 `0.1 + 0.2` 不会出现浮点漂移；
 * 结果转换为整数分。
 */
class CalcEngine {
  var expression: String = ""
    private set

  fun appendDigit(d: String) {
    if (d == "00") {
      appendDigit("0")
      appendDigit("0")
      return
    }
    if (d.length != 1) {
      return
    }
    if (expression.length >= MAX_EXPRESSION) {
      return
    }
    val segment = expression.substring(numberStart(expression))
    if (d == ".") {
      if (segment.contains('.')) {
        return
      }
      expression = if (segment.isEmpty()) expression + "0." else expression + "."
      return
    }
    if (d[0] !in '0'..'9') {
      return
    }
    val dot = segment.indexOf('.')
    if (dot >= 0) {
      if (segment.length - dot - 1 >= MAX_DECIMALS) {
        return
      }
    } else if (segment.length >= MAX_INT_DIGITS) {
      return
    }
    expression += d
  }

  fun appendOperator(op: Operator) {
    var expr = expression
    if (expr.isEmpty()) {
      expression = "0${op.symbol}"
      return
    }
    if (expr.last() == '.') {
      expr = expr.dropLast(1)
    }
    if (expr.isEmpty()) {
      expression = "0${op.symbol}"
      return
    }
    if (isOperatorChar(expr.last())) {
      expression = expr.dropLast(1) + op.symbol
      return
    }
    if (expr.length >= MAX_EXPRESSION) {
      return
    }
    expression = expr + op.symbol
  }

  fun backspace() {
    if (expression.isNotEmpty()) {
      expression = expression.dropLast(1)
    }
  }

  fun clear() {
    expression = ""
  }

  /** 编辑已有流水时直接回填金额表达式。 */
  fun setExpression(value: String) {
    expression = value.take(MAX_EXPRESSION)
  }

  fun evaluate(): CalcResult {
    if (expression.isEmpty()) {
      return CalcResult(error = CalcError.EMPTY)
    }
    val evaluated = evaluateExpression(expression)
    if (evaluated.error != CalcError.NONE) {
      return CalcResult(error = evaluated.error)
    }
    val cents = MoneyUtil.roundHalfUp(evaluated.micro / 10000.0)
    if (cents < 0) {
      return CalcResult(error = CalcError.NEGATIVE)
    }
    if (cents == 0L) {
      return CalcResult(error = CalcError.ZERO)
    }
    if (cents > MAX_CENTS) {
      return CalcResult(error = CalcError.TOO_LARGE)
    }
    return CalcResult(ok = true, cents = cents)
  }

  fun preview(): CalcPreview {
    val result = evaluate()
    if (result.ok) {
      return CalcPreview(text = "合计 ${MoneyUtil.formatCents(result.cents)}", valid = true)
    }
    val text =
      when (result.error) {
        CalcError.EMPTY -> "请输入金额"
        CalcError.ZERO -> "金额需大于 0"
        CalcError.NEGATIVE -> "金额不能为负"
        CalcError.DIVIDE_BY_ZERO -> "除数不能为 0"
        CalcError.TOO_LARGE -> "金额过大"
        else -> "无法计算"
      }
    return CalcPreview(text = text, valid = false)
  }

  private class EvalValue(val micro: Double = 0.0, val error: CalcError = CalcError.NONE)

  companion object {
    private const val SCALE = 1_000_000.0
    private const val MAX_CENTS = 9_999_999_999L
    private const val MAX_EXPRESSION = 24
    private const val MAX_INT_DIGITS = 8
    private const val MAX_DECIMALS = 2
    private const val MAX_MICRO = 1e16

    private fun numberStart(expr: String): Int {
      for (i in expr.indices.reversed()) {
        if (isOperatorChar(expr[i])) {
          return i + 1
        }
      }
      return 0
    }

    internal fun isOperatorChar(ch: Char): Boolean =
      ch == Operator.PLUS.symbol[0] ||
        ch == Operator.MINUS.symbol[0] ||
        ch == Operator.MULTIPLY.symbol[0] ||
        ch == Operator.DIVIDE.symbol[0] ||
        ch == '-'

    private fun evaluateExpression(expr: String): EvalValue {
      val numbers = ArrayList<Double>()
      val operators = ArrayList<Char>()
      var i = 0
      var expectNumber = true
      while (i < expr.length) {
        val ch = expr[i]
        if (isOperatorChar(ch)) {
          if (expectNumber) {
            return EvalValue(error = CalcError.INVALID)
          }
          operators.add(ch)
          expectNumber = true
          i += 1
          continue
        }
        var j = i
        while (j < expr.length && !isOperatorChar(expr[j])) {
          j += 1
        }
        val micro = parseMicro(expr.substring(i, j))
        if (micro < 0) {
          return EvalValue(error = CalcError.INVALID)
        }
        numbers.add(micro)
        expectNumber = false
        i = j
      }
      if (expectNumber || numbers.isEmpty() || operators.size != numbers.size - 1) {
        return EvalValue(error = CalcError.INVALID)
      }

      val values = ArrayList<Double>()
      val additive = ArrayList<Char>()
      values.add(numbers[0])
      for (k in operators.indices) {
        val op = operators[k]
        val rhs = numbers[k + 1]
        if (op == Operator.MULTIPLY.symbol[0]) {
          val product = values[values.size - 1] * rhs
          if (!product.isFinite() || kotlin.math.abs(product) > MAX_MICRO * SCALE) {
            return EvalValue(error = CalcError.TOO_LARGE)
          }
          values[values.size - 1] = Math.round(product / SCALE).toDouble()
        } else if (op == Operator.DIVIDE.symbol[0]) {
          if (rhs == 0.0) {
            return EvalValue(error = CalcError.DIVIDE_BY_ZERO)
          }
          values[values.size - 1] = Math.round(values[values.size - 1] * SCALE / rhs).toDouble()
        } else {
          additive.add(op)
          values.add(rhs)
        }
        if (kotlin.math.abs(values[values.size - 1]) > MAX_MICRO) {
          return EvalValue(error = CalcError.TOO_LARGE)
        }
      }

      var acc = values[0]
      for (m in additive.indices) {
        acc = if (additive[m] == Operator.PLUS.symbol[0]) acc + values[m + 1] else acc - values[m + 1]
        if (kotlin.math.abs(acc) > MAX_MICRO) {
          return EvalValue(error = CalcError.TOO_LARGE)
        }
      }
      return EvalValue(micro = acc)
    }

    private fun parseMicro(text: String): Double {
      if (text.isEmpty()) {
        return -1.0
      }
      val intPart = StringBuilder()
      val fracPart = StringBuilder()
      var dotSeen = false
      var digits = 0
      for (ch in text) {
        if (ch == '.') {
          if (dotSeen) {
            return -1.0
          }
          dotSeen = true
          continue
        }
        if (ch !in '0'..'9') {
          return -1.0
        }
        digits += 1
        if (dotSeen) {
          fracPart.append(ch)
        } else {
          intPart.append(ch)
        }
      }
      if (digits == 0 || fracPart.length > MAX_DECIMALS || intPart.length > MAX_INT_DIGITS) {
        return -1.0
      }
      return try {
        val intValue = if (intPart.isEmpty()) 0.0 else intPart.toString().toDouble()
        val fracValue = if (fracPart.isEmpty()) 0.0 else fracPart.toString().padEnd(6, '0').toDouble()
        intValue * SCALE + fracValue
      } catch (error: NumberFormatException) {
        -1.0
      }
    }
  }
}
