package com.github.ppg007.moremoney.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.ui.theme.Spacing

/** 基础卡片：白/深色表面 + 1dp 描边 + 20dp 圆角。 */
@Composable
fun AppCard(
  modifier: Modifier = Modifier,
  contentPadding: PaddingValues = PaddingValues(Spacing.x7),
  content: @Composable ColumnScope.() -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  val shape = RoundedCornerShape(Radius.card)

  Column(
    modifier =
      modifier
        .fillMaxWidth()
        .clip(shape)
        .background(colors.surface)
        .border(width = 1.dp, color = colors.line, shape = shape)
        .padding(contentPadding),
    content = content,
  )
}
