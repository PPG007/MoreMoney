package com.github.ppg007.moremoney.ui.budget

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
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
import com.github.ppg007.moremoney.ui.components.base.AppTextField
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.util.MoneyUtil

/**
 * 设置/清空本月预算。金额以元输入，转换为整数分保存。
 */
@Composable
fun BudgetEditDialog(
  visible: Boolean,
  bookName: String,
  monthLabel: String,
  currentCents: Long,
  onSave: (Long) -> Unit,
  onClear: () -> Unit,
  onDismiss: () -> Unit,
) {
  if (!visible) {
    return
  }
  val colors = MoreMoneyTheme.colors
  var text by remember(bookName, visible) {
    mutableStateOf(if (currentCents > 0) MoneyUtil.formatYuan(currentCents).replace("−", "") else "")
  }
  var error by remember(bookName, visible) { mutableStateOf("") }

  AlertDialog(
    onDismissRequest = onDismiss,
    containerColor = colors.surface,
    shape = RoundedCornerShape(Radius.card),
    title = {
      Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(text = "设置预算", style = MoreMoneyTextStyles.subTitle, color = colors.ink)
        Text(
          text = "$bookName · $monthLabel",
          style = MoreMoneyTextStyles.caption,
          color = colors.ink3,
        )
      }
    },
    text = {
      Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
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
        )
        if (error.isNotEmpty()) {
          Text(text = error, style = MoreMoneyTextStyles.caption, color = colors.expense)
        }
        if (currentCents > 0) {
          Text(
            text = "清空本月预算",
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
            else -> onSave(cents)
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
