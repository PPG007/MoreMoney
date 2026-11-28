package com.github.ppg007.moremoney.service

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class BackupFormatTest {
  private fun sampleLine(): BackupLine =
    BackupLine(
      type = "BOOK",
      cells = listOf(
        "aWQ=", "5pel5bi46LSm5pys", "aWNfYm9va19kYWlseQ==", "IzJBNzhENg==",
        "0", "", "", "10000", "1", "0", "0", "1", "2",
      ),
    )

  @Test
  fun buildsBodyTextInOrder() {
    val body = BackupFormat.buildBody(listOf(sampleLine()))
    assertTrue(body.startsWith("BOOK\taWQ=\t5pel5bi46LSm5pys"))
    assertTrue(body.contains("\t10000\t1\t0\t0\t1\t2"))
  }

  @Test
  fun wrapsAndParsesDocument() {
    val counts = BackupCounts(books = 3, categories = 9, txns = 128, budgets = 2, privateBooks = 1)
    val body = BackupFormat.buildBody(listOf(sampleLine()))
    val text = BackupFormat.wrap(body, "abcdef", counts, 1762656000000, "1.0.0")
    val doc = BackupFormat.parse(text)
    assertEquals(1, doc.format)
    assertEquals(3, doc.schemaVersion)
    assertFalse(text.contains("members="))
    assertEquals(1762656000000L, doc.createdAt)
    assertEquals("1.0.0", doc.appVersion)
    assertEquals(3, doc.counts.books)
    assertEquals(128, doc.counts.txns)
    assertEquals("abcdef", doc.checksum)
    assertEquals(body, doc.body)
    assertEquals(1, doc.lines.size)
    assertEquals("BOOK", doc.lines[0].type)
    // BOOK 行为 13 列：id、名称、图标、颜色、私密标志与密码占位 +
    // 默认、排序、归档、创建时间、更新时间。
    assertEquals(13, doc.lines[0].cells.size)
  }

  @Test
  fun keepsMultilineBodyIdentical() {
    val body =
      "TXN\tYQ==\tYg==\tc3RhcnQ=\nMEMBER\tYw==\tZA==\teQ==\teg==\t0\t0\t0"
    val text = BackupFormat.wrap(body, "x", BackupCounts(), 0, "1.0.0")
    val doc = BackupFormat.parse(text)
    assertEquals(body, doc.body)
    assertEquals(2, doc.lines.size)
  }

  @Test
  fun rejectsInvalidMagic() {
    var failed = false
    try {
      BackupFormat.parse("NOT_A_BACKUP\n")
    } catch (error: IllegalArgumentException) {
      failed = true
    }
    assertTrue(failed)
  }

  @Test
  fun acceptsLegacySchemaVersionOne() {
    val text =
      BackupFormat.wrap("TXN\ta", "x", BackupCounts(), 0, "1.0.0")
        .replace("schemaVersion=3", "schemaVersion=1")
    val doc = BackupFormat.parse(text)
    assertEquals(1, doc.schemaVersion)
  }

  @Test
  fun acceptsSchemaVersionTwo() {
    val text =
      BackupFormat.wrap("BUDGET\ta\tb\t2026-11\t100\t1", "x", BackupCounts(), 0, "1.0.0")
        .replace("schemaVersion=3", "schemaVersion=2")
    val doc = BackupFormat.parse(text)
    assertEquals(2, doc.schemaVersion)
  }

  @Test
  fun rejectsUnsupportedSchemaVersion() {
    val text =
      BackupFormat.wrap("body", "x", BackupCounts(), 0, "1.0.0")
        .replace("schemaVersion=3", "schemaVersion=9")
    var failed = false
    try {
      BackupFormat.parse(text)
    } catch (error: IllegalArgumentException) {
      failed = true
    }
    assertTrue(failed)
  }

  @Test
  fun rejectsMissingBodyMarker() {
    var failed = false
    try {
      BackupFormat.parse("MOREMONEY_BACKUP\nformat=1\n")
    } catch (error: IllegalArgumentException) {
      failed = true
    }
    assertTrue(failed)
  }

  @Test
  fun ignoresUnknownLineTypesOnParse() {
    val body = "UNKNOWN\ta\nBOOK\tb"
    val doc = BackupFormat.parse(BackupFormat.wrap(body, "x", BackupCounts(), 0, "1.0.0"))
    assertEquals(2, doc.lines.size)
    assertFalse(BackupFormat.isKnownType(doc.lines[0].type))
  }
}
