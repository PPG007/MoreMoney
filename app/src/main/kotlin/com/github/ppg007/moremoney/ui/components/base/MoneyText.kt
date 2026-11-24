package com.github.ppg007.moremoney.ui.components.base

import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.isSpecified
import androidx.compose.ui.unit.sp
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.tabularNumbers
import com.github.ppg007.moremoney.util.MoneyUtil

enum class MoneyTone {
  Ink,
  Ink2,
  Ink3,
  Expense,
  Good,
  BrandInk,
  OnHero,
  Warn,
}

/**
 * 统一的金额文本。
 *
 * - 应用只记录支出，金额一律按非负数值展示，不出现负号；
 * - `hidden=true` → `¥••••`，不通过长度或颜色反推金额；
 * - 一律使用 `tabularNumbers()`，避免数字变化时左右跳动；
 * - 窄屏/大字体下自动缩小字号，避免金额被截断。
 */
@Composable
fun MoneyText(
  cents: Long,
  modifier: Modifier = Modifier,
  hidden: Boolean = false,
  showSymbol: Boolean = true,
  tone: MoneyTone = MoneyTone.Ink,
  style: TextStyle = MoreMoneyTextStyles.body,
  weight: FontWeight? = null,
) {
  val colors = MoreMoneyTheme.colors
  val color: Color =
    when (tone) {
      MoneyTone.Ink -> colors.ink
      MoneyTone.Ink2 -> colors.ink2
      MoneyTone.Ink3 -> colors.ink3
      MoneyTone.Expense -> colors.expense
      MoneyTone.Good -> colors.good
      MoneyTone.BrandInk -> colors.brandInk
      MoneyTone.OnHero -> colors.onHero
      MoneyTone.Warn -> colors.warn
    }
  val text =
    if (hidden) {
      "¥••••"
    } else {
      // 只记账应用：即使上游传入负值，也按金额绝对值展示。
      val value = if (cents < 0) -cents else cents
      MoneyUtil.formatCents(value, symbol = showSymbol)
    }
  val resolvedStyle = style.tabularNumbers().let { if (weight != null) it.copy(fontWeight = weight) else it }
  val autoSize =
    remember(resolvedStyle.fontSize) {
      if (resolvedStyle.fontSize.isSpecified && resolvedStyle.fontSize.value > 8f) {
        TextAutoSize.StepBased(
          minFontSize = 8.sp,
          maxFontSize = resolvedStyle.fontSize,
          stepSize = 0.5.sp,
        )
      } else {
        null
      }
    }
  Text(
    text = text,
    modifier = modifier,
    color = color,
    style = resolvedStyle,
    maxLines = 1,
    autoSize = autoSize,
  )
}
