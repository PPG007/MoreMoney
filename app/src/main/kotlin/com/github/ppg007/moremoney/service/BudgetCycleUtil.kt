package com.github.ppg007.moremoney.service

import com.github.ppg007.moremoney.models.BudgetCycle
import com.github.ppg007.moremoney.util.DateRange
import com.github.ppg007.moremoney.util.DateUtil
import java.time.LocalDate
import java.time.LocalTime
import java.time.temporal.ChronoUnit

/**
 * 预算周期计算与金额折算。
 *
 * 一个账本只保存一个“周期 + 金额”，其他周期由这里自动折算：
 * 年度 = 月度 × 12，季度 = 月度 × 3；反向折算按整数分四舍五入。
 */
object BudgetCycleUtil {
  fun startOf(cycle: BudgetCycle, today: LocalDate = DateUtil.today()): LocalDate =
    when (cycle) {
      BudgetCycle.YEAR -> today.withDayOfYear(1)
      BudgetCycle.QUARTER -> {
        val firstMonth = ((today.monthValue - 1) / 3) * 3 + 1
        LocalDate.of(today.year, firstMonth, 1)
      }
      BudgetCycle.MONTH -> today.withDayOfMonth(1)
    }

  fun endOf(cycle: BudgetCycle, today: LocalDate = DateUtil.today()): LocalDate =
    when (cycle) {
      BudgetCycle.YEAR -> startOf(cycle, today).plusYears(1).minusDays(1)
      BudgetCycle.QUARTER -> startOf(cycle, today).plusMonths(3).minusDays(1)
      BudgetCycle.MONTH -> startOf(cycle, today).plusMonths(1).minusDays(1)
    }

  fun range(cycle: BudgetCycle, today: LocalDate = DateUtil.today()): DateRange {
    val zone = DateUtil.zone()
    val start = startOf(cycle, today)
    val end = endOf(cycle, today)
    return DateRange(
      startMs = start.atStartOfDay(zone).toInstant().toEpochMilli(),
      endMs = end.atTime(LocalTime.of(23, 59, 59, 999_000_000)).atZone(zone).toInstant().toEpochMilli(),
    )
  }

  /** 当前周期剩余天数（含今天），至少 1。 */
  fun daysLeft(cycle: BudgetCycle, today: LocalDate = DateUtil.today()): Int =
    (ChronoUnit.DAYS.between(today, endOf(cycle, today)).toInt() + 1).coerceAtLeast(1)

  fun monthlyCents(cycle: BudgetCycle, amountCents: Long): Long =
    when (cycle) {
      BudgetCycle.MONTH -> amountCents
      BudgetCycle.QUARTER -> divideRoundHalfUp(amountCents, 3)
      BudgetCycle.YEAR -> divideRoundHalfUp(amountCents, 12)
    }

  fun quarterlyCents(cycle: BudgetCycle, amountCents: Long): Long =
    when (cycle) {
      BudgetCycle.MONTH -> amountCents * 3
      BudgetCycle.QUARTER -> amountCents
      BudgetCycle.YEAR -> divideRoundHalfUp(amountCents, 4)
    }

  fun yearlyCents(cycle: BudgetCycle, amountCents: Long): Long =
    when (cycle) {
      BudgetCycle.MONTH -> amountCents * 12
      BudgetCycle.QUARTER -> amountCents * 4
      BudgetCycle.YEAR -> amountCents
    }

  /** 把某周期的金额换算为目标周期的等价金额。 */
  fun convert(amountCents: Long, from: BudgetCycle, to: BudgetCycle): Long =
    when (to) {
      BudgetCycle.MONTH -> monthlyCents(from, amountCents)
      BudgetCycle.QUARTER -> quarterlyCents(from, amountCents)
      BudgetCycle.YEAR -> yearlyCents(from, amountCents)
    }

  fun label(cycle: BudgetCycle): String =
    when (cycle) {
      BudgetCycle.YEAR -> "年度预算"
      BudgetCycle.QUARTER -> "季度预算"
      BudgetCycle.MONTH -> "月度预算"
    }

  fun shortLabel(cycle: BudgetCycle): String =
    when (cycle) {
      BudgetCycle.YEAR -> "本年"
      BudgetCycle.QUARTER -> "本季"
      BudgetCycle.MONTH -> "本月"
    }

  fun repeatLabel(cycle: BudgetCycle): String =
    when (cycle) {
      BudgetCycle.YEAR -> "每年"
      BudgetCycle.QUARTER -> "每季度"
      BudgetCycle.MONTH -> "每月"
    }

  private fun divideRoundHalfUp(value: Long, divisor: Long): Long =
    (value + divisor / 2) / divisor
}
