package com.github.ppg007.moremoney.ui.ledger

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.github.ppg007.moremoney.ui.components.base.MoneyText
import com.github.ppg007.moremoney.ui.components.base.MoneyTone
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.ui.theme.Spacing
import com.github.ppg007.moremoney.ui.theme.withAlpha

/** 首页摘要卡：本月支出、预算进度、预算/每天可用/剩余。 */
@Composable
fun SummaryCard(
  spentCents: Long,
  budgetCents: Long,
  hasBudget: Boolean,
  perDayCents: Long,
  hidden: Boolean,
  onGoBudget: () -> Unit,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  val ratio = if (hasBudget && budgetCents > 0) (spentCents.toFloat() / budgetCents).coerceIn(0f, 1f) else 0f
  val remaining = budgetCents - spentCents
  val overspent = hasBudget && remaining < 0

  Column(
    modifier =
      modifier
        .fillMaxWidth()
        .clip(RoundedCornerShape(Radius.cardLg))
        .background(colors.surface)
        .border(1.dp, withAlpha(colors.line, 0.76f), RoundedCornerShape(Radius.cardLg))
        .padding(19.dp),
    verticalArrangement = Arrangement.spacedBy(Spacing.x5),
  ) {
    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
      Text(text = "本月支出", style = MoreMoneyTextStyles.caption, color = colors.ink3)
      MoneyText(
        cents = spentCents,
        hidden = hidden,
        tone = MoneyTone.Expense,
        style = MoreMoneyTextStyles.heroAmount,
      )
    }

    if (hasBudget) {
      Box(modifier = Modifier.fillMaxWidth().height(8.dp)) {
        Box(
          modifier =
            Modifier
              .fillMaxWidth()
              .height(8.dp)
              .clip(RoundedCornerShape(Radius.pill))
              .background(colors.surface2),
        )
        if (!hidden && ratio > 0f) {
          Box(
            modifier =
              Modifier
                .fillMaxWidth(ratio)
                .height(8.dp)
                .clip(RoundedCornerShape(Radius.pill))
                .background(Brush.horizontalGradient(listOf(colors.brand, colors.brandInk))),
          )
          Row(
            modifier = Modifier.fillMaxWidth(ratio),
            horizontalArrangement = Arrangement.End,
          ) {
            Box(
              modifier =
                Modifier
                  .width(12.dp)
                  .height(12.dp)
                  .clip(CircleShape)
                  .background(colors.surface)
                  .border(3.dp, colors.brandInk, CircleShape),
            )
          }
        }
      }
    } else {
      Row(verticalAlignment = Alignment.CenterVertically) {
        Text(
          text = "未设置预算",
          style = MoreMoneyTextStyles.caption,
          color = colors.ink3,
          modifier = Modifier.weight(1f),
        )
        Text(
          text = "去设置",
          style = MoreMoneyTextStyles.caption.copy(fontWeight = FontWeight.Bold),
          color = colors.brandInk,
          modifier =
            Modifier
              .clip(RoundedCornerShape(Radius.pill))
              .background(colors.brandWash)
              .clickable(onClick = onGoBudget)
              .padding(horizontal = 9.dp, vertical = 5.dp),
        )
      }
    }

    Row(verticalAlignment = Alignment.CenterVertically) {
      SummaryStat("预算", budgetCents, MoneyTone.Ink, hasBudget, hidden, Modifier.weight(1f))
      StatDivider()
      SummaryStat("每天可用", perDayCents, MoneyTone.Ink, hasBudget, hidden, Modifier.weight(1f))
      StatDivider()
      SummaryStat(
        if (overspent) "超支" else "剩余",
        if (overspent) -remaining else remaining,
        if (overspent) MoneyTone.Expense else MoneyTone.Good,
        hasBudget,
        hidden,
        Modifier.weight(1f),
      )
    }
  }
}

@Composable
private fun SummaryStat(
  label: String,
  cents: Long,
  tone: MoneyTone,
  showValue: Boolean,
  hidden: Boolean,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(3.dp)) {
    if (showValue) {
      MoneyText(
        cents = cents,
        hidden = hidden,
        tone = tone,
        style = MoreMoneyTextStyles.stat,
      )
    } else {
      Text(text = "—", style = MoreMoneyTextStyles.stat, color = colors.ink3)
    }
    Text(text = label, style = MoreMoneyTextStyles.caption, color = colors.ink3)
  }
}

@Composable
private fun StatDivider() {
  Box(
    modifier =
      Modifier
        .padding(horizontal = Spacing.x3)
        .width(1.dp)
        .height(24.dp)
        .background(MoreMoneyTheme.colors.line),
  )
  Spacer(Modifier.width(0.dp))
}
