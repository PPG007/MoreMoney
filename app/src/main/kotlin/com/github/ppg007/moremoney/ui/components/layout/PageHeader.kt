package com.github.ppg007.moremoney.ui.components.layout

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.height
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.github.ppg007.moremoney.R
import com.github.ppg007.moremoney.ui.components.base.AppIconButton
import com.github.ppg007.moremoney.ui.theme.IconSize
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme

/** 二级页头部：返回按钮 + 17/700 标题 + 右侧动作。 */
@Composable
fun PageHeader(
  title: String,
  onBack: () -> Unit,
  modifier: Modifier = Modifier,
  trailing: (@Composable () -> Unit)? = null,
) {
  val colors = MoreMoneyTheme.colors
  Row(
    modifier =
      modifier
        .fillMaxWidth()
        .statusBarsPadding()
        .height(52.dp)
        .padding(horizontal = 16.dp),
    verticalAlignment = Alignment.CenterVertically,
    horizontalArrangement = Arrangement.spacedBy(10.dp),
  ) {
    AppIconButton(
      iconRes = R.drawable.ic_back,
      contentDescription = "返回",
      onClick = onBack,
      size = 34,
      iconSize = 17,
    )
    Text(
      text = title,
      style = MoreMoneyTextStyles.subTitle.copy(fontWeight = FontWeight.Bold),
      color = colors.ink,
      maxLines = 1,
      overflow = TextOverflow.Ellipsis,
      modifier = Modifier.weight(1f),
    )
    trailing?.invoke()
  }
}
