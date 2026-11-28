package com.github.ppg007.moremoney.ui.budget

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.github.ppg007.moremoney.models.BudgetCycle
import com.github.ppg007.moremoney.service.BudgetCycleUtil
import com.github.ppg007.moremoney.ui.components.base.AppTextField
import com.github.ppg007.moremoney.ui.components.base.SegmentedControl
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.util.MoneyUtil

/**
 * 设置/清空账本预算。一个账本只能选择年、季、月其中一个周期；
 * 金额以元输入，转换为整数分保存，其他周期金额自动折算。
 */
@Composable
fun BudgetEditDialog(
  visible: Boolean,
  bookName: String,
  currentCycle: BudgetCycle,
  currentCents: Long,
  onSave: (BudgetCycle, Long) -> Unit,
  onClear: () -> Unit,
  onDismiss: () -> Unit,
) {
  if (!visible) {
    return
  }
  val colors = MoreMoneyTheme.colors
  var cycle by remember(bookName, currentCycle, visible) { mutableStateOf(currentCycle) }
  var text by remember(bookName, currentCycle, visible) {
    mutableStateOf(if (currentCents > 0) MoneyUtil.formatYuan(currentCents).replace("−", "") else "")
  }
  var error by remember(bookName, currentCycle, visible) { mutableStateOf("") }
  val parsedCents = MoneyUtil.parseYuanToCents(text)
  val hint =
    if (parsedCents == null || parsedCents <= 0) {
      "${BudgetCycleUtil.repeatLabel(cycle)}自动重复"
    } else {
      when (cycle) {
        BudgetCycle.YEAR ->
          "每年自动重复 · 折合每月 ${MoneyUtil.formatCents(BudgetCycleUtil.monthlyCents(cycle, parsedCents))}"
        BudgetCycle.QUARTER ->
          "每季度自动重复 · 折合每月 ${MoneyUtil.formatCents(BudgetCycleUtil.monthlyCents(cycle, parsedCents))}"
        BudgetCycle.MONTH ->
          "每月自动重复 · 折合每年 ${MoneyUtil.formatCents(BudgetCycleUtil.yearlyCents(cycle, parsedCents))}"
      }
    }

  AlertDialog(
    onDismissRequest = onDismiss,
    containerColor = colors.surface,
    shape = RoundedCornerShape(Radius.card),
    title = {
      Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(text = "设置预算", style = MoreMoneyTextStyles.subTitle, color = colors.ink)
        Text(
          text = "$bookName · 设置后自动重复",
          style = MoreMoneyTextStyles.caption,
          color = colors.ink3,
        )
      }
    },
    text = {
      Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(text = "预算周期", style = MoreMoneyTextStyles.caption, color = colors.ink3)
        SegmentedControl(
          options = listOf("年度", "季度", "月度"),
          selectedIndex = BudgetCycle.entries.indexOf(cycle),
          onSelect = { index ->
            val next = BudgetCycle.entries[index]
            if (next != cycle) {
              val cents = MoneyUtil.parseYuanToCents(text)
              if (cents != null && cents > 0) {
                text = MoneyUtil.formatYuan(BudgetCycleUtil.convert(cents, cycle, next))
              }
              cycle = next
            }
          },
        )
        AppTextField(
          value = text,
          onValueChange = {
            text = it
            error = ""
          },
          placeholder = "例如 3000",
          leadingIcon = null,
          height = 44,
          keyboardOptions =
            androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.Decimal),
          modifier = Modifier.fillMaxWidth(),
        )
        Text(text = hint, style = MoreMoneyTextStyles.caption, color = colors.ink3)
        if (error.isNotEmpty()) {
          Text(text = error, style = MoreMoneyTextStyles.caption, color = colors.expense)
        }
        if (currentCents > 0) {
          Text(
            text = "清空该账本预算",
            style = MoreMoneyTextStyles.caption.copy(fontWeight = FontWeight.SemiBold),
            color = colors.expense,
            modifier = Modifier.clickable { onClear() }.padding(vertical = 4.dp),
          )
        }
      }
    },
    confirmButton = {
      TextButton(
        onClick = {
          val cents = MoneyUtil.parseYuanToCents(text)
          when {
            cents == null -> error = "请输入正确的金额，最多两位小数"
            cents <= 0 -> error = "预算需大于 0"
            cents > 99_999_999_99L -> error = "金额过大"
            else -> onSave(cycle, cents)
          }
        }
      ) {
        Text(text = "保存", style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.Bold), color = colors.brandInk)
      }
    },
    dismissButton = {
      TextButton(onClick = onDismiss) {
        Text(text = "取消", style = MoreMoneyTextStyles.row, color = colors.ink2)
      }
    },
  )
}
