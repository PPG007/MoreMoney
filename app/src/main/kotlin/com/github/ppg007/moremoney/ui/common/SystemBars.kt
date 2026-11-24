package com.github.ppg007.moremoney.ui.common

import android.app.Activity
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

/**
 * 状态栏/导航栏图标明暗。
 *
 * @param darkIcons true 表示深色图标（浅色背景），false 表示白色图标（首页 Hero）。
 *
 * 首页 Hero 覆盖状态栏，必须使用白色图标；其他一级页与所有二级页使用深色图标。
 */
@Composable
fun SystemBarAppearance(darkIcons: Boolean) {
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
