package com.github.ppg007.moremoney.ui.components.base

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.github.ppg007.moremoney.R
import com.github.ppg007.moremoney.data.db.entity.BookEntity
import com.github.ppg007.moremoney.ui.components.iconResOf
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.ui.theme.parseColorOf
import com.github.ppg007.moremoney.ui.theme.withAlpha

/** 账本切换 chip；`onHero=true` 用于首页渐变背景。 */
@Composable
fun BookChip(
  label: String,
  selected: Boolean,
  onClick: () -> Unit,
  modifier: Modifier = Modifier,
  book: BookEntity? = null,
  onHero: Boolean = false,
) {
  val colors = MoreMoneyTheme.colors
  val background =
    when {
      onHero && selected -> withAlpha(colors.onHero, 0.2f)
      onHero -> colors.heroGlass
      selected -> colors.brandWash
      else -> colors.surface
    }
  val border =
    when {
      onHero && selected -> withAlpha(colors.onHero, 0.45f)
      onHero -> colors.heroLine
      selected -> colors.brandSoft
      else -> colors.line
    }
  val foreground = if (onHero) colors.onHero else if (selected) colors.brandInk else colors.ink2
  val iconRes = if (book != null) iconResOf(book.icon) else R.drawable.ic_all
  val iconTint =
    when {
      onHero -> colors.onHero
      book != null -> parseColorOf(book.color)
      else -> colors.brandInk
    }
  val iconBackground =
    when {
      onHero -> withAlpha(colors.onHero, 0.18f)
      book != null -> withAlpha(parseColorOf(book.color), 0.16f)
      else -> colors.brandWash
    }

  Row(
    modifier =
      modifier
        .clip(RoundedCornerShape(Radius.chip))
        .background(background)
        .border(1.dp, border, RoundedCornerShape(Radius.chip))
        .clickable(onClick = onClick)
        .padding(start = 6.dp, end = 10.dp, top = 6.dp, bottom = 6.dp),
    verticalAlignment = Alignment.CenterVertically,
    horizontalArrangement = Arrangement.spacedBy(5.dp),
  ) {
    Box(
      modifier =
        Modifier
          .size(22.dp)
          .clip(RoundedCornerShape(7.dp))
          .background(iconBackground),
      contentAlignment = Alignment.Center,
    ) {
      Icon(
        painter = painterResource(iconRes),
        contentDescription = null,
        tint = iconTint,
        modifier = Modifier.size(13.dp),
      )
    }
    Text(
      text = label,
      style = MoreMoneyTextStyles.caption.copy(fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal),
      color = foreground,
    )
  }
}
