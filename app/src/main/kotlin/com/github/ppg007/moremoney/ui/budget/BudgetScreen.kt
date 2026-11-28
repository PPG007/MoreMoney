package com.github.ppg007.moremoney.ui.budget

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.github.ppg007.moremoney.R
import com.github.ppg007.moremoney.service.BudgetBookView
import com.github.ppg007.moremoney.service.BudgetCycleUtil
import com.github.ppg007.moremoney.state.AppUiState
import com.github.ppg007.moremoney.ui.common.SystemBarAppearance
import com.github.ppg007.moremoney.ui.common.appViewModel
import com.github.ppg007.moremoney.ui.components.base.AppIconButton
import com.github.ppg007.moremoney.ui.components.base.EyeButton
import com.github.ppg007.moremoney.ui.components.base.MiniButton
import com.github.ppg007.moremoney.ui.components.base.MoneyText
import com.github.ppg007.moremoney.ui.components.base.MoneyTone
import com.github.ppg007.moremoney.ui.components.base.RingProgress
import com.github.ppg007.moremoney.ui.components.base.dashedBorder
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.ui.theme.Spacing
import com.github.ppg007.moremoney.ui.components.iconResOf
import com.github.ppg007.moremoney.ui.theme.tabularNumbers
import com.github.ppg007.moremoney.ui.theme.parseColorOf
import com.github.ppg007.moremoney.ui.theme.withAlpha
import kotlin.math.roundToInt

/**
 * 一级 Tab“预算”：单账本预算卡（可左右切换）、待设置预算。
 *
 * 每个账本按自身周期展示，不做跨账本合并；默认账本有预算时优先展示。
 * 隐藏金额时数字、进度填充、百分比一起隐藏。
 */
@Composable
fun BudgetScreen(
  ui: AppUiState,
  modifier: Modifier = Modifier,
) {
  val viewModel: BudgetViewModel = appViewModel { BudgetViewModel(it) }
  val state by viewModel.state.collectAsStateWithLifecycle()
  val colors = MoreMoneyTheme.colors
  var editingBook by remember { mutableStateOf<BudgetBookView?>(null) }

  SystemBarAppearance()

  Column(
    modifier =
      modifier
        .fillMaxSize()
        .testTag("budget_screen")
        .background(colors.background)
        .verticalScroll(rememberScrollState())
        .statusBarsPadding()
        .padding(horizontal = Spacing.page)
        .padding(top = 10.dp),
  ) {
    Row(verticalAlignment = Alignment.CenterVertically) {
      Text(
        text = "预算",
        style = MoreMoneyTextStyles.pageTitle,
        color = colors.ink,
        modifier = Modifier.weight(1f),
      )
      EyeButton(ui = ui)
    }

    state.selectedBook?.let { book ->
      MainBudgetCard(
        book = book,
        position = state.selectedIndex + 1,
        count = state.budgeted.size,
        hidden = ui.hideAmount,
        onPrevious = viewModel::selectPreviousBook,
        onNext = viewModel::selectNextBook,
        onClick = { editingBook = book },
        modifier = Modifier.padding(top = Spacing.x4),
      )
    }

    if (state.unset.isNotEmpty()) {
      SectionTitle(
        title = "待设置预算",
        count = state.unset.size,
        modifier = Modifier.padding(top = Spacing.x5),
      )
      state.unset.forEach { book ->
        UnsetBudgetCard(
          book = book,
          hidden = ui.hideAmount,
          onSet = { editingBook = book },
          modifier = Modifier.padding(top = Spacing.x3),
        )
      }
    }

    Text(
      text = "预算按账本设置，可选择年度、季度或月度周期，设置后自动重复，无需逐月重设。" +
        "每张卡片只展示该账本自身周期的进度，不做跨账本合并；有多个已设预算账本时可左右切换。" +
        "每天可用 = 剩余 ÷ 当前周期剩余天数（含今天）。",
      style = MoreMoneyTextStyles.caption,
      color = colors.ink3,
      modifier = Modifier.padding(top = Spacing.x5, bottom = 120.dp),
    )
  }

  val editing = editingBook
  if (editing != null) {
    BudgetEditDialog(
      visible = true,
      bookName = editing.name,
      currentCycle = editing.cycle,
      currentCents = editing.budgetCents,
      onSave = { cycle, cents ->
        viewModel.setBudget(editing.bookId, cycle, cents)
        editingBook = null
      },
      onClear = {
        viewModel.clearBudget(editing.bookId)
        editingBook = null
      },
      onDismiss = { editingBook = null },
    )
  }
}

@Composable
private fun SectionTitle(title: String, count: Int, modifier: Modifier = Modifier) {
  val colors = MoreMoneyTheme.colors
  Row(modifier = modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
    Text(
      text = title,
      style = MoreMoneyTextStyles.body.copy(fontWeight = FontWeight.Bold),
      color = colors.ink,
      modifier = Modifier.weight(1f),
    )
    Text(text = count.toString(), style = MoreMoneyTextStyles.caption, color = colors.ink3)
  }
}

@Composable
private fun MainBudgetCard(
  book: BudgetBookView,
  position: Int,
  count: Int,
  hidden: Boolean,
  onPrevious: () -> Unit,
  onNext: () -> Unit,
  onClick: () -> Unit,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  val color = parseColorOf(book.color)
  val percent = book.percent.coerceIn(0f, 1f)
  val overflow = book.remainingCents < 0
  Column(
    modifier =
      modifier
        .fillMaxWidth()
        .clip(RoundedCornerShape(Radius.cardLg))
        .background(colors.surface)
        .border(1.dp, colors.line, RoundedCornerShape(Radius.cardLg))
        .clickable(onClick = onClick)
        .padding(17.dp),
  ) {
    Row(verticalAlignment = Alignment.CenterVertically) {
      Box(
        modifier =
          Modifier
            .size(36.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(withAlpha(color, 0.16f)),
        contentAlignment = Alignment.Center,
      ) {
        Icon(
          painter = painterResource(iconResOf(book.icon)),
          contentDescription = null,
          tint = color,
          modifier = Modifier.size(19.dp),
        )
      }
      Column(modifier = Modifier.padding(start = 9.dp).weight(1f)) {
        Text(
          text = book.name,
          style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.Bold),
          color = colors.ink,
          maxLines = 1,
          overflow = TextOverflow.Ellipsis,
        )
        Text(text = BudgetCycleUtil.label(book.cycle), style = MoreMoneyTextStyles.caption, color = colors.ink3)
      }
      if (count > 1) {
        AppIconButton(
          iconRes = R.drawable.ic_chevron_left,
          contentDescription = "上一个账本",
          onClick = onPrevious,
          modifier = Modifier.testTag("budget_prev"),
          size = 30,
          iconSize = 15,
        )
        Text(
          text = "$position/$count",
          style = MoreMoneyTextStyles.caption,
          color = colors.ink3,
          modifier = Modifier.padding(horizontal = 2.dp),
        )
        AppIconButton(
          iconRes = R.drawable.ic_chevron_right,
          contentDescription = "下一个账本",
          onClick = onNext,
          modifier = Modifier.testTag("budget_next"),
          size = 30,
          iconSize = 15,
        )
      }
    }

    Row(
      modifier = Modifier.padding(top = Spacing.x5),
      verticalAlignment = Alignment.CenterVertically,
    ) {
      RingProgress(progress = percent, hidden = hidden, overflow = overflow) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
          Text(
            text = if (hidden) "••" else "${(percent * 100).roundToInt()}%",
            style = MoreMoneyTextStyles.ringCenter.tabularNumbers(),
            color = if (overflow) colors.expense else colors.ink,
          )
          Text(text = "已用", style = MoreMoneyTextStyles.caption, color = colors.ink3)
        }
      }
      Column(
        modifier = Modifier.padding(start = 17.dp).weight(1f),
        verticalArrangement = Arrangement.spacedBy(8.dp),
      ) {
        BudgetLine("预算", book.budgetCents, MoneyTone.Ink, hidden)
        BudgetLine("已用", book.spentCents, MoneyTone.Expense, hidden)
        BudgetLine(
          if (overflow) "超支" else "剩余",
          if (overflow) -book.remainingCents else book.remainingCents,
          if (overflow) MoneyTone.Expense else MoneyTone.Good,
          hidden,
        )
      }
    }

    Row(
      modifier =
        Modifier
          .padding(top = Spacing.x4)
          .fillMaxWidth()
          .clip(RoundedCornerShape(11.dp))
          .background(colors.brandWash)
          .padding(horizontal = 11.dp, vertical = 9.dp),
      verticalAlignment = Alignment.CenterVertically,
    ) {
      Text(text = "每天可用", style = MoreMoneyTextStyles.caption, color = colors.ink2, modifier = Modifier.weight(1f))
      MoneyText(
        cents = book.perDayCents,
        hidden = hidden,
        tone = MoneyTone.BrandInk,
        style = MoreMoneyTextStyles.settingsTitle.copy(fontWeight = FontWeight.Bold),
      )
    }
  }
}

@Composable
private fun BudgetLine(label: String, cents: Long, tone: MoneyTone, hidden: Boolean) {
  val colors = MoreMoneyTheme.colors
  Row(verticalAlignment = Alignment.CenterVertically) {
    Text(text = label, style = MoreMoneyTextStyles.caption, color = colors.ink3, modifier = Modifier.weight(1f))
    MoneyText(cents = cents, hidden = hidden, tone = tone, style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.Bold))
  }
}

@Composable
private fun UnsetBudgetCard(
  book: BudgetBookView,
  hidden: Boolean,
  onSet: () -> Unit,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  val color = parseColorOf(book.color)
  Row(
    modifier =
      modifier
        .fillMaxWidth()
        .clip(RoundedCornerShape(Radius.card))
        .background(withAlpha(colors.brandWash, 0.55f))
        .dashedBorder(colors.line, Radius.card, 1.5.dp)
        .padding(15.dp),
    verticalAlignment = Alignment.CenterVertically,
    horizontalArrangement = Arrangement.spacedBy(11.dp),
  ) {
    Box(
      modifier =
        Modifier
          .size(42.dp)
          .clip(RoundedCornerShape(13.dp))
          .background(withAlpha(color, 0.14f)),
      contentAlignment = Alignment.Center,
    ) {
      Icon(
        painter = painterResource(iconResOf(book.icon)),
        contentDescription = null,
        tint = color,
        modifier = Modifier.size(21.dp),
      )
    }
    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
      Text(text = book.name, style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.Bold), color = colors.ink)
      Text(text = "还没有设置预算", style = MoreMoneyTextStyles.caption, color = colors.ink3)
      Text(text = "设置后按年 / 季 / 月自动重复", style = MoreMoneyTextStyles.caption, color = colors.ink3)
    }
    MiniButton(text = "设置预算", onClick = onSet)
  }
}
