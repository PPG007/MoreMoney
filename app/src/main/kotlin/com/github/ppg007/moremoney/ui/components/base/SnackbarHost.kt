package com.github.ppg007.moremoney.ui.components.base

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.github.ppg007.moremoney.state.AppUiState
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.ui.theme.Spacing
import com.github.ppg007.moremoney.ui.theme.isDarkTheme
import kotlinx.coroutines.delay

/**
 * 全局 Snackbar：删除撤销、错误提示共用。
 *
 * 新消息会替换旧消息；连续删除时只展示最后一次操作，避免状态串线。
 */
@Composable
fun SnackbarHost(
  ui: AppUiState,
  modifier: Modifier = Modifier,
  bottomPadding: Int = 86,
) {
  val colors = MoreMoneyTheme.colors
  val dark = isDarkTheme()
  // Snackbar 背景在浅色模式是深色、深色模式是浅色，动作色需要反向取 token。
  val actionColor = if (dark) colors.brandInk else colors.brandSoft
  val snack = ui.snackbar
  LaunchedEffect(snack?.id) {
    val current = snack ?: return@LaunchedEffect
    delay(current.durationMs)
    if (ui.snackbar?.id == current.id) {
      ui.dismissSnack()
    }
  }

  Box(modifier = modifier.fillMaxSize(), contentAlignment = Alignment.BottomCenter) {
    AnimatedVisibility(
      visible = snack != null,
      enter = fadeIn(),
      exit = fadeOut(),
    ) {
      val current = snack ?: return@AnimatedVisibility
      Row(
        modifier =
          Modifier
            .fillMaxWidth()
            .navigationBarsPadding()
            // 右侧给 70dp FAB + 16dp 边距让位，避免“撤销”被 FAB 压住。
            .padding(start = Spacing.page, end = 88.dp)
            .padding(bottom = bottomPadding.dp)
            .clip(RoundedCornerShape(Radius.chip))
            .background(colors.ink)
            .padding(horizontal = 14.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Spacing.x5),
      ) {
        Text(
          text = current.message,
          style = MoreMoneyTextStyles.caption,
          color = colors.buttonForeground,
          modifier = Modifier.weight(1f),
        )
        if (current.actionLabel != null) {
          Text(
            text = current.actionLabel,
            style = MoreMoneyTextStyles.caption.copy(fontWeight = FontWeight.Bold),
            color = actionColor,
            modifier =
              Modifier.clickable {
                current.onAction?.invoke()
                ui.dismissSnack()
              },
          )
        }
      }
    }
  }
}
