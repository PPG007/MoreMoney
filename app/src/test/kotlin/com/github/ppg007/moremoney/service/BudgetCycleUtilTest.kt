package com.github.ppg007.moremoney.service

import com.github.ppg007.moremoney.models.BudgetCycle
import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.LocalDate

class BudgetCycleUtilTest {
  @Test
  fun monthRangeAndDaysLeft() {
    val today = LocalDate.of(2026, 11, 15)
    assertEquals(LocalDate.of(2026, 11, 1), BudgetCycleUtil.startOf(BudgetCycle.MONTH, today))
    assertEquals(LocalDate.of(2026, 11, 30), BudgetCycleUtil.endOf(BudgetCycle.MONTH, today))
    assertEquals(16, BudgetCycleUtil.daysLeft(BudgetCycle.MONTH, today))
  }

  @Test
  fun quarterRangeCoversThreeMonths() {
    val today = LocalDate.of(2026, 8, 15)
    assertEquals(LocalDate.of(2026, 7, 1), BudgetCycleUtil.startOf(BudgetCycle.QUARTER, today))
    assertEquals(LocalDate.of(2026, 9, 30), BudgetCycleUtil.endOf(BudgetCycle.QUARTER, today))
    assertEquals(47, BudgetCycleUtil.daysLeft(BudgetCycle.QUARTER, today))
  }

  @Test
  fun quarterStartsAtCorrectMonth() {
    assertEquals(
      LocalDate.of(2026, 1, 1),
      BudgetCycleUtil.startOf(BudgetCycle.QUARTER, LocalDate.of(2026, 1, 10)),
    )
    assertEquals(
      LocalDate.of(2026, 4, 1),
      BudgetCycleUtil.startOf(BudgetCycle.QUARTER, LocalDate.of(2026, 6, 30)),
    )
    assertEquals(
      LocalDate.of(2026, 7, 1),
      BudgetCycleUtil.startOf(BudgetCycle.QUARTER, LocalDate.of(2026, 7, 1)),
    )
    assertEquals(
      LocalDate.of(2026, 10, 1),
      BudgetCycleUtil.startOf(BudgetCycle.QUARTER, LocalDate.of(2026, 12, 31)),
    )
  }

  @Test
  fun yearRangeAndDaysLeft() {
    val today = LocalDate.of(2026, 8, 15)
    assertEquals(LocalDate.of(2026, 1, 1), BudgetCycleUtil.startOf(BudgetCycle.YEAR, today))
    assertEquals(LocalDate.of(2026, 12, 31), BudgetCycleUtil.endOf(BudgetCycle.YEAR, today))
    assertEquals(139, BudgetCycleUtil.daysLeft(BudgetCycle.YEAR, today))
  }

  @Test
  fun convertsBetweenCycles() {
    assertEquals(100_000L, BudgetCycleUtil.monthlyCents(BudgetCycle.MONTH, 100_000))
    assertEquals(300_000L, BudgetCycleUtil.quarterlyCents(BudgetCycle.MONTH, 100_000))
    assertEquals(1_200_000L, BudgetCycleUtil.yearlyCents(BudgetCycle.MONTH, 100_000))

    assertEquals(100_000L, BudgetCycleUtil.monthlyCents(BudgetCycle.QUARTER, 300_000))
    assertEquals(300_000L, BudgetCycleUtil.quarterlyCents(BudgetCycle.QUARTER, 300_000))
    assertEquals(1_200_000L, BudgetCycleUtil.yearlyCents(BudgetCycle.QUARTER, 300_000))

    assertEquals(100_000L, BudgetCycleUtil.monthlyCents(BudgetCycle.YEAR, 1_200_000))
    assertEquals(300_000L, BudgetCycleUtil.quarterlyCents(BudgetCycle.YEAR, 1_200_000))
    assertEquals(1_200_000L, BudgetCycleUtil.yearlyCents(BudgetCycle.YEAR, 1_200_000))
  }

  @Test
  fun convertsAmountWhenSwitchingCycle() {
    assertEquals(1_200_000L, BudgetCycleUtil.convert(100_000, BudgetCycle.MONTH, BudgetCycle.YEAR))
    assertEquals(300_000L, BudgetCycleUtil.convert(100_000, BudgetCycle.MONTH, BudgetCycle.QUARTER))
    assertEquals(100_000L, BudgetCycleUtil.convert(1_200_000, BudgetCycle.YEAR, BudgetCycle.MONTH))
    assertEquals(300_000L, BudgetCycleUtil.convert(1_200_000, BudgetCycle.YEAR, BudgetCycle.QUARTER))
    assertEquals(1_200_000L, BudgetCycleUtil.convert(300_000, BudgetCycle.QUARTER, BudgetCycle.YEAR))
    assertEquals(100_000L, BudgetCycleUtil.convert(300_000, BudgetCycle.QUARTER, BudgetCycle.MONTH))
  }

  @Test
  fun dividesWithHalfUpRounding() {
    // 100_000 / 12 = 8333.33 → 8333；100_000 / 4 = 25000。
    assertEquals(8_333L, BudgetCycleUtil.monthlyCents(BudgetCycle.YEAR, 100_000))
    assertEquals(25_000L, BudgetCycleUtil.quarterlyCents(BudgetCycle.YEAR, 100_000))
    // 100 / 3 = 33.33 → 33；101 / 3 = 33.67 → 34。
    assertEquals(33L, BudgetCycleUtil.monthlyCents(BudgetCycle.QUARTER, 100))
    assertEquals(34L, BudgetCycleUtil.monthlyCents(BudgetCycle.QUARTER, 101))
  }

  @Test
  fun labelsAreStable() {
    assertEquals("年度预算", BudgetCycleUtil.label(BudgetCycle.YEAR))
    assertEquals("季度预算", BudgetCycleUtil.label(BudgetCycle.QUARTER))
    assertEquals("月度预算", BudgetCycleUtil.label(BudgetCycle.MONTH))
    assertEquals("本年", BudgetCycleUtil.shortLabel(BudgetCycle.YEAR))
    assertEquals("每季度", BudgetCycleUtil.repeatLabel(BudgetCycle.QUARTER))
  }
}
