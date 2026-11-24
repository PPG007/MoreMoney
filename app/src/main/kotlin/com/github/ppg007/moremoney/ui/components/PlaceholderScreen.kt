package com.github.ppg007.moremoney.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.github.ppg007.moremoney.R
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Spacing
import com.github.ppg007.moremoney.ui.theme.tabularNumbers

/**
 * 一级 Tab 的占位页。
 *
 * 用于在迁移初期验证主题、排版与导航；后续任务会用真实页面逐个替换。
 */
@Composable
fun PlaceholderScreen(
  title: String,
  subtitle: String,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors

  Column(
    modifier =
      modifier
        .fillMaxSize()
        .verticalScroll(rememberScrollState())
        .padding(horizontal = Spacing.page)
        .padding(top = Spacing.x8, bottom = Spacing.x9),
  ) {
    Text(
      text = title,
      style = MaterialTheme.typography.headlineMedium,
      color = colors.ink,
    )
    Spacer(Modifier.height(Spacing.x3))
    Text(
      text = subtitle,
      style = MaterialTheme.typography.bodyLarge,
      color = colors.ink2,
    )

    Spacer(Modifier.height(Spacing.x8))
    AppCard {
      Text(
        text = stringResource(R.string.placeholder_badge),
        style = MaterialTheme.typography.labelMedium,
        color = colors.brandInk,
      )
      Spacer(Modifier.height(Spacing.x5))
      Text(
        text = stringResource(R.string.placeholder_sample_amount),
        style = MaterialTheme.typography.bodySmall,
        color = colors.ink3,
      )
      Spacer(Modifier.height(Spacing.x1))
      Text(
        text = stringResource(R.string.placeholder_sample_value),
        style = MaterialTheme.typography.displayLarge.tabularNumbers(),
        color = colors.ink,
      )
      Spacer(Modifier.height(Spacing.x5))
      Row(horizontalArrangement = Arrangement.spacedBy(Spacing.x5)) {
        StatusDot(color = colors.expense, label = stringResource(R.string.color_expense))
        StatusDot(color = colors.good, label = stringResource(R.string.color_good))
        StatusDot(color = colors.warn, label = stringResource(R.string.color_warn))
      }
      Spacer(Modifier.height(Spacing.x5))
      Text(
        text = stringResource(R.string.placeholder_ready),
        style = MaterialTheme.typography.bodySmall,
        color = colors.ink3,
      )
    }
  }
}

@Composable
private fun StatusDot(
  color: Color,
  label: String,
) {
  Row(
    verticalAlignment = Alignment.CenterVertically,
    horizontalArrangement = Arrangement.spacedBy(Spacing.x2),
  ) {
    Box(
      modifier =
        Modifier
          .size(8.dp)
          .clip(CircleShape)
          .background(color),
    )
    Text(
      text = label,
      style = MaterialTheme.typography.labelSmall,
      color = MoreMoneyTheme.colors.ink3,
    )
  }
}
