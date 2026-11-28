package com.github.ppg007.moremoney.state

import android.content.Context
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

enum class ThemeMode { SYSTEM, LIGHT, DARK }

data class SettingsState(
  val defaultBookId: String = "",
  val weekStart: Int = 1,
  val lastBackupAt: Long = 0,
  val lastBackupName: String = "",
  val screenPrivacy: Boolean = false,
  val themeMode: ThemeMode = ThemeMode.SYSTEM,
)

/**
 * 设置持久化：SharedPreferences + StateFlow，不新增 DataStore 依赖。
 *
 * 键名采用 WBS T05.2 约定的 snake_case；所有写入同步更新 [state]，
 * 页面通过 `collectAsStateWithLifecycle()` 观察。
 */
class SettingsService(context: Context) {
  companion object {
    const val STORE_NAME = "moremoney_settings"
    const val KEY_DEFAULT_BOOK = "default_book_id"
    const val KEY_WEEK_START = "week_start"
    const val KEY_LAST_BACKUP_AT = "last_backup_at"
    const val KEY_LAST_BACKUP_NAME = "last_backup_name"
    const val KEY_SCREEN_PRIVACY = "screen_privacy"
    const val KEY_THEME_MODE = "theme_mode"
  }

  private val prefs = context.getSharedPreferences(STORE_NAME, Context.MODE_PRIVATE)
  private val _state = MutableStateFlow(read())
  val state: StateFlow<SettingsState> = _state.asStateFlow()

  private fun read(): SettingsState {
    val weekStart = prefs.getInt(KEY_WEEK_START, 1).let { if (it in 1..7) it else 1 }
    return SettingsState(
      defaultBookId = prefs.getString(KEY_DEFAULT_BOOK, "").orEmpty(),
      weekStart = weekStart,
      lastBackupAt = prefs.getLong(KEY_LAST_BACKUP_AT, 0),
      lastBackupName = prefs.getString(KEY_LAST_BACKUP_NAME, "").orEmpty(),
      screenPrivacy = prefs.getBoolean(KEY_SCREEN_PRIVACY, false),
      themeMode =
        prefs.getString(KEY_THEME_MODE, null)
          ?.let { raw -> ThemeMode.entries.firstOrNull { it.name == raw } }
          ?: ThemeMode.SYSTEM,
    )
  }

  private fun update(transform: (SettingsState) -> SettingsState) {
    _state.value = transform(_state.value)
  }

  fun defaultBookId(): String = _state.value.defaultBookId

  fun setDefaultBookId(bookId: String) {
    prefs.edit().putString(KEY_DEFAULT_BOOK, bookId).apply()
    update { it.copy(defaultBookId = bookId) }
  }

  fun weekStart(): Int = _state.value.weekStart

  fun setWeekStart(value: Int) {
    val normalized = if (value in 1..7) value else 1
    prefs.edit().putInt(KEY_WEEK_START, normalized).apply()
    update { it.copy(weekStart = normalized) }
  }

  fun lastBackupAt(): Long = _state.value.lastBackupAt

  fun lastBackupName(): String = _state.value.lastBackupName

  fun setLastBackup(at: Long, name: String) {
    prefs.edit().putLong(KEY_LAST_BACKUP_AT, at).putString(KEY_LAST_BACKUP_NAME, name).apply()
    update { it.copy(lastBackupAt = at, lastBackupName = name) }
  }

  fun screenPrivacy(): Boolean = _state.value.screenPrivacy

  fun setScreenPrivacy(value: Boolean) {
    prefs.edit().putBoolean(KEY_SCREEN_PRIVACY, value).apply()
    update { it.copy(screenPrivacy = value) }
  }

  fun themeMode(): ThemeMode = _state.value.themeMode

  fun setThemeMode(value: ThemeMode) {
    prefs.edit().putString(KEY_THEME_MODE, value.name).apply()
    update { it.copy(themeMode = value) }
  }
}
