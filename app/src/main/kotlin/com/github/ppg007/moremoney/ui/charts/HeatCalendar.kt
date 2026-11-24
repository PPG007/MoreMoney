package com.github.ppg007.moremoney.ui.charts

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.github.ppg007.moremoney.R
import com.github.ppg007.moremoney.ui.components.base.AppIconButton
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.ui.theme.Spacing
import com.github.ppg007.moremoney.ui.theme.withAlpha
import com.github.ppg007.moremoney.util.DateUtil
import com.github.ppg007.moremoney.util.MoneyUtil
import java.time.YearMonth

/**
 * 日历热力：7 列月历、4 档品牌色热力、选中日描边。
 *
 * 隐藏金额时统一中性色，金额显示 `••`，不通过颜色深浅反推金额。
 */
@Composable
fun HeatCalendar(
  monthKey: String,
  days: Map<String, Long>,
  selectedDay: String,
  hidden: Boolean,
  onSelectDay: (String) -> Unit,
  onPrevMonth: () -> Unit,
  onNextMonth: () -> Unit,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  val yearMonth = DateUtil.parseMonthKey(monthKey)
  val first = yearMonth.atDay(1)
  val leading = (first.dayOfWeek.value + 6) % 7
  val totalDays = yearMonth.lengthOfMonth()
  val cells = leading + totalDays
  val rows = (cells + 6) / 7
  val maxCents = days.values.maxOrNull()?.coerceAtLeast(1) ?: 1

  Column(
    modifier =
      modifier
        .fillMaxWidth()
        .clip(RoundedCornerShape(Radius.cardLg))
        .background(colors.chartSurface)
        .border(1.dp, colors.line, RoundedCornerShape(Radius.cardLg))
        .padding(15.dp),
    verticalArrangement = Arrangement.spacedBy(Spacing.x3),
  ) {
    Row(verticalAlignment = Alignment.CenterVertically) {
      AppIconButton(
        iconRes = R.drawable.ic_chevron_left,
        contentDescription = "上个月",
        onClick = onPrevMonth,
        size = 30,
        iconSize = 15,
      )
      Text(
        text = DateUtil.formatMonthCnWithYear(monthKey),
        style = MoreMoneyTextStyles.stat,
        color = colors.ink,
        textAlign = TextAlign.Center,
        modifier = Modifier.weight(1f),
      )
      AppIconButton(
        iconRes = R.drawable.ic_chevron_right,
        contentDescription = "下个月",
        onClick = onNextMonth,
        size = 30,
        iconSize = 15,
      )
    }

    Row(modifier = Modifier.fillMaxWidth()) {
      listOf("一", "二", "三", "四", "五", "六", "日").forEach { label ->
        Text(
          text = label,
          style = MoreMoneyTextStyles.caption.copy(fontSize = 8.sp),
          color = colors.ink3,
          textAlign = TextAlign.Center,
          modifier = Modifier.weight(1f),
        )
      }
    }

    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
      for (row in 0 until rows) {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
          for (column in 0 until 7) {
            val index = row * 7 + column
            val dayNumber = index - leading + 1
            if (dayNumber < 1 || dayNumber > totalDays) {
              Box(modifier = Modifier.weight(1f).aspectRatio(1f))
            } else {
              val date = yearMonth.atDay(dayNumber)
              val key = DateUtil.dayKey(date)
              val cents = days[key] ?: 0L
              val ratio = if (maxCents > 0) cents.toFloat() / maxCents else 0f
              val alpha =
                when {
                  hidden || cents <= 0 -> 0f
                  ratio > 0.75f -> 0.28f
                  ratio > 0.5f -> 0.2f
                  ratio > 0.25f -> 0.13f
                  else -> 0.07f
                }
              val selected = key == selectedDay
              Box(
                modifier =
                  Modifier
                    .weight(1f)
                    .aspectRatio(1f)
                    .clip(RoundedCornerShape(10.dp))
                    .background(
                      if (alpha > 0f) withAlpha(colors.brand, alpha) else colors.surface
                    )
                    .then(
                      if (selected) Modifier.border(1.dp, colors.brandInk, RoundedCornerShape(10.dp)) else Modifier
                    )
                    .clickable { onSelectDay(key) }
                    .padding(3.dp),
                contentAlignment = Alignment.Center,
              ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                  Text(
                    text = dayNumber.toString(),
                    style = MoreMoneyTextStyles.caption.copy(fontSize = 10.sp),
                    color = if (dayNumber == DateUtil.today().dayOfMonth &&
                      yearMonth == YearMonth.from(DateUtil.today())
                    ) {
                      colors.brandInk
                    } else {
                      colors.ink
                    },
                    fontWeight = FontWeight.SemiBold,
                  )
                  Text(
                    text =
                      when {
                        hidden && cents > 0 -> "••"
                        cents > 0 -> MoneyUtil.formatCents(cents, symbol = false)
                        else -> ""
                      },
                    style = MoreMoneyTextStyles.caption.copy(fontSize = 7.sp),
                    color = colors.ink3,
                    maxLines = 1,
                  )
                }
              }
            }
          }
        }
      }
    }

    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
      Text(text = "少", style = MoreMoneyTextStyles.caption.copy(fontSize = 8.sp), color = colors.ink3)
      listOf(0.07f, 0.13f, 0.2f, 0.28f).forEach { alpha ->
        Box(
          modifier =
            Modifier
              .size(10.dp)
              .clip(RoundedCornerShape(3.dp))
              .background(withAlpha(colors.brand, if (hidden) 0f else alpha)),
        )
      }
      Text(text = "多", style = MoreMoneyTextStyles.caption.copy(fontSize = 8.sp), color = colors.ink3)
      Text(
        text = if (hidden) "金额已隐藏" else "共 ${MoneyUtil.formatCents(days.values.sum())}",
        style = MoreMoneyTextStyles.caption.copy(fontSize = 8.sp),
        color = colors.ink3,
        modifier = Modifier.weight(1f),
        textAlign = TextAlign.End,
      )
    }
  }
}
