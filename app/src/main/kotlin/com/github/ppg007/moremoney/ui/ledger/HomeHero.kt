package com.github.ppg007.moremoney.ui.ledger

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.github.ppg007.moremoney.R
import com.github.ppg007.moremoney.data.db.entity.BookEntity
import com.github.ppg007.moremoney.state.AppUiState
import com.github.ppg007.moremoney.ui.components.base.BookChip
import com.github.ppg007.moremoney.ui.components.base.EyeButton
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.ui.theme.Spacing
import com.github.ppg007.moremoney.ui.theme.tabularNumbers

/** 首页 Hero：标题、搜索、眼睛按钮、月份切换与账本 chips。 */
@Composable
fun HomeHero(
  ui: AppUiState,
  monthLabel: String,
  books: List<BookEntity>,
  selectedBookId: String,
  onSelectBook: (String) -> Unit,
  onSearch: () -> Unit,
  onPrevMonth: () -> Unit,
  onNextMonth: () -> Unit,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  Column(
    modifier =
      modifier
        .fillMaxWidth()
        .clip(RoundedCornerShape(bottomStart = Radius.hero, bottomEnd = Radius.hero))
        .background(
          Brush.linearGradient(
            colors = listOf(colors.heroStart, colors.heroMiddle, colors.heroEnd),
          )
        )
        .padding(horizontal = Spacing.x7)
        .padding(top = 10.dp, bottom = 78.dp)
        .statusBarsPadding(),
    verticalArrangement = Arrangement.spacedBy(Spacing.x4),
  ) {
    Row(verticalAlignment = Alignment.CenterVertically) {
      Text(
        text = "记账本",
        style = MoreMoneyTextStyles.pageTitle,
        color = colors.onHero,
        modifier = Modifier.weight(1f),
      )
      Row(horizontalArrangement = Arrangement.spacedBy(Spacing.x2), verticalAlignment = Alignment.CenterVertically) {
        HeroIconButton(iconRes = R.drawable.ic_search, description = stringResource(R.string.cd_search), onClick = onSearch)
        EyeButton(ui = ui, hero = true)
      }
    }

    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Spacing.x5)) {
      HeroIconButton(
        iconRes = R.drawable.ic_chevron_left,
        description = "上个月",
        onClick = onPrevMonth,
        modifier = Modifier.testTag("month_prev"),
      )
      Text(
        text = monthLabel,
        style = MoreMoneyTextStyles.month.tabularNumbers(),
        color = colors.onHero,
        modifier = Modifier.weight(1f),
        textAlign = androidx.compose.ui.text.style.TextAlign.Center,
      )
      HeroIconButton(
        iconRes = R.drawable.ic_chevron_right,
        description = "下个月",
        onClick = onNextMonth,
        modifier = Modifier.testTag("month_next"),
      )
    }

    Row(
      modifier = Modifier.horizontalScroll(rememberScrollState()),
      horizontalArrangement = Arrangement.spacedBy(Spacing.x2),
    ) {
      BookChip(
        label = "全部",
        selected = selectedBookId.isEmpty(),
        onHero = true,
        onClick = { onSelectBook("") },
        modifier = Modifier.testTag("book_chip_all"),
      )
      books.forEach { book ->
        BookChip(
          label = book.name,
          selected = selectedBookId == book.id,
          book = book,
          onHero = true,
          onClick = { onSelectBook(book.id) },
          modifier = Modifier.testTag("book_chip_${book.id}"),
        )
      }
    }
  }
}

@Composable
private fun HeroIconButton(
  iconRes: Int,
  description: String,
  onClick: () -> Unit,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  Box(
    modifier =
      modifier
        .size(36.dp)
        .clip(RoundedCornerShape(Radius.pill))
        .background(colors.heroGlass)
        .border(1.dp, colors.heroLine, RoundedCornerShape(Radius.pill))
        .clickable(onClick = onClick),
    contentAlignment = Alignment.Center,
  ) {
    Icon(
      painter = painterResource(iconRes),
      contentDescription = description,
      tint = colors.onHero,
      modifier = Modifier.size(17.dp),
    )
  }
}
