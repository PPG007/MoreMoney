package com.github.ppg007.moremoney.service

data class CsvRow(
  val cells: List<String> = emptyList(),
  val lineNumber: Int = 0,
)

class CsvSyntaxError(message: String, val line: Int) : Exception(message)

/**
 * RFC 4180 风格 CSV 解析器，支持引号内逗号、双引号与换行；空行跳过。
 *
 * 坏行会抛出带行号的 [CsvSyntaxError]。
 */
object CsvParser {
  fun parse(text: String): List<CsvRow> {
    val rows = ArrayList<CsvRow>()
    var cells = ArrayList<String>()
    var field = StringBuilder()
    var inQuotes = false
    var afterQuote = false
    var line = 1
    var rowStart = 1
    var i = 0

    while (i < text.length) {
      val ch = text[i]
      if (inQuotes) {
        if (ch == '"') {
          val next = if (i + 1 < text.length) text[i + 1] else '\u0000'
          if (next == '"') {
            field.append('"')
            i += 2
          } else {
            inQuotes = false
            afterQuote = true
            i += 1
          }
        } else {
          if (ch == '\n') {
            line += 1
          }
          field.append(ch)
          i += 1
        }
        continue
      }
      if (afterQuote) {
        when {
          ch == ',' -> {
            cells.add(field.toString())
            field = StringBuilder()
            afterQuote = false
            i += 1
          }
          ch == '\r' || ch == '\n' -> {
            cells.add(field.toString())
            field = StringBuilder()
            afterQuote = false
            pushRow(rows, cells, rowStart)
            cells = ArrayList()
            if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') {
              i += 2
            } else {
              i += 1
            }
            line += 1
            rowStart = line
          }
          else -> throw CsvSyntaxError("引号后出现非法字符", line)
        }
        continue
      }
      when {
        ch == '"' && field.isEmpty() -> {
          inQuotes = true
          i += 1
        }
        ch == ',' -> {
          cells.add(field.toString())
          field = StringBuilder()
          i += 1
        }
        ch == '\r' || ch == '\n' -> {
          cells.add(field.toString())
          field = StringBuilder()
          pushRow(rows, cells, rowStart)
          cells = ArrayList()
          if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') {
            i += 2
          } else {
            i += 1
          }
          line += 1
          rowStart = line
        }
        else -> {
          field.append(ch)
          i += 1
        }
      }
    }

    if (inQuotes) {
      throw CsvSyntaxError("引号未闭合", rowStart)
    }
    if (afterQuote || field.isNotEmpty() || cells.isNotEmpty()) {
      cells.add(field.toString())
      pushRow(rows, cells, rowStart)
    }
    return rows
  }

  private fun pushRow(rows: MutableList<CsvRow>, cells: List<String>, lineNumber: Int) {
    if (cells.size == 1 && cells[0].isEmpty()) {
      return
    }
    rows.add(CsvRow(cells = cells.toList(), lineNumber = lineNumber))
  }
}
