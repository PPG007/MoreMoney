package com.github.ppg007.moremoney.util

/**
 * 金额工具：所有金额以整数“分”存储和传递，禁止浮点存储。
 *
 * 负号使用 U+2212（−）。
 */
object MoneyUtil {
  const val NEGATIVE_SIGN = "−"

  /** 四舍五入，0.5 远离零。 */
  fun roundHalfUp(value: Double): Long =
    if (value >= 0) {
      Math.floor(value + 0.5).toLong()
    } else {
      -Math.floor(-value + 0.5).toLong()
    }

  /**
   * 把“分”格式化为 `¥1,286.40` / `1,286.40` / `−¥12.00`。
   *
   * @param symbol 是否带货币符号
   * @param grouping 是否使用千分位
   */
  fun formatCents(cents: Long, symbol: Boolean = true, grouping: Boolean = true): String {
    val rounded = roundHalfUp(cents.toDouble())
    val negative = rounded < 0
    val abs = if (rounded == Long.MIN_VALUE) Long.MAX_VALUE else kotlin.math.abs(rounded)
    val yuan = abs / 100
    val fraction = (abs % 100).toInt()
    val yuanText = if (grouping) groupDigits(yuan) else yuan.toString()
    val fractionText = fraction.toString().padStart(2, '0')
    val prefix = if (negative) NEGATIVE_SIGN else ""
    val symbolText = if (symbol) "¥" else ""
    return prefix + symbolText + yuanText + "." + fractionText
  }

  /** 不带货币符号、不带千分位的元文本，如 `12.30`。 */
  fun formatYuan(cents: Long): String {
    val rounded = roundHalfUp(cents.toDouble())
    val negative = rounded < 0
    val abs = if (rounded == Long.MIN_VALUE) Long.MAX_VALUE else kotlin.math.abs(rounded)
    val yuan = abs / 100
    val fraction = (abs % 100).toInt()
    val prefix = if (negative) NEGATIVE_SIGN else ""
    return prefix + yuan.toString() + "." + fraction.toString().padStart(2, '0')
  }

  /**
   * 解析用户输入的元文本；非法输入返回 null。
   *
   * - `12.3` → 1230
   * - `.5` → 500
   * - `12.345` / `-1` / `abc` / `1.2.3` → null
   */
  fun parseYuanToCents(text: String): Long? {
    val raw = text.trim()
    if (raw.isEmpty()) {
      return null
    }
    var intPart = StringBuilder()
    var fracPart = StringBuilder()
    var dotSeen = false
    var digits = 0
    for (ch in raw) {
      if (ch == '.') {
        if (dotSeen) {
          return null
        }
        dotSeen = true
        continue
      }
      if (ch !in '0'..'9') {
        return null
      }
      digits += 1
      if (dotSeen) {
        fracPart.append(ch)
      } else {
        intPart.append(ch)
      }
    }
    if (digits == 0 || fracPart.length > 2) {
      return null
    }
    return try {
      if (intPart.isEmpty()) {
        val whole = fracPart.toString().toLong()
        whole * 100
      } else {
        val yuan = intPart.toString().toLong()
        val frac = if (fracPart.isEmpty()) 0L else fracPart.toString().padEnd(2, '0').toLong()
        yuan * 100 + frac
      }
    } catch (error: NumberFormatException) {
      null
    }
  }

  /** 历史别名。 */
  fun yuanTextToCents(text: String): Long? = parseYuanToCents(text)

  private fun groupDigits(value: Long): String {
    val text = value.toString()
    val result = StringBuilder()
    var count = 0
    var i = text.length - 1
    while (i >= 0) {
      result.insert(0, text[i])
      count += 1
      if (count % 3 == 0 && i > 0) {
        result.insert(0, ',')
      }
      i -= 1
    }
    return result.toString()
  }
}
