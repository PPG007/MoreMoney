package com.github.ppg007.moremoney.util

/** 计算器错误类型。 */
enum class CalcError {
  NONE,
  EMPTY,
  INVALID,
  ZERO,
  NEGATIVE,
  DIVIDE_BY_ZERO,
  TOO_LARGE,
}

/** 运算符；符号与键盘显示、表达式解析共用。 */
enum class Operator(val symbol: String) {
  PLUS("+"),
  MINUS("−"),
  MULTIPLY("×"),
  DIVIDE("÷"),
}

data class CalcResult(
  val ok: Boolean = false,
  val cents: Long = 0,
  val error: CalcError = CalcError.NONE,
)

data class CalcPreview(
  val text: String = "",
  val valid: Boolean = false,
)
