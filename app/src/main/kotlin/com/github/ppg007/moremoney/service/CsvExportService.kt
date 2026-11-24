package com.github.ppg007.moremoney.service

import com.github.ppg007.moremoney.data.db.entity.CategoryEntity
import com.github.ppg007.moremoney.data.repository.BookRepository
import com.github.ppg007.moremoney.data.repository.CategoryRepository
import com.github.ppg007.moremoney.data.repository.TxnRepository
import com.github.ppg007.moremoney.models.TxnFilter

/**
 * CSV 导出：查询 → [CsvExportRow] → [CsvFormat.build]。
 *
 * 文件写入由 UI 通过 SAF `CreateDocument` 完成；取消保存返回 -1，不视为错误。
 * 固定 9 列、UTF-8 BOM、CRLF、两位小数金额。
 */
class CsvExportService(
  private val bookRepository: BookRepository,
  private val categoryRepository: CategoryRepository,
  private val txnRepository: TxnRepository,
) {
  private data class NameMaps(
    val books: Map<String, String>,
    val groups: Map<String, String>,
    val categories: Map<String, CategoryEntity>,
  )

  private suspend fun loadNames(): NameMaps {
    val books = bookRepository.list().associate { it.id to it.name }
    val groups = categoryRepository.listGroups().associate { it.id to it.name }
    val categories = categoryRepository.list().associateBy { it.id }
    return NameMaps(books, groups, categories)
  }

  suspend fun prepareRows(filter: TxnFilter, excludeBookIds: List<String> = emptyList()): List<CsvExportRow> {
    val maps = loadNames()
    val txns = txnRepository.listActive()
      .filter { excludeBookIds.none { excluded -> excluded == it.bookId } }
      .filter { filter.bookIds.isEmpty() || it.bookId in filter.bookIds }
      .filter { filter.startMs <= 0 || it.occurredAt >= filter.startMs }
      .filter { filter.endMs <= 0 || it.occurredAt <= filter.endMs }
      .sortedBy { it.occurredAt }

    return txns.map { txn ->
      val category = maps.categories[txn.categoryId]
      CsvExportRow(
        date = CsvFormat.dateText(txn.occurredAt),
        time = CsvFormat.timeText(txn.occurredAt),
        type = "expense",
        book = maps.books[txn.bookId].orEmpty(),
        group = category?.let { maps.groups[it.groupId] }.orEmpty(),
        category = category?.name.orEmpty(),
        amount = CsvFormat.formatAmount(txn.amountCents),
        note = txn.note,
        id = txn.id,
      )
    }
  }

  suspend fun buildText(filter: TxnFilter, excludeBookIds: List<String> = emptyList()): String =
    CsvFormat.build(prepareRows(filter, excludeBookIds))

  suspend fun estimate(filter: TxnFilter, excludeBookIds: List<String> = emptyList()): Int =
    prepareRows(filter, excludeBookIds).size
}
