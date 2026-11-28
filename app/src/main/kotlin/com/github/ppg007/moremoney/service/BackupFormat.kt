package com.github.ppg007.moremoney.service

/** 备份正文的一行：类型 + Tab 分隔的字段。 */
data class BackupLine(
  val type: String = "",
  val cells: List<String> = emptyList(),
)

data class BackupCounts(
  var books: Int = 0,
  var categories: Int = 0,
  var txns: Int = 0,
  var budgets: Int = 0,
  var privateBooks: Int = 0,
)

data class BackupDocument(
  var format: Int = 0,
  var schemaVersion: Int = 0,
  var createdAt: Long = 0,
  var appVersion: String = "",
  var counts: BackupCounts = BackupCounts(),
  var checksum: String = "",
  var body: String = "",
  var lines: List<BackupLine> = emptyList(),
  var rawText: String = "",
)

/**
 * `MOREMONEY_BACKUP` 文件格式（Android 独立版）。
 *
 * - `format=1` 不变；
 * - `schemaVersion=3`：预算改为每个账本一条“周期 + 金额”，BUDGET 行第 3 列写周期；
 * - 仍可读取 schemaVersion=1/2 的旧备份：MEMBER 行忽略，旧 BUDGET 的月份字段按月度预算处理；
 * - Android 不生成 `PRIVATE` 行，但解析时保留该类型以便识别并跳过。
 */
object BackupFormat {
  const val MAGIC = "MOREMONEY_BACKUP"
  const val FORMAT_VERSION = 1
  const val SCHEMA_VERSION = 3
  const val LEGACY_SCHEMA_VERSION = 1

  fun buildBody(lines: List<BackupLine>): String =
    lines.joinToString("\n") { line -> line.type + "\t" + line.cells.joinToString("\t") }

  fun wrap(body: String, checksum: String, counts: BackupCounts, createdAt: Long, appVersion: String): String {
    val header =
      listOf(
        MAGIC,
        "format=$FORMAT_VERSION",
        "schemaVersion=$SCHEMA_VERSION",
        "createdAt=$createdAt",
        "appVersion=$appVersion",
        "books=${counts.books}",
        "categories=${counts.categories}",
        "txns=${counts.txns}",
        "budgets=${counts.budgets}",
        "privateBooks=${counts.privateBooks}",
        "checksum=$checksum",
      )
    return header.joinToString("\n") + "\n[BODY]\n" + body + "\n[END]\n"
  }

  fun parse(text: String): BackupDocument {
    val doc = BackupDocument(rawText = text)
    val lines = text.split("\n")
    if (lines.isEmpty() || lines[0].trim() != MAGIC) {
      throw IllegalArgumentException("不是有效的 MoreMoney 备份文件")
    }
    var bodyStart = -1
    for (i in 1 until lines.size) {
      val line = lines[i].trim()
      if (line == "[BODY]") {
        bodyStart = i + 1
        break
      }
      applyHeader(doc, line)
    }
    if (bodyStart < 0) {
      throw IllegalArgumentException("备份文件缺少数据段")
    }
    var bodyEnd = -1
    for (i in bodyStart until lines.size) {
      if (lines[i].trim() == "[END]") {
        bodyEnd = i
        break
      }
    }
    if (bodyEnd < 0) {
      throw IllegalArgumentException("备份文件缺少结束标记")
    }
    if (doc.format != FORMAT_VERSION) {
      throw IllegalArgumentException("不支持的备份格式版本")
    }
    if (doc.schemaVersion !in LEGACY_SCHEMA_VERSION..SCHEMA_VERSION) {
      throw IllegalArgumentException("备份数据版本不兼容，请升级应用")
    }
    if (doc.checksum.isEmpty()) {
      throw IllegalArgumentException("备份文件缺少校验和")
    }
    doc.body = lines.subList(bodyStart, bodyEnd).joinToString("\n")
    doc.lines = parseBody(doc.body)
    return doc
  }

  fun parseBody(body: String): List<BackupLine> {
    if (body.isEmpty()) {
      return emptyList()
    }
    val result = ArrayList<BackupLine>()
    for (raw in body.split("\n")) {
      if (raw.isEmpty()) {
        continue
      }
      val cells = raw.split("\t")
      result.add(BackupLine(type = cells[0], cells = cells.drop(1)))
    }
    return result
  }

  fun isKnownType(type: String): Boolean =
    type == "BOOK" || type == "MEMBER" || type == "GROUP" || type == "CATEGORY" ||
      type == "TXN" || type == "BUDGET" || type == "PRIVATE"

  private fun applyHeader(doc: BackupDocument, line: String) {
    if (line.isEmpty()) {
      return
    }
    val index = line.indexOf('=')
    if (index < 0) {
      return
    }
    val key = line.substring(0, index)
    val value = line.substring(index + 1)
    when (key) {
      "format" -> doc.format = value.trim().toIntOrNull() ?: 0
      "schemaVersion" -> doc.schemaVersion = value.trim().toIntOrNull() ?: 0
      "createdAt" -> doc.createdAt = value.trim().toLongOrNull() ?: 0
      "appVersion" -> doc.appVersion = value
      "books" -> doc.counts.books = value.trim().toIntOrNull() ?: 0
      "categories" -> doc.counts.categories = value.trim().toIntOrNull() ?: 0
      "txns" -> doc.counts.txns = value.trim().toIntOrNull() ?: 0
      "budgets" -> doc.counts.budgets = value.trim().toIntOrNull() ?: 0
      "privateBooks" -> doc.counts.privateBooks = value.trim().toIntOrNull() ?: 0
      "checksum" -> doc.checksum = value.trim()
    }
  }
}
