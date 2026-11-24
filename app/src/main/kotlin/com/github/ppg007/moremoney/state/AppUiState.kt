package com.github.ppg007.moremoney.state

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

data class SnackMessage(
  val id: Long,
  val message: String,
  val actionLabel: String? = null,
  val durationMs: Long = 5000,
  val onAction: (() -> Unit)? = null,
)

/**
 * 会话级全局 UI 状态。
 *
 * - `hideAmount` 不持久化，冷启动恢复显示；
 * - Snackbar 由全局 Host 展示，删除撤销依赖它。
 */
class AppUiState {
  var hideAmount: Boolean by mutableStateOf(false)
    private set

  var snackbar: SnackMessage? by mutableStateOf(null)
    private set

  private var nextId: Long = 1

  fun toggleHideAmount() {
    hideAmount = !hideAmount
  }

  fun updateHideAmount(value: Boolean) {
    hideAmount = value
  }

  fun showSnack(
    message: String,
    actionLabel: String? = null,
    durationMs: Long = 5000,
    onAction: (() -> Unit)? = null,
  ) {
    snackbar =
      SnackMessage(
        id = nextId++,
        message = message,
        actionLabel = actionLabel,
        durationMs = durationMs,
        onAction = onAction,
      )
  }

  fun dismissSnack() {
    snackbar = null
  }
}
