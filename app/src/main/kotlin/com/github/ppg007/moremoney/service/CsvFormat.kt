package com.github.ppg007.moremoney.service

import com.github.ppg007.moremoney.util.DateUtil
import java.time.Instant
import java.time.LocalDateTime

/** CSV 导出的一行。 */
data class CsvExportRow(
  var date: String = "",
  var time: String = "",
  var type: String = "expense",
  var book: String = "",
  var group: String = "",
  var category: String = "",
  var amount: String = "",
  var note: String = "",
  var id: String = "",
)

/**
 * CSV 格式：UTF-8 BOM、CRLF、固定 9 列（成员管理已移除）。
 *
 * 旧版 10 列文件（含 member 列）仍可导入，成员列会被忽略。
 */
object CsvFormat {
  const val HEADER = "date,time,type,book,group,category,amount,note,id"

  /** 旧版 Android 导出格式，仅用于导入兼容。 */
  const val LEGACY_HEADER_10 = "date,time,type,book,group,category,member,amount,note,id"
  val BOM: String = String(Character.toChars(0xFEFF))
  const val CRLF = "\r\n"

  fun escape(field: String): String {
    var value = field
    val first = value.firstOrNull()
    if (first == '=' || first == '+' || first == '-' || first == '@') {
      value = "'$value"
    }
    val needsQuote = value.any { it == ',' || it == '"' || it == '\n' || it == '\r' }
    if (needsQuote) {
      return "\"" + value.replace("\"", "\"\"") + "\""
    }
    return value
  }

  fun row(item: CsvExportRow): String {
    val cells =
      listOf(
        item.date,
        item.time,
        item.type,
        item.book,
        item.group,
        item.category,
        item.amount,
        item.note,
        item.id,
      )
    return cells.joinToString(",") { escape(it) }
  }

  fun build(rows: List<CsvExportRow>): String {
    val builder = StringBuilder()
    builder.append(BOM).append(HEADER).append(CRLF)
    for (item in rows) {
      builder.append(row(item)).append(CRLF)
    }
    return builder.toString()
  }

  fun formatAmount(cents: Long): String {
    val abs = kotlin.math.abs(cents)
    val yuan = abs / 100
    val fraction = abs % 100
    return yuan.toString() + "." + fraction.toString().padStart(2, '0')
  }

  fun pad2(value: Int): String = value.toString().padStart(2, '0')

  fun dateText(timestamp: Long): String {
    val date = DateUtil.toLocalDate(timestamp)
    return "${date.year}-${pad2(date.monthValue)}-${pad2(date.dayOfMonth)}"
  }

  fun timeText(timestamp: Long): String {
    val dateTime = DateUtil.toLocalDateTime(timestamp)
    return "${pad2(dateTime.hour)}:${pad2(dateTime.minute)}"
  }

  fun fileName(timestamp: Long): String {
    val dateTime = DateUtil.toLocalDateTime(timestamp)
    return "MoreMoney_${dateTime.year}${pad2(dateTime.monthValue)}${pad2(dateTime.dayOfMonth)}_" +
      "${pad2(dateTime.hour)}${pad2(dateTime.minute)}.csv"
  }

  fun localDateTimeOf(date: String, time: String): LocalDateTime {
    val dateParts = date.split("-")
    val timeParts = time.split(":")
    return LocalDateTime.of(
      dateParts[0].toInt(),
      dateParts[1].toInt(),
      dateParts[2].toInt(),
      timeParts[0].toInt(),
      timeParts[1].toInt(),
    )
  }

  fun epochMilliOf(date: String, time: String): Long =
    localDateTimeOf(date, time).atZone(DateUtil.zone()).toInstant().toEpochMilli()

  fun parseAmountToCents(text: String): Long {
    if (!Regex("^\\d+(\\.\\d{1,2})?$").matches(text)) {
      return -1
    }
    val parts = text.split(".")
    val yuan = parts[0].toLongOrNull() ?: return -1
    val cents = if (parts.size > 1) parts[1].padEnd(2, '0').toLong() else 0L
    return yuan * 100 + cents
  }

  fun unescapeNote(note: String): String {
    if (note.length >= 2 && note[0] == '\'' && (note[1] == '=' || note[1] == '+' || note[1] == '-' || note[1] == '@')) {
      return note.substring(1)
    }
    return note
  }

  fun nowEpochMillis(): Long = Instant.now().toEpochMilli()
}
