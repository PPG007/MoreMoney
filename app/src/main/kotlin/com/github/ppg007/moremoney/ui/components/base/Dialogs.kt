package com.github.ppg007.moremoney.ui.components.base

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.ui.theme.Spacing

/** 通用确认弹窗；`danger=true` 时确认按钮使用支出红。 */
@Composable
fun ConfirmDialog(
  visible: Boolean,
  title: String,
  message: String,
  onConfirm: () -> Unit,
  onDismiss: () -> Unit,
  confirmLabel: String = "确定",
  cancelLabel: String = "取消",
  danger: Boolean = false,
) {
  if (!visible) {
    return
  }
  val colors = MoreMoneyTheme.colors
  AlertDialog(
    onDismissRequest = onDismiss,
    containerColor = colors.surface,
    shape = RoundedCornerShape(Radius.card),
    title = { Text(text = title, style = MoreMoneyTextStyles.subTitle, color = colors.ink) },
    text = { Text(text = message, style = MoreMoneyTextStyles.body, color = colors.ink2) },
    confirmButton = {
      TextButton(onClick = onConfirm) {
        Text(
          text = confirmLabel,
          style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.Bold),
          color = if (danger) colors.expense else colors.brandInk,
        )
      }
    },
    dismissButton = {
      TextButton(onClick = onDismiss) {
        Text(text = cancelLabel, style = MoreMoneyTextStyles.row, color = colors.ink2)
      }
    },
  )
}

/** 文本输入弹窗，用于设置预算、新建分组、改名等。 */
@Composable
fun InputDialog(
  visible: Boolean,
  title: String,
  onConfirm: (String) -> Unit,
  onDismiss: () -> Unit,
  initialValue: String = "",
  placeholder: String = "",
  confirmLabel: String = "保存",
  keyboardType: KeyboardType = KeyboardType.Text,
) {
  if (!visible) {
    return
  }
  val colors = MoreMoneyTheme.colors
  var value by remember(title, visible) { mutableStateOf(initialValue) }
  AlertDialog(
    onDismissRequest = onDismiss,
    containerColor = colors.surface,
    shape = RoundedCornerShape(Radius.card),
    title = { Text(text = title, style = MoreMoneyTextStyles.subTitle, color = colors.ink) },
    text = {
      AppTextField(
        value = value,
        onValueChange = { value = it },
        placeholder = placeholder,
        height = 44,
        keyboardOptions = KeyboardOptions(keyboardType = keyboardType),
      )
    },
    confirmButton = {
      TextButton(onClick = { onConfirm(value.trim()) }) {
        Text(text = confirmLabel, style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.Bold), color = colors.brandInk)
      }
    },
    dismissButton = {
      TextButton(onClick = onDismiss) {
        Text(text = "取消", style = MoreMoneyTextStyles.row, color = colors.ink2)
      }
    },
  )
}

/** 通用底部弹层容器；形状与阴影遵循设计规范。 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppBottomSheet(
  onDismiss: () -> Unit,
  modifier: Modifier = Modifier,
  content: @Composable ColumnScope.() -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
  ModalBottomSheet(
    onDismissRequest = onDismiss,
    sheetState = sheetState,
    containerColor = colors.surface,
    shape = RoundedCornerShape(topStart = Radius.sheet, topEnd = Radius.sheet),
    dragHandle = {
      Box(
        modifier =
          Modifier
            .padding(vertical = 10.dp)
            .size(width = 36.dp, height = 4.dp)
            .clip(RoundedCornerShape(Radius.pill))
            .background(colors.surface3),
      )
    },
  ) {
    Column(
      modifier =
        modifier
          .fillMaxWidth()
          .navigationBarsPadding()
          .padding(horizontal = Spacing.x7)
          .padding(bottom = Spacing.x8),
      verticalArrangement = Arrangement.spacedBy(Spacing.x5),
      content = content,
    )
  }
}

@Composable
fun SheetTitle(
  title: String,
  subtitle: String? = null,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  Column(modifier = modifier.fillMaxWidth()) {
    Text(text = title, style = MoreMoneyTextStyles.bookTitle, color = colors.ink)
    if (subtitle != null) {
      Text(text = subtitle, style = MoreMoneyTextStyles.caption, color = colors.ink3)
    }
  }
}

@Composable
fun SheetActions(
  cancelLabel: String = "取消",
  confirmLabel: String = "保存",
  onCancel: () -> Unit,
  onConfirm: () -> Unit,
  confirmEnabled: Boolean = true,
  danger: Boolean = false,
) {
  val colors = MoreMoneyTheme.colors
  Row(horizontalArrangement = Arrangement.spacedBy(Spacing.x3), modifier = Modifier.fillMaxWidth()) {
    Box(
      modifier =
        Modifier
          .weight(1f)
          .clip(RoundedCornerShape(Radius.button))
          .background(colors.surface2)
          .clickable(onClick = onCancel)
          .padding(vertical = 12.dp),
      contentAlignment = Alignment.Center,
    ) {
      Text(text = cancelLabel, style = MoreMoneyTextStyles.row, color = colors.ink2)
    }
    Box(
      modifier =
        Modifier
          .weight(1.5f)
          .clip(RoundedCornerShape(Radius.button))
          .background(if (confirmEnabled) (if (danger) colors.expense else colors.buttonBackground) else colors.surface3)
          .clickable(enabled = confirmEnabled, onClick = onConfirm)
          .padding(vertical = 12.dp),
      contentAlignment = Alignment.Center,
    ) {
      Text(
        text = confirmLabel,
        style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.Bold),
        color = if (confirmEnabled) colors.buttonForeground else colors.ink3,
      )
    }
  }
}

/** 关闭/取消时滚动列表用的透明色，避免误用品牌色。 */
val TransparentColor: Color = Color.Transparent
