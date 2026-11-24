package com.github.ppg007.moremoney.ui.charts

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.github.ppg007.moremoney.appContainer
import com.github.ppg007.moremoney.data.db.entity.TxnEntity
import com.github.ppg007.moremoney.models.BucketSum
import com.github.ppg007.moremoney.models.CategorySum
import com.github.ppg007.moremoney.models.DaySum
import com.github.ppg007.moremoney.state.AppUiState
import com.github.ppg007.moremoney.ui.common.SystemBarAppearance
import com.github.ppg007.moremoney.ui.common.appViewModel
import com.github.ppg007.moremoney.ui.components.base.AppBottomSheet
import com.github.ppg007.moremoney.ui.components.base.AppDatePickerDialog
import com.github.ppg007.moremoney.ui.components.base.CategoryCircle
import com.github.ppg007.moremoney.ui.components.base.Chip
import com.github.ppg007.moremoney.ui.components.base.EmptyState
import com.github.ppg007.moremoney.ui.components.base.EyeButton
import com.github.ppg007.moremoney.ui.components.base.MoneyText
import com.github.ppg007.moremoney.ui.components.base.MoneyTone
import com.github.ppg007.moremoney.ui.components.base.SegmentedControl
import com.github.ppg007.moremoney.ui.components.base.SheetTitle
import com.github.ppg007.moremoney.ui.ledger.DayHeader
import com.github.ppg007.moremoney.ui.ledger.TxnDetailSheet
import com.github.ppg007.moremoney.ui.ledger.TxnRow
import com.github.ppg007.moremoney.ui.theme.ChartPalette
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.ui.theme.SeedColors
import com.github.ppg007.moremoney.ui.theme.Spacing
import com.github.ppg007.moremoney.ui.theme.isDarkTheme
import com.github.ppg007.moremoney.ui.theme.parseColorOf
import com.github.ppg007.moremoney.ui.theme.withAlpha
import com.github.ppg007.moremoney.util.DateUtil
import com.github.ppg007.moremoney.util.MoneyUtil
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

private val PeriodLabels = listOf("本月", "上月", "今年", "全部", "自定义")

/**
 * 一级 Tab“图表”：分类占比、趋势、日历热力三个子页。
 */
@Composable
fun ChartsScreen(
  ui: AppUiState,
  modifier: Modifier = Modifier,
) {
  val viewModel: ChartsViewModel = appViewModel { ChartsViewModel(it) }
  val state by viewModel.state.collectAsStateWithLifecycle()
  val container = LocalContext.current.appContainer
  val colors = MoreMoneyTheme.colors
  val txns by container.txnRepository.observeActive().collectAsStateWithLifecycle(emptyList())
  val categories by container.categoryRepository.observeAll().collectAsStateWithLifecycle(emptyList())
  val categoryById = categories.associateBy { it.id }
  var selectedCategory by remember { mutableStateOf(-1) }
  var selectedDay by remember { mutableStateOf(DateUtil.nowDayKey()) }
  var detailTxn by remember { mutableStateOf<TxnEntity?>(null) }
  var showRangeStart by remember { mutableStateOf(false) }
  var showRangeEnd by remember { mutableStateOf(false) }
  var rangeStartDay by remember { mutableStateOf<String?>(null) }
  val isDark = isDarkTheme()

  SystemBarAppearance(darkIcons = true)

  LaunchedEffect(state.calendarMonth) {
    selectedDay =
      if (state.calendarMonth == DateUtil.monthKey(DateUtil.today())) {
        DateUtil.nowDayKey()
      } else {
        "${state.calendarMonth}-01"
      }
  }

  Column(
    modifier =
      modifier
        .fillMaxSize()
        .background(colors.background)
        .verticalScroll(rememberScrollState())
        .statusBarsPadding()
        .padding(horizontal = Spacing.page)
        .padding(top = 10.dp),
  ) {
    Row(verticalAlignment = Alignment.CenterVertically) {
      Text(
        text = "图表",
        style = MoreMoneyTextStyles.pageTitle,
        color = colors.ink,
        modifier = Modifier.weight(1f),
      )
      EyeButton(ui = ui)
    }

    SegmentedControl(
      options = listOf("分类", "趋势", "日历"),
      selectedIndex = state.segment,
      onSelect = {
        selectedCategory = -1
        viewModel.setSegment(it)
      },
      modifier = Modifier.padding(top = Spacing.x4),
    )

    Row(
      modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()).padding(vertical = Spacing.x3),
      horizontalArrangement = Arrangement.spacedBy(Spacing.x2),
    ) {
      PeriodLabels.forEachIndexed { index, label ->
        val selected = state.periodIndex == index
        Text(
          text = if (index == 4 && state.periodIndex == 4) state.periodLabel else label,
          style = MoreMoneyTextStyles.caption.copy(fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal),
          color = if (selected) colors.buttonForeground else colors.ink2,
          modifier =
            Modifier
              .clip(RoundedCornerShape(Radius.pill))
              .background(if (selected) colors.brandInk else colors.surface)
              .border(1.dp, if (selected) colors.brandInk else colors.line, RoundedCornerShape(Radius.pill))
              .clickable {
                if (index == 4) {
                  rangeStartDay = null
                  showRangeStart = true
                } else {
                  viewModel.setPeriod(index)
                }
              }
              .padding(horizontal = 11.dp, vertical = 6.dp),
        )
      }
    }

    when (state.segment) {
      0 -> CategorySection(
        state = state,
        hidden = ui.hideAmount,
        isDark = isDark,
        selected = selectedCategory,
        onSelect = { selectedCategory = it },
      )
      1 -> TrendSection(state = state, hidden = ui.hideAmount)
      else -> CalendarSection(
        state = state,
        txns = txns,
        hidden = ui.hideAmount,
        selectedDay = selectedDay,
        categoryById = categoryById,
        onSelectDay = { selectedDay = it },
        onPrevMonth = { viewModel.changeCalendarMonth(-1) },
        onNextMonth = { viewModel.changeCalendarMonth(1) },
        onShowTxn = { detailTxn = it },
      )
    }

    Spacer(Modifier.height(120.dp))
  }

  if (showRangeStart) {
    AppDatePickerDialog(
      initial = DateUtil.today(),
      title = "选择开始日期",
      onConfirm = { start ->
        rangeStartDay = DateUtil.dayKey(start)
        showRangeStart = false
        showRangeEnd = true
      },
      onDismiss = { showRangeStart = false },
    )
  }

  if (showRangeEnd) {
    AppDatePickerDialog(
      initial = DateUtil.today(),
      title = "选择结束日期",
      onConfirm = { end ->
        rangeStartDay?.let { start -> viewModel.setCustomRange(start, DateUtil.dayKey(end)) }
        rangeStartDay = null
        showRangeEnd = false
      },
      onDismiss = {
        rangeStartDay = null
        showRangeEnd = false
      },
    )
  }

  detailTxn?.let { txn ->
    TxnDetailSheet(
      txn = txn,
      category = categoryById[txn.categoryId],
      book = null,
      hidden = ui.hideAmount,
      onDismiss = { detailTxn = null },
      onEdit = { detailTxn = null },
      onDelete = {
        detailTxn = null
        container.appScope.launch {
          runCatching { container.deleteService.deleteTxn(txn.id) }
            .onSuccess {
              container.ui.showSnack("已删除 1 笔", "撤销", 5000) {
                container.appScope.launch {
                  runCatching { container.deleteService.undoDelete(txn.id) }
                }
              }
            }
        }
      },
    )
  }
}

@Composable
private fun CategorySection(
  state: ChartsUiState,
  hidden: Boolean,
  isDark: Boolean,
  selected: Int,
  onSelect: (Int) -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  val slices =
    state.legend.mapIndexed { index, item ->
      val color =
        if (item.categoryId == "__other__") {
          ChartPalette.other(isDark)
        } else {
          parseColorOf(item.color)
        }
      DonutSlice(cents = item.cents, color = color, name = item.name)
    }

  Column(
    modifier =
      Modifier
        .fillMaxWidth()
        .clip(RoundedCornerShape(Radius.cardLg))
        .background(colors.chartSurface)
        .border(1.dp, colors.line, RoundedCornerShape(Radius.cardLg))
        .padding(15.dp),
    verticalArrangement = Arrangement.spacedBy(Spacing.x4),
  ) {
    if (state.legend.isEmpty()) {
      EmptyState(title = "区间内暂无支出", description = "换个周期或先记一笔")
    } else {
      Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
        DonutChart(
          slices = slices,
          totalCents = state.totalCents,
          hidden = hidden,
          selectedIndex = selected,
          onSelect = onSelect,
          centerLabel = state.periodLabel,
        )
      }
      Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
        state.legend.forEachIndexed { index, item ->
          LegendRow(
            item = item,
            total = state.totalCents,
            hidden = hidden,
            isDark = isDark,
            selected = selected == index,
            onClick = { onSelect(if (selected == index) -1 else index) },
          )
        }
      }
    }
  }
}

@Composable
private fun LegendRow(
  item: CategorySum,
  total: Long,
  hidden: Boolean,
  isDark: Boolean,
  selected: Boolean,
  onClick: () -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  val color = if (item.categoryId == "__other__") ChartPalette.other(isDark) else parseColorOf(item.color)
  val percent = if (total > 0) (item.cents.toFloat() / total * 100) else 0f
  Row(
    modifier =
      Modifier
        .fillMaxWidth()
        .clip(RoundedCornerShape(12.dp))
        .background(if (selected) colors.surface2 else colors.chartSurface)
        .clickable(onClick = onClick)
        .padding(horizontal = 8.dp, vertical = 9.dp),
    verticalAlignment = Alignment.CenterVertically,
    horizontalArrangement = Arrangement.spacedBy(8.dp),
  ) {
    Box(modifier = Modifier.size(8.dp).clip(CircleShape).background(color))
    CategoryCircle(iconName = item.icon, colorText = item.color.ifEmpty { SeedColors.neutral }, size = 28, iconSize = 14)
    Text(
      text = item.name,
      style = MoreMoneyTextStyles.legend,
      color = colors.ink,
      maxLines = 1,
      overflow = TextOverflow.Ellipsis,
      modifier = Modifier.weight(1f),
    )
    Text(
      text = "${percent.roundToInt()}%",
      style = MoreMoneyTextStyles.caption,
      color = colors.ink3,
    )
    MoneyText(
      cents = item.cents,
      hidden = hidden,
      tone = MoneyTone.Ink,
      style = MoreMoneyTextStyles.settingsTitle.copy(fontWeight = FontWeight.SemiBold),
      modifier = Modifier.size(width = 88.dp, height = 18.dp),
    )
  }
}

@Composable
private fun TrendSection(
  state: ChartsUiState,
  hidden: Boolean,
) {
  val colors = MoreMoneyTheme.colors
  Column(
    modifier =
      Modifier
        .fillMaxWidth()
        .clip(RoundedCornerShape(Radius.cardLg))
        .background(colors.chartSurface)
        .border(1.dp, colors.line, RoundedCornerShape(Radius.cardLg))
        .padding(15.dp),
    verticalArrangement = Arrangement.spacedBy(Spacing.x4),
  ) {
    Text(text = state.periodLabel, style = MoreMoneyTextStyles.caption, color = colors.ink3)
    Row(verticalAlignment = Alignment.Bottom) {
      MoneyText(
        cents = state.stats.totalCents,
        hidden = hidden,
        tone = MoneyTone.Expense,
        style = MoreMoneyTextStyles.trendMain,
        modifier = Modifier.weight(1f),
      )
    }
    TrendChart(buckets = state.buckets, hidden = hidden)
    Row(verticalAlignment = Alignment.CenterVertically) {
      TrendStat("日均", state.stats.avgCents, hidden, Modifier.weight(1f))
      TrendStat("最高", state.stats.maxCents, hidden, Modifier.weight(1f))
      TrendStat("天数", state.stats.days.toLong(), hidden, Modifier.weight(1f), isCount = true)
    }
    if (state.topDays.isNotEmpty()) {
      TopDaysList(
        days = state.topDays.map { BucketSum(key = it.dayKey, label = DateUtil.formatShortDay(it.dayKey), cents = it.cents) },
        hidden = hidden,
      )
    }
  }
}

@Composable
private fun TrendStat(
  label: String,
  cents: Long,
  hidden: Boolean,
  modifier: Modifier = Modifier,
  isCount: Boolean = false,
) {
  val colors = MoreMoneyTheme.colors
  Column(modifier = modifier) {
    if (isCount) {
      Text(
        text = if (hidden) "••" else cents.toString(),
        style = MoreMoneyTextStyles.body.copy(fontWeight = FontWeight.Bold),
        color = colors.ink,
      )
    } else {
      MoneyText(cents = cents, hidden = hidden, tone = MoneyTone.Ink, style = MoreMoneyTextStyles.body.copy(fontWeight = FontWeight.Bold))
    }
    Text(text = label, style = MoreMoneyTextStyles.caption, color = colors.ink3)
  }
}

@Composable
private fun CalendarSection(
  state: ChartsUiState,
  txns: List<TxnEntity>,
  hidden: Boolean,
  selectedDay: String,
  categoryById: Map<String, com.github.ppg007.moremoney.data.db.entity.CategoryEntity>,
  onSelectDay: (String) -> Unit,
  onPrevMonth: () -> Unit,
  onNextMonth: () -> Unit,
  onShowTxn: (TxnEntity) -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  Column(verticalArrangement = Arrangement.spacedBy(Spacing.x3)) {
    HeatCalendar(
      monthKey = state.calendarMonth,
      days = state.calendarDays,
      selectedDay = selectedDay,
      hidden = hidden,
      onSelectDay = onSelectDay,
      onPrevMonth = onPrevMonth,
      onNextMonth = onNextMonth,
    )
    val dayTxns = txns.filter { it.dayKey == selectedDay }
    Column(
      modifier =
        Modifier
          .fillMaxWidth()
          .clip(RoundedCornerShape(Radius.card))
          .background(colors.surface)
          .border(1.dp, colors.line, RoundedCornerShape(Radius.card)),
    ) {
      DayHeader(
        dayKey = selectedDay,
        cents = dayTxns.sumOf { it.amountCents },
        hidden = hidden,
        modifier = Modifier.padding(horizontal = 13.dp),
      )
      if (dayTxns.isEmpty()) {
        Text(
          text = "这一天没有记录",
          style = MoreMoneyTextStyles.caption,
          color = colors.ink3,
          modifier = Modifier.padding(13.dp),
        )
      } else {
        dayTxns.forEachIndexed { index, txn ->
          TxnRow(
            txn = txn,
            category = categoryById[txn.categoryId],
            hidden = hidden,
            isFirst = false,
            isLast = index == dayTxns.size - 1,
            onClick = { onShowTxn(txn) },
          )
          if (index != dayTxns.size - 1) {
            Box(
              modifier =
                Modifier
                  .padding(start = 66.dp)
                  .height(1.dp)
                  .fillMaxWidth()
                  .background(colors.line),
            )
          }
        }
      }
    }
  }
}
