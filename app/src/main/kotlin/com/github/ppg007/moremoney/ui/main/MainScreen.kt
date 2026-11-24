package com.github.ppg007.moremoney.ui.main

import androidx.annotation.DrawableRes
import androidx.annotation.StringRes
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.github.ppg007.moremoney.R
import com.github.ppg007.moremoney.state.AppUiState
import com.github.ppg007.moremoney.ui.budget.BudgetScreen
import com.github.ppg007.moremoney.ui.charts.ChartsScreen
import com.github.ppg007.moremoney.ui.ledger.LedgerScreen
import com.github.ppg007.moremoney.ui.settings.SettingsScreen
import com.github.ppg007.moremoney.ui.theme.IconSize
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius

private val TabBarHeight = 62.dp
private val TabPillWidth = 38.dp
private val TabPillHeight = 25.dp

private enum class AppTab(
  @StringRes val labelRes: Int,
  @DrawableRes val iconRes: Int,
  val testTag: String,
) {
  Ledger(R.string.tab_ledger, R.drawable.ic_tab_books, "tab_ledger"),
  Budget(R.string.tab_budget, R.drawable.ic_tab_budget, "tab_budget"),
  Charts(R.string.tab_charts, R.drawable.ic_tab_charts, "tab_charts"),
  Settings(R.string.tab_settings, R.drawable.ic_tab_settings, "tab_settings"),
}

/**
 * 应用外壳：4 个一级 Tab + 统一的底部栏。
 *
 * 二级页通过回调交给根导航；Tab 选中态在进程重建后由 `rememberSaveable` 保持。
 */
@Composable
fun MainScreen(
  ui: AppUiState,
  onAddTxn: (bookId: String, dayKey: String) -> Unit,
  onSearch: () -> Unit,
  onEditTxn: (String) -> Unit,
  onBookManage: () -> Unit,
  onCategoryManage: () -> Unit,
  onDataBackup: () -> Unit,
  modifier: Modifier = Modifier,
) {
  var selectedIndex by rememberSaveable { mutableIntStateOf(0) }
  val selectedTab = AppTab.entries[selectedIndex]

  Scaffold(
    modifier = modifier.fillMaxSize(),
    containerColor = MoreMoneyTheme.colors.background,
    contentWindowInsets = WindowInsets(0, 0, 0, 0),
    bottomBar = {
      MoreMoneyBottomBar(
        selectedIndex = selectedIndex,
        onSelect = { selectedIndex = it },
      )
    },
  ) { innerPadding ->
    Box(
      modifier =
        Modifier
          .fillMaxSize()
          .padding(innerPadding),
    ) {
      when (selectedTab) {
        AppTab.Ledger ->
          LedgerScreen(
            ui = ui,
            onAdd = onAddTxn,
            onSearch = onSearch,
            onEditTxn = onEditTxn,
            onGoBudget = { selectedIndex = 1 },
          )
        AppTab.Budget -> BudgetScreen(ui = ui)
        AppTab.Charts -> ChartsScreen(ui = ui)
        AppTab.Settings ->
          SettingsScreen(
            ui = ui,
            onBookManage = onBookManage,
            onCategoryManage = onCategoryManage,
            onDataBackup = onDataBackup,
          )
      }
    }
  }
}

@Composable
private fun MoreMoneyBottomBar(
  selectedIndex: Int,
  onSelect: (Int) -> Unit,
) {
  val colors = MoreMoneyTheme.colors

  Row(
    modifier =
      Modifier
        .fillMaxWidth()
        .background(colors.tabBackground)
        .drawBehind {
          val stroke = 1.dp.toPx()
          drawLine(
            color = colors.line,
            start = Offset(0f, stroke / 2f),
            end = Offset(size.width, stroke / 2f),
            strokeWidth = stroke,
          )
        }
        .navigationBarsPadding()
        .height(TabBarHeight),
    verticalAlignment = Alignment.CenterVertically,
  ) {
    AppTab.entries.forEachIndexed { index, tab ->
      TabItem(
        tab = tab,
        selected = index == selectedIndex,
        onClick = { onSelect(index) },
        modifier = Modifier.weight(1f),
      )
    }
  }
}

@Composable
private fun TabItem(
  tab: AppTab,
  selected: Boolean,
  onClick: () -> Unit,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  val tint = if (selected) colors.brandInk else colors.ink3

  Column(
    modifier =
      modifier
        .fillMaxHeight()
        .testTag(tab.testTag)
        .selectable(
          selected = selected,
          onClick = onClick,
          role = Role.Tab,
        ),
    horizontalAlignment = Alignment.CenterHorizontally,
    verticalArrangement = Arrangement.Center,
  ) {
    Box(
      modifier =
        Modifier
          .width(TabPillWidth)
          .height(TabPillHeight)
          .clip(RoundedCornerShape(Radius.pill))
          .background(if (selected) colors.brandSoft else Color.Transparent),
      contentAlignment = Alignment.Center,
    ) {
      Icon(
        painter = painterResource(tab.iconRes),
        contentDescription = null,
        tint = tint,
        modifier = Modifier.size(IconSize.tab),
      )
    }
    Spacer(Modifier.height(2.dp))
    Text(
      text = stringResource(tab.labelRes),
      style =
        MaterialTheme.typography.labelSmall.copy(
          fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
        ),
      color = tint,
    )
  }
}
