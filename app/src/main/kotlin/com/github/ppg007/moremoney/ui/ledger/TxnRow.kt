package com.github.ppg007.moremoney.ui.ledger

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.github.ppg007.moremoney.data.db.entity.CategoryEntity
import com.github.ppg007.moremoney.data.db.entity.TxnEntity
import com.github.ppg007.moremoney.ui.components.base.CategoryCircle
import com.github.ppg007.moremoney.ui.components.base.MoneyText
import com.github.ppg007.moremoney.ui.components.base.MoneyTone
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.ui.theme.SeedColors
import com.github.ppg007.moremoney.util.DateUtil

/**
 * 流水行：图标 42、标题 13/600、副行分类、金额 14/700。
 * 长按触发删除菜单，单击打开详情。
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun TxnRow(
  txn: TxnEntity,
  category: CategoryEntity?,
  hidden: Boolean,
  isFirst: Boolean,
  isLast: Boolean,
  modifier: Modifier = Modifier,
  showDate: Boolean = false,
  onClick: () -> Unit = {},
  onLongClick: () -> Unit = {},
) {
  val colors = MoreMoneyTheme.colors
  val topRadius = if (isFirst) Radius.card else 0.dp
  val bottomRadius = if (isLast) Radius.card else 0.dp
  val shape = RoundedCornerShape(topStart = topRadius, topEnd = topRadius, bottomStart = bottomRadius, bottomEnd = bottomRadius)
  val categoryName = category?.name ?: "未分类"
  val title = txn.note.ifBlank { categoryName }
  val subtitle = if (showDate) "${DateUtil.formatDayCn(txn.dayKey)} · $categoryName" else categoryName

  Row(
    modifier =
      modifier
        .fillMaxWidth()
        .clip(shape)
        .background(colors.surface)
        .combinedClickable(onClick = onClick, onLongClick = onLongClick)
        .padding(horizontal = 13.dp, vertical = 11.dp),
    verticalAlignment = Alignment.CenterVertically,
    horizontalArrangement = Arrangement.spacedBy(11.dp),
  ) {
    CategoryCircle(
      iconName = category?.icon ?: "ic_cat_other",
      colorText = category?.color ?: SeedColors.neutral,
      size = 42,
      iconSize = 21,
    )
    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
      Text(
        text = title,
        style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.SemiBold),
        color = colors.ink,
        maxLines = 1,
        overflow = TextOverflow.Ellipsis,
      )
      Text(
        text = subtitle,
        style = MoreMoneyTextStyles.caption,
        color = colors.ink3,
        maxLines = 1,
        overflow = TextOverflow.Ellipsis,
      )
    }
    MoneyText(
      cents = txn.amountCents,
      hidden = hidden,
      tone = MoneyTone.Expense,
      style = MoreMoneyTextStyles.body.copy(fontWeight = FontWeight.Bold),
    )
  }
  if (!isLast) {
    Spacer(Modifier.height(0.dp))
  }
}

/** 日期分组头：5dp 圆点 + 11月9日 周一 + 当天小计。 */
@Composable
fun DayHeader(
  dayKey: String,
  cents: Long,
  hidden: Boolean,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  Row(
    modifier =
      modifier
        .fillMaxWidth()
        .background(colors.background)
        .padding(horizontal = 2.dp)
        .height(26.dp),
    verticalAlignment = Alignment.CenterVertically,
    horizontalArrangement = Arrangement.spacedBy(6.dp),
  ) {
    Box(
      modifier =
        Modifier
          .size(5.dp)
          .clip(CircleShape)
          .background(colors.brand),
    )
    Text(
      text = DateUtil.formatDayCn(dayKey),
      style = MoreMoneyTextStyles.caption.copy(fontWeight = FontWeight.SemiBold),
      color = colors.ink2,
      modifier = Modifier.weight(1f),
    )
    MoneyText(
      cents = cents,
      hidden = hidden,
      tone = MoneyTone.Ink,
      style = MoreMoneyTextStyles.caption.copy(fontWeight = FontWeight.SemiBold),
    )
  }
}
