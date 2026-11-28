package com.github.ppg007.moremoney.ui.common

import android.app.Activity
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat
import com.github.ppg007.moremoney.ui.theme.isDarkTheme

/**
 * 状态栏/导航栏图标明暗。
 *
 * @param darkIcons true 表示深色图标（浅色背景），false 表示白色图标（深色背景）。
 *
 * 默认跟随当前主题：浅色主题用深色图标，深色主题用白色图标。
 * 首页 Hero 覆盖状态栏，固定使用白色图标。
 */
@Composable
fun SystemBarAppearance(darkIcons: Boolean = !isDarkTheme()) {
  val view = LocalView.current
  if (view.isInEditMode) {
    return
  }
  val window = (view.context as? Activity)?.window ?: return
  SideEffect {
    WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = darkIcons
    WindowCompat.getInsetsController(window, view).isAppearanceLightNavigationBars = darkIcons
  }
}
