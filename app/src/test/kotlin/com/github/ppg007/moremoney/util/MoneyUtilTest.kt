package com.github.ppg007.moremoney.util

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class MoneyUtilTest {
  @Test
  fun formatsCentsWithSymbolAndGrouping() {
    assertEquals("¥1,286.40", MoneyUtil.formatCents(128640))
    assertEquals("1,286.40", MoneyUtil.formatCents(128640, symbol = false))
    assertEquals("¥0.00", MoneyUtil.formatCents(0))
    assertEquals("−¥12.00", MoneyUtil.formatCents(-1200))
  }

  @Test
  fun formatsYuanWithoutSymbol() {
    assertEquals("12.30", MoneyUtil.formatYuan(1230))
    assertEquals("0.05", MoneyUtil.formatYuan(5))
  }

  @Test
  fun parsesYuanTextToCents() {
    assertEquals(1230L, MoneyUtil.parseYuanToCents("12.3"))
    assertEquals(500L, MoneyUtil.parseYuanToCents(".5"))
    assertEquals(1200L, MoneyUtil.parseYuanToCents("12"))
    assertNull(MoneyUtil.parseYuanToCents("12.345"))
    assertNull(MoneyUtil.parseYuanToCents("-1"))
    assertNull(MoneyUtil.parseYuanToCents("abc"))
    assertNull(MoneyUtil.parseYuanToCents(""))
    assertNull(MoneyUtil.parseYuanToCents("1.2.3"))
  }

  @Test
  fun roundsHalfUp() {
    assertEquals(2L, MoneyUtil.roundHalfUp(1.5))
    assertEquals(1L, MoneyUtil.roundHalfUp(1.49))
    assertEquals(-2L, MoneyUtil.roundHalfUp(-1.5))
    assertEquals(-1L, MoneyUtil.roundHalfUp(-1.49))
  }
}
