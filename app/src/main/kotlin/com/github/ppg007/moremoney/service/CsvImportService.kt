package com.github.ppg007.moremoney.service

import androidx.room.withTransaction
import com.github.ppg007.moremoney.data.db.MoreMoneyDatabase
import com.github.ppg007.moremoney.data.db.entity.BookEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryGroupEntity
import com.github.ppg007.moremoney.data.db.entity.TxnEntity
import com.github.ppg007.moremoney.data.repository.BookRepository
import com.github.ppg007.moremoney.data.repository.CategoryRepository
import com.github.ppg007.moremoney.data.repository.TxnRepository
import com.github.ppg007.moremoney.ui.theme.SeedColors
import com.github.ppg007.moremoney.util.DateUtil
import com.github.ppg007.moremoney.util.IdUtil
import com.github.ppg007.moremoney.util.PinyinUtil

data class ImportError(val line: Int, val message: String)

data class ImportPreview(
  val total: Int = 0,
  val toInsert: Int = 0,
  val duplicates: Int = 0,
  val newBooks: List<String> = emptyList(),
  val newCategories: List<String> = emptyList(),
  val errors: List<ImportError> = emptyList(),
  val rows: List<TxnEntity> = emptyList(),
  val bookNames: List<String> = emptyList(),
  val groupNames: List<String> = emptyList(),
  val categoryNames: List<String> = emptyList(),
) {
  val hasErrors: Boolean get() = errors.isNotEmpty()
}

data class ImportResult(val inserted: Int = 0, val skipped: Int = 0)

/**
 * CSV 导入：
 * - 表头必须与模板一致；同时兼容旧版 10 列（含 member 列），成员列直接忽略；
 * - 逐行校验，坏行带行号；有错误时禁止导入；
 * - 同文件重复 ID 保留第一条，库中已存在 ID 跳过；
 * - 自动创建账本/分组/分类；
 * - 全部写入包裹在一个事务里，失败整体回滚。
 */
class CsvImportService(
  private val db: MoreMoneyDatabase,
  private val bookRepository: BookRepository,
  private val categoryRepository: CategoryRepository,
  private val txnRepository: TxnRepository,
) {
  companion object {
    const val MAX_BYTES = 5 * 1024 * 1024
    const val MAX_ROWS = 20000
    const val MAX_AMOUNT_CENTS = 9_999_999_999L
  }

  private data class ExistingMaps(
    val books: MutableMap<String, String>,
    val groups: MutableMap<String, String>,
    val categories: MutableMap<String, String>,
    val txnIds: MutableSet<String>,
  )

  private suspend fun loadMaps(): ExistingMaps {
    val books = LinkedHashMap<String, String>()
    for (book in bookRepository.list()) {
      books[book.name] = book.id
    }
    val groups = LinkedHashMap<String, String>()
    val categories = LinkedHashMap<String, String>()
    for (group in categoryRepository.listGroups()) {
      groups[group.name] = group.id
      for (category in categoryRepository.listByGroup(group.id)) {
        categories.putIfAbsent(category.name, category.id)
      }
    }
    val txnIds = txnRepository.allIds().toMutableSet()
    return ExistingMaps(books, groups, categories, txnIds)
  }

  suspend fun preview(text: String): ImportPreview {
    if (text.toByteArray(Charsets.UTF_8).size > MAX_BYTES) {
      return ImportPreview(errors = listOf(ImportError(0, "文件超过 5MB 上限")))
    }
    val clean = text.removePrefix(CsvFormat.BOM)
    val parsed =
      try {
        CsvParser.parse(clean)
      } catch (error: CsvSyntaxError) {
        return ImportPreview(errors = listOf(ImportError(error.line, error.message ?: "文件解析失败")))
      } catch (error: Exception) {
        return ImportPreview(errors = listOf(ImportError(0, "文件解析失败")))
      }
    if (parsed.isEmpty()) {
      return ImportPreview(errors = listOf(ImportError(0, "文件为空")))
    }
    val header = parsed[0].cells.joinToString(",")
    val legacy = header == CsvFormat.LEGACY_HEADER_10
    if (header != CsvFormat.HEADER && !legacy) {
      return ImportPreview(errors = listOf(ImportError(parsed[0].lineNumber, "表头与模板不一致")))
    }
    if (parsed.size - 1 > MAX_ROWS) {
      return ImportPreview(errors = listOf(ImportError(0, "超过 20000 行上限")))
    }
    // 旧版 10 列：date,time,type,book,group,category,member,amount,note,id
    // 新版 9 列：去掉 member，其余顺序不变。
    val requiredCells = if (legacy) 10 else 9
    val amountIndex = if (legacy) 7 else 6
    val noteIndex = if (legacy) 8 else 7
    val idIndex = if (legacy) 9 else 8

    val maps = loadMaps()
    val newBooks = ArrayList<String>()
    val newCategories = ArrayList<String>()
    val rows = ArrayList<TxnEntity>()
    val bookNames = ArrayList<String>()
    val groupNames = ArrayList<String>()
    val categoryNames = ArrayList<String>()
    val errors = ArrayList<ImportError>()
    var duplicates = 0
    var total = 0

    for (index in 1 until parsed.size) {
      val row = parsed[index]
      total += 1
      if (row.cells.size < requiredCells) {
        errors.add(ImportError(row.lineNumber, "字段数量不足"))
        continue
      }
      val date = row.cells[0].trim()
      val time = row.cells[1].trim()
      val type = row.cells[2].trim()
      val bookName = row.cells[3].trim()
      val groupName = row.cells[4].trim()
      val categoryName = row.cells[5].trim()
      val amountText = row.cells[amountIndex].trim()
      val note = CsvFormat.unescapeNote(row.cells[noteIndex])
      val rawId = row.cells[idIndex].trim()

      var message = ""
      if (!validDate(date)) {
        message = "日期格式不正确"
      } else if (!validTime(time)) {
        message = "时间格式不正确"
      } else if (type != "expense") {
        message = "type 必须为 expense"
      } else if (bookName.isEmpty()) {
        message = "账本不能为空"
      } else if (groupName.isEmpty()) {
        message = "分组不能为空"
      } else if (categoryName.isEmpty()) {
        message = "分类不能为空"
      } else if (note.length > 100) {
        message = "备注超过 100 字"
      }
      val amountCents = CsvFormat.parseAmountToCents(amountText)
      if (message.isEmpty() && amountCents < 0) {
        message = "金额格式不正确"
      }
      if (message.isEmpty() && amountCents <= 0) {
        message = "金额需大于 0"
      }
      if (message.isEmpty() && amountCents > MAX_AMOUNT_CENTS) {
        message = "金额超出上限"
      }
      if (message.isNotEmpty()) {
        errors.add(ImportError(row.lineNumber, message))
        continue
      }

      var id = rawId
      if (id.isEmpty()) {
        id = IdUtil.next()
      } else if (maps.txnIds.contains(id)) {
        duplicates += 1
        continue
      }
      maps.txnIds.add(id)

      if (!maps.books.containsKey(bookName) && bookName !in newBooks) {
        newBooks.add(bookName)
      }
      if (!maps.categories.containsKey(categoryName) && categoryName !in newCategories) {
        newCategories.add(categoryName)
      }

      val now = System.currentTimeMillis()
      rows.add(
        TxnEntity(
          id = id,
          bookId = maps.books[bookName].orEmpty(),
          categoryId = maps.categories[categoryName].orEmpty(),
          amountCents = amountCents,
          occurredAt = CsvFormat.epochMilliOf(date, time),
          dayKey = date,
          note = note,
          createdAt = now,
          updatedAt = now,
        )
      )
      bookNames.add(bookName)
      groupNames.add(groupName)
      categoryNames.add(categoryName)
    }

    return ImportPreview(
      total = total,
      toInsert = rows.size,
      duplicates = duplicates,
      newBooks = newBooks,
      newCategories = newCategories,
      errors = errors,
      rows = rows,
      bookNames = bookNames,
      groupNames = groupNames,
      categoryNames = categoryNames,
    )
  }

  suspend fun execute(preview: ImportPreview): ImportResult {
    if (preview.hasErrors) {
      throw IllegalStateException("存在校验错误，未写入任何数据")
    }
    var inserted = 0
    db.withTransaction {
      val maps = loadMaps()
      val now = System.currentTimeMillis()
      var bookSort = maps.books.size
      var groupSort = maps.groups.size
      var colorIndex = maps.books.size

      for (name in preview.newBooks) {
        val id = "book_${IdUtil.next()}"
        bookRepository.save(
          BookEntity(
            id = id, name = name, icon = "ic_book_daily", color = SeedColors.c1,
            isDefault = false, sort = bookSort, archived = false, createdAt = now, updatedAt = now,
          )
        )
        maps.books[name] = id
        bookSort += 1
      }

      for (name in preview.groupNames) {
        if (!maps.groups.containsKey(name)) {
          val id = "group_${IdUtil.next()}"
          categoryRepository.insertGroup(
            CategoryGroupEntity(id = id, name = name, sort = groupSort, isSystem = false)
          )
          maps.groups[name] = id
          groupSort += 1
        }
      }

      preview.newCategories.forEachIndexed { index, name ->
        val groupName = preview.categoryNames.zip(preview.groupNames)
          .firstOrNull { it.first == name }?.second ?: "其他"
        var groupId = maps.groups[groupName]
        if (groupId == null) {
          val id = "group_${IdUtil.next()}"
          categoryRepository.insertGroup(
            CategoryGroupEntity(id = id, name = groupName, sort = groupSort, isSystem = false)
          )
          maps.groups[groupName] = id
          groupId = id
          groupSort += 1
        }
        val id = "cat_${IdUtil.next()}"
        categoryRepository.save(
          CategoryEntity(
            id = id,
            groupId = groupId,
            name = name,
            icon = "ic_cat_other",
            color = SeedColors.at(colorIndex),
            pinyin = PinyinUtil.key(name),
            sort = index,
            archived = false,
            createdAt = now,
          )
        )
        maps.categories[name] = id
        colorIndex += 1
      }

      for (index in preview.rows.indices) {
        val row = preview.rows[index]
        val bookId = maps.books[preview.bookNames[index]]
        val categoryId = maps.categories[preview.categoryNames[index]]
        if (bookId == null || categoryId == null) {
          throw IllegalStateException("自动创建实体失败")
        }
        txnRepository.insert(row.copy(bookId = bookId, categoryId = categoryId))
        inserted += 1
      }
    }
    return ImportResult(inserted = inserted, skipped = preview.duplicates)
  }

  private fun validDate(text: String): Boolean {
    if (!Regex("^\\d{4}-\\d{2}-\\d{2}$").matches(text)) {
      return false
    }
    val parts = text.split("-")
    val year = parts[0].toIntOrNull() ?: return false
    val month = parts[1].toIntOrNull() ?: return false
    val day = parts[2].toIntOrNull() ?: return false
    if (month !in 1..12 || day < 1) {
      return false
    }
    return day <= DateUtil.daysInMonth(year, month)
  }

  private fun validTime(text: String): Boolean {
    if (!Regex("^\\d{2}:\\d{2}$").matches(text)) {
      return false
    }
    val parts = text.split(":")
    val hour = parts[0].toIntOrNull() ?: return false
    val minute = parts[1].toIntOrNull() ?: return false
    return hour in 0..23 && minute in 0..59
  }
}
