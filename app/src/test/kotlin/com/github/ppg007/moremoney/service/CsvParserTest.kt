package com.github.ppg007.moremoney.service

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class CsvParserTest {
  @Test
  fun parsesSimpleRows() {
    val rows = CsvParser.parse("a,b\nc,d\n")
    assertEquals(2, rows.size)
    assertEquals("a|b", rows[0].cells.joinToString("|"))
    assertEquals("c|d", rows[1].cells.joinToString("|"))
    assertEquals(1, rows[0].lineNumber)
    assertEquals(2, rows[1].lineNumber)
  }

  @Test
  fun parsesQuotedCommasQuotesAndNewlines() {
    val rows = CsvParser.parse("\"a,b\",\"say \"\"hi\"\"\",\"line1\nline2\"\n")
    assertEquals(1, rows.size)
    assertEquals(3, rows[0].cells.size)
    assertEquals("a,b", rows[0].cells[0])
    assertEquals("say \"hi\"", rows[0].cells[1])
    assertEquals("line1\nline2", rows[0].cells[2])
  }

  @Test
  fun parsesCrlfAndSkipsBlankLines() {
    val rows = CsvParser.parse("a,b\r\n\r\nc,d\r\n")
    assertEquals(2, rows.size)
    assertEquals("a|b", rows[0].cells.joinToString("|"))
    assertEquals("c|d", rows[1].cells.joinToString("|"))
  }

  @Test
  fun reportsUnclosedQuote() {
    var failed = false
    var line = 0
    try {
      CsvParser.parse("a,\"b\nc")
    } catch (error: CsvSyntaxError) {
      failed = true
      line = error.line
    }
    assertTrue(failed)
    assertEquals(1, line)
  }

  @Test
  fun reportsTextAfterClosingQuote() {
    var failed = false
    try {
      CsvParser.parse("a,\"b\"x\n")
    } catch (error: CsvSyntaxError) {
      failed = true
    }
    assertTrue(failed)
  }

  @Test
  fun keepsEmptyCells() {
    val rows = CsvParser.parse("a,,c\n")
    assertEquals(1, rows.size)
    assertEquals(3, rows[0].cells.size)
    assertEquals("", rows[0].cells[1])
  }
}
