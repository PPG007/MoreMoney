package com.github.ppg007.moremoney.ui.components.base

import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDefaults
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.SelectableDates
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.util.DateUtil
import java.time.LocalDate

/**
 * 主题化的日期选择弹窗，替代系统的 [android.app.DatePickerDialog]。
 *
 * 使用 Material3 日历（月份翻页 + 年份下拉），颜色全部取 MoreMoney 设计 token。
 * [minDate]/[maxDate] 为闭区间，传 `null` 表示不限制；日期按 UTC 日序号与
 * Material3 的 UTC 毫秒互转，不受设备时区影响。
 */
@Composable
fun AppDatePickerDialog(
  initial: LocalDate,
  onConfirm: (LocalDate) -> Unit,
  onDismiss: () -> Unit,
  title: String = "选择日期",
  minDate: LocalDate? = null,
  maxDate: LocalDate? = null,
) {
  val colors = MoreMoneyTheme.colors
  val pickerColors =
    DatePickerDefaults.colors(
      containerColor = colors.surface,
      titleContentColor = colors.ink3,
      headlineContentColor = colors.ink,
      weekdayContentColor = colors.ink3,
      navigationContentColor = colors.ink2,
      yearContentColor = colors.ink2,
      currentYearContentColor = colors.brandInk,
      selectedYearContainerColor = colors.buttonBackground,
      selectedYearContentColor = colors.buttonForeground,
      dayContentColor = colors.ink,
      selectedDayContainerColor = colors.buttonBackground,
      selectedDayContentColor = colors.buttonForeground,
      todayContentColor = colors.brandInk,
      todayDateBorderColor = colors.brandInk,
      disabledDayContentColor = colors.ink3.copy(alpha = 0.38f),
      disabledYearContentColor = colors.ink3.copy(alpha = 0.38f),
      dividerColor = colors.line,
    )
  val yearRange =
    remember(minDate, maxDate) {
      val first = minDate?.year ?: DatePickerDefaults.YearRange.first
      val last = maxDate?.year ?: DatePickerDefaults.YearRange.last
      first..last
    }
  val selectableDates = remember(minDate, maxDate) { BoundedSelectableDates(minDate, maxDate) }
  val state =
    rememberDatePickerState(
      initialSelectedDateMillis = DateUtil.toUtcMillis(initial),
      initialDisplayedMonthMillis = DateUtil.toUtcMillis(initial),
      yearRange = yearRange,
      selectableDates = selectableDates,
    )

  DatePickerDialog(
    onDismissRequest = onDismiss,
    confirmButton = {
      TextButton(
        onClick = { state.selectedDateMillis?.let { onConfirm(DateUtil.fromUtcMillis(it)) } },
      ) {
        Text(
          text = "确定",
          style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.Bold),
          color = colors.brandInk,
        )
      }
    },
    dismissButton = {
      TextButton(onClick = onDismiss) {
        Text(text = "取消", style = MoreMoneyTextStyles.row, color = colors.ink2)
      }
    },
    shape = RoundedCornerShape(Radius.card),
    tonalElevation = 0.dp,
    colors = pickerColors,
  ) {
    DatePicker(
      state = state,
      colors = pickerColors,
      showModeToggle = false,
      title = {
        Text(
          text = title,
          style = MoreMoneyTextStyles.settingsTitle,
          color = colors.ink3,
          modifier = Modifier.padding(start = 24.dp, end = 12.dp, top = 16.dp),
        )
      },
    )
  }
}

/** 将 Material3 的 UTC 日期限制在闭区间内；年份列表同样禁用越界年份。 */
private class BoundedSelectableDates(
  private val minDate: LocalDate?,
  private val maxDate: LocalDate?,
) : SelectableDates {
  override fun isSelectableDate(utcTimeMillis: Long): Boolean {
    val date = DateUtil.fromUtcMillis(utcTimeMillis)
    if (minDate != null && date.isBefore(minDate)) {
      return false
    }
    if (maxDate != null && date.isAfter(maxDate)) {
      return false
    }
    return true
  }

  override fun isSelectableYear(year: Int): Boolean {
    if (minDate != null && year < minDate.year) {
      return false
    }
    if (maxDate != null && year > maxDate.year) {
      return false
    }
    return true
  }
}
