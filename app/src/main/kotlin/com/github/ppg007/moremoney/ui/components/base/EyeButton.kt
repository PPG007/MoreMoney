package com.github.ppg007.moremoney.ui.components.base

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.github.ppg007.moremoney.R
import com.github.ppg007.moremoney.state.AppUiState
import com.github.ppg007.moremoney.ui.theme.IconSize
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius

/**
 * 全局金额隐藏按钮。任一页面切换后所有页面同步。
 *
 * `hero=true` 用于首页 Hero 的深色渐变背景。
 */
@Composable
fun EyeButton(
  ui: AppUiState,
  modifier: Modifier = Modifier,
  hero: Boolean = false,
) {
  val colors = MoreMoneyTheme.colors
  val background =
    when {
      hero -> colors.heroGlass
      ui.hideAmount -> colors.brandWash
      else -> colors.surface
    }
  val border = when {
    hero -> colors.heroLine
    ui.hideAmount -> colors.brandSoft
    else -> colors.line
  }
  val tint = when {
    hero -> colors.onHero
    ui.hideAmount -> colors.brandInk
    else -> colors.ink2
  }
  val description =
    stringResource(if (ui.hideAmount) R.string.cd_show_amount else R.string.cd_hide_amount)

  Box(
    modifier =
      modifier
        .size(34.dp)
        .clip(CircleShape)
        .background(background)
        .border(1.dp, border, CircleShape)
        .testTag("eye_button")
        .clickable(onClick = { ui.toggleHideAmount() })
        .semantics { contentDescription = description },
    contentAlignment = Alignment.Center,
  ) {
    Icon(
      painter = painterResource(if (ui.hideAmount) R.drawable.ic_eye_off else R.drawable.ic_eye),
      contentDescription = null,
      tint = tint,
      modifier = Modifier.size(IconSize.action),
    )
  }
}
