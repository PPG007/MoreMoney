package com.github.ppg007.moremoney.ui.ledger

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.github.ppg007.moremoney.data.db.entity.BookEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryEntity
import com.github.ppg007.moremoney.data.db.entity.TxnEntity
import com.github.ppg007.moremoney.ui.components.base.AppBottomSheet
import com.github.ppg007.moremoney.ui.components.base.MoneyText
import com.github.ppg007.moremoney.ui.components.base.MoneyTone
import com.github.ppg007.moremoney.ui.components.base.SheetTitle
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.ui.theme.Spacing
import com.github.ppg007.moremoney.util.DateUtil

/** 流水详情（只读）+ 编辑/删除入口。 */
@Composable
fun TxnDetailSheet(
  txn: TxnEntity,
  category: CategoryEntity?,
  book: BookEntity?,
  hidden: Boolean,
  onDismiss: () -> Unit,
  onEdit: () -> Unit,
  onDelete: () -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  AppBottomSheet(onDismiss = onDismiss) {
    SheetTitle(title = if (txn.note.isBlank()) (category?.name ?: "未分类") else txn.note)
    MoneyText(
      cents = txn.amountCents,
      hidden = hidden,
      tone = MoneyTone.Expense,
      style = MoreMoneyTextStyles.heroAmount,
    )
    DetailRow("分类", category?.name ?: "未分类")
    DetailRow("账本", book?.name ?: "")
    DetailRow("日期", DateUtil.formatDayCn(txn.dayKey))
    if (txn.note.isNotBlank()) {
      DetailRow("备注", txn.note)
    }
    Row(horizontalArrangement = Arrangement.spacedBy(Spacing.x3), modifier = Modifier.fillMaxWidth()) {
      Box(
        modifier =
          Modifier
            .weight(1f)
            .clip(RoundedCornerShape(Radius.button))
            .background(colors.surface2)
            .clickable(onClick = onDelete)
            .padding(vertical = 12.dp),
        contentAlignment = Alignment.Center,
      ) {
        Text(
          text = "删除",
          style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.Bold),
          color = colors.expense,
        )
      }
      Box(
        modifier =
          Modifier
            .weight(1.5f)
            .clip(RoundedCornerShape(Radius.button))
            .background(colors.buttonBackground)
            .clickable(onClick = onEdit)
            .padding(vertical = 12.dp),
        contentAlignment = Alignment.Center,
      ) {
        Text(
          text = "编辑",
          style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.Bold),
          color = colors.buttonForeground,
        )
      }
    }
  }
}

@Composable
private fun DetailRow(label: String, value: String) {
  val colors = MoreMoneyTheme.colors
  Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
    Text(
      text = label,
      style = MoreMoneyTextStyles.caption,
      color = colors.ink3,
      modifier = Modifier.weight(1f),
    )
    Text(text = value, style = MoreMoneyTextStyles.settingsTitle, color = colors.ink)
  }
}
