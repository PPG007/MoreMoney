package com.github.ppg007.moremoney.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * 图表色与种子色，沿用 MoreMoney 的历史设计 token。
 *
 * 这里是除 `Color.kt` 外唯一允许出现十六进制颜色的位置；组件通过
 * [ChartPalette] / [MemberPalette] / [SeedColors] 取用。
 */
object ChartPalette {
  const val slotCount = 5

  private val lightSlots =
    listOf(Color(0xFF2A78D6), Color(0xFFEB6834), Color(0xFF1BAF7A), Color(0xFFEDA100), Color(0xFFE87BA4))
  private val darkSlots =
    listOf(Color(0xFF3987E5), Color(0xFFD95926), Color(0xFF199E70), Color(0xFFC98500), Color(0xFFD55181))

  private val lightOther = Color(0xFFB8AAB1)
  private val darkOther = Color(0xFF7D6C75)

  fun slots(isDark: Boolean): List<Color> = if (isDark) darkSlots else lightSlots

  fun other(isDark: Boolean): Color = if (isDark) darkOther else lightOther

  /** 循环取色；超出 5 个槽位时归入“其他”。 */
  fun slot(index: Int, isDark: Boolean): Color {
    val slots = slots(isDark)
    return if (index in slots.indices) slots[index] else other(isDark)
  }
}

/** 解析数据里保存的颜色文本；非法值回退到中性色。 */
fun parseColorOf(value: String): Color {
  if (value.startsWith("#")) {
    val parsed = parseHexColor(value)
    if (parsed != null) {
      return parsed
    }
  }
  return parseHexColor(SeedColors.neutral) ?: Color.Gray
}

fun parseHexColor(hex: String): Color? {
  val raw = hex.removePrefix("#")
  return when (raw.length) {
    6 -> Color(0xFF000000 or raw.toLong(16))
    8 -> Color(raw.toLong(16))
    else -> null
  }
}

/** 种子色，与固定种子数据配套，导入/导出测试依赖这些值。 */
object SeedColors {
  const val c1 = "#2A78D6"
  const val c2 = "#EB6834"
  const val c3 = "#1BAF7A"
  const val c4 = "#EDA100"
  const val c5 = "#E87BA4"
  const val c6 = "#6250D6"
  const val c7 = "#008300"
  const val c8 = "#E34948"
  const val neutral = "#B8AAB1"

  val all = listOf(c1, c2, c3, c4, c5, c6, c7, c8, neutral)

  fun at(index: Int): String = all[((index % all.size) + all.size) % all.size]
}

/** 节点透明度合成：把 `#RRGGBB` 与 0..1 的 alpha 合成为带 alpha 的颜色。 */
fun withAlpha(color: Color, alpha: Float): Color =
  color.copy(alpha = (alpha.coerceIn(0f, 1f)) * color.alpha)

/** 十六进制文本 + alpha → 十六进制文本（备份/数据层以外不使用）。 */
fun withAlphaHex(hex: String, alpha: Float): String {
  val raw = hex.removePrefix("#")
  if (raw.length != 6) {
    return hex
  }
  val ratio = alpha.coerceIn(0f, 1f)
  val aa = Math.round(ratio * 255).toString(16).uppercase().padStart(2, '0')
  return "#$aa${raw.uppercase()}"
}
