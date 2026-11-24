package com.github.ppg007.moremoney.service

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDateTime

class CsvFormatTest {
  @Test
  fun escapesCommasQuotesAndNewlines() {
    assertEquals("\"午餐,饮料\"", CsvFormat.escape("午餐,饮料"))
    assertEquals("\"说\"\"你好\"\"\"", CsvFormat.escape("说\"你好\""))
    assertEquals("\"第一行\n第二行\"", CsvFormat.escape("第一行\n第二行"))
    assertEquals("普通备注", CsvFormat.escape("普通备注"))
  }

  @Test
  fun escapesFormulaInjection() {
    assertEquals("'=SUM(A1)", CsvFormat.escape("=SUM(A1)"))
    assertEquals("'+1", CsvFormat.escape("+1"))
    assertEquals("'-1", CsvFormat.escape("-1"))
    assertEquals("'@cmd", CsvFormat.escape("@cmd"))
  }

  @Test
  fun formatsAmountsAndDates() {
    assertEquals("32.00", CsvFormat.formatAmount(3200))
    assertEquals("0.05", CsvFormat.formatAmount(5))
    val time =
      LocalDateTime.of(2026, 11, 9, 12, 30)
        .atZone(java.time.ZoneId.systemDefault())
        .toInstant()
        .toEpochMilli()
    assertEquals("2026-11-09", CsvFormat.dateText(time))
    assertEquals("12:30", CsvFormat.timeText(time))
  }

  @Test
  fun buildsHeaderWithBomAndCrlf() {
    val row =
      CsvExportRow(
        date = "2026-11-09",
        time = "12:30",
        type = "expense",
        book = "日常账本",
        group = "餐饮",
        category = "餐饮",
        amount = "32.00",
        note = "午餐",
        id = "txn_1",
      )
    val text = CsvFormat.build(listOf(row))
    assertTrue(text.startsWith("﻿date,time,type,book,group,category,amount,note,id\r\n"))
    assertTrue(text.endsWith("\r\n"))
    assertTrue(text.contains("2026-11-09,12:30,expense,日常账本,餐饮,餐饮,32.00,午餐,txn_1"))
  }
}
