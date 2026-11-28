package com.github.ppg007.moremoney.state

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** 刚保存的流水位置；首页据此自动切到对应账本与月份并展示这笔记录。 */
data class SavedTxnEvent(
  val seq: Long,
  val bookId: String,
  val dayKey: String,
)

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

  private val _savedTxn = MutableStateFlow<SavedTxnEvent?>(null)
  val savedTxn: StateFlow<SavedTxnEvent?> = _savedTxn.asStateFlow()
  private var nextSavedTxnSeq: Long = 1
  private var consumedSavedTxnSeq: Long = 0

  fun notifyTxnSaved(bookId: String, dayKey: String) {
    _savedTxn.value = SavedTxnEvent(seq = nextSavedTxnSeq++, bookId = bookId, dayKey = dayKey)
  }

  /** 只消费一次，避免新创建的首页 ViewModel 再次跳回旧记录。 */
  fun consumeSavedTxn(): SavedTxnEvent? {
    val event = _savedTxn.value ?: return null
    if (event.seq <= consumedSavedTxnSeq) {
      return null
    }
    consumedSavedTxnSeq = event.seq
    return event
  }

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
