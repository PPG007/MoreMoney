package com.github.ppg007.moremoney.ui.charts

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.github.ppg007.moremoney.AppContainer
import com.github.ppg007.moremoney.models.BucketGranularity
import com.github.ppg007.moremoney.models.BucketSum
import com.github.ppg007.moremoney.models.CategorySum
import com.github.ppg007.moremoney.models.DailyStats
import com.github.ppg007.moremoney.models.DaySum
import com.github.ppg007.moremoney.models.PeriodRange
import com.github.ppg007.moremoney.models.PeriodType
import com.github.ppg007.moremoney.models.StatsFilter
import com.github.ppg007.moremoney.service.PeriodResolver
import com.github.ppg007.moremoney.util.DateUtil
import com.github.ppg007.moremoney.util.ErrorUtil
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.mapLatest
import kotlinx.coroutines.flow.stateIn
import java.time.LocalDate
import java.time.Instant

data class ChartsUiState(
  val loading: Boolean = true,
  val error: String = "",
  val segment: Int = 0,
  val periodIndex: Int = 0,
  val periodLabel: String = "本月",
  val range: PeriodRange = PeriodRange(),
  val totalCents: Long = 0,
  val legend: List<CategorySum> = emptyList(),
  val buckets: List<BucketSum> = emptyList(),
  val bucketGranularity: BucketGranularity = BucketGranularity.DAY,
  val topDays: List<DaySum> = emptyList(),
  val stats: DailyStats = DailyStats(),
  val calendarMonth: String = DateUtil.monthKey(DateUtil.today()),
  val calendarDays: Map<String, Long> = emptyMap(),
  val calendarTotal: Long = 0,
  val txnCount: Int = 0,
)

/**
 * 图表页：分类占比、趋势、日历热力共用一套统计服务。
 *
 * 周期切换或任意流水变化都会重新聚合；空数据返回 0/空列表，不抛异常。
 */
class ChartsViewModel(private val container: AppContainer) : ViewModel() {
  private val segment = MutableStateFlow(0)
  private val periodIndex = MutableStateFlow(0)
  private val customRange = MutableStateFlow<Pair<String, String>?>(null)
  private val calendarMonth = MutableStateFlow(DateUtil.monthKey(DateUtil.today()))

  private val dataTick =
    combine(
      container.txnRepository.observeActive(),
      container.bookRepository.observeAll(),
    ) { _, _ -> Unit }

  private val params =
    combine(segment, periodIndex, customRange, calendarMonth) { seg, period, custom, month ->
      Params(seg, period, custom, month)
    }

  private data class Params(
    val segment: Int,
    val periodIndex: Int,
    val custom: Pair<String, String>?,
    val calendarMonth: String,
  )

  val state: StateFlow<ChartsUiState> =
    combine(dataTick, params) { _, p -> p }
      .mapLatest { p -> load(p) }
      .catch { error -> emit(ChartsUiState(loading = false, error = ErrorUtil.messageOf(error))) }
      .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), ChartsUiState())

  private suspend fun load(params: Params): ChartsUiState {
    val range = resolveRange(params.periodIndex, params.custom)
    val filter =
      StatsFilter(
        startMs = range.startMs,
        endMs = range.endMs,
        weekStart = container.settings.weekStart(),
      )
    val total = container.statsService.sum(filter)
    val legend = container.statsService.categoryLegend(filter)
    val granularity = PeriodResolver.bucketGranularity(range)
    val buckets = container.statsService.byBucket(filter, granularity)
    val topDays = container.statsService.topDays(filter, 3)
    val dailyStats = container.statsService.dailyStats(filter)

    val monthRange = DateUtil.rangeOfMonth(params.calendarMonth)
    val monthFilter = StatsFilter(startMs = monthRange.startMs, endMs = monthRange.endMs)
    val calendar = container.statsService.byDay(monthFilter)
    val calendarMap = calendar.associate { it.dayKey to it.cents }
    val calendarTotal = calendar.sumOf { it.cents }

    return ChartsUiState(
      loading = false,
      segment = params.segment,
      periodIndex = params.periodIndex,
      periodLabel = range.label,
      range = range,
      totalCents = total,
      legend = legend,
      buckets = buckets,
      bucketGranularity = granularity,
      topDays = topDays,
      stats = dailyStats,
      calendarMonth = params.calendarMonth,
      calendarDays = calendarMap,
      calendarTotal = calendarTotal,
      txnCount = calendar.size,
    )
  }

  private fun resolveRange(periodIndex: Int, custom: Pair<String, String>?): PeriodRange {
    val now = Instant.now()
    val weekStart = container.settings.weekStart()
    return when (periodIndex) {
      1 -> {
        val prevMonth = DateUtil.addMonths(DateUtil.monthKey(DateUtil.today()), -1)
        val range = DateUtil.rangeOfMonth(prevMonth)
        PeriodRange(startMs = range.startMs, endMs = range.endMs, label = DateUtil.formatMonthCn(prevMonth))
      }
      2 -> PeriodResolver.resolve(PeriodType.YEAR, now, weekStart)
      3 -> PeriodResolver.resolve(PeriodType.ALL, now, weekStart)
      4 -> {
        val pair = custom ?: (DateUtil.nowDayKey() to DateUtil.nowDayKey())
        PeriodResolver.custom(pair.first, pair.second)
      }
      else -> PeriodResolver.resolve(PeriodType.MONTH, now, weekStart)
    }
  }

  fun setSegment(index: Int) {
    segment.value = index
  }

  fun setPeriod(index: Int) {
    periodIndex.value = index
  }

  fun setCustomRange(startDayKey: String, endDayKey: String) {
    val start = DateUtil.parseDayKey(startDayKey).toEpochDay()
    val end = DateUtil.parseDayKey(endDayKey).toEpochDay()
    val pair =
      if (start <= end) {
        startDayKey to endDayKey
      } else {
        endDayKey to startDayKey
      }
    customRange.value = pair
    periodIndex.value = 4
    calendarMonth.value = startDayKey.substring(0, 7)
  }

  fun changeCalendarMonth(delta: Int) {
    calendarMonth.value = DateUtil.addMonths(calendarMonth.value, delta)
  }

  fun calendarMonthValue(): String = calendarMonth.value

  fun todayLocalDate(): LocalDate = DateUtil.today()
}
