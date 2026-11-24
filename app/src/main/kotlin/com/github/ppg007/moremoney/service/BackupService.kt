package com.github.ppg007.moremoney.service

import androidx.room.withTransaction
import com.github.ppg007.moremoney.BuildConfig
import com.github.ppg007.moremoney.data.db.MoreMoneyDatabase
import com.github.ppg007.moremoney.data.db.entity.BookEntity
import com.github.ppg007.moremoney.data.db.entity.BudgetEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryGroupEntity
import com.github.ppg007.moremoney.data.db.entity.TxnEntity
import com.github.ppg007.moremoney.data.repository.BookRepository
import com.github.ppg007.moremoney.data.repository.BudgetRepository
import com.github.ppg007.moremoney.data.repository.CategoryRepository
import com.github.ppg007.moremoney.data.repository.TxnRepository
import com.github.ppg007.moremoney.state.SettingsService
import java.security.MessageDigest
import java.util.Base64

/** 导出结果；文件写入由 UI 通过 SAF 完成。 */
data class BackupExport(
  val text: String,
  val createdAt: Long,
  val fileName: String,
  val txns: Int,
)

/** 恢复预览：计数仅作展示，校验以版本与 SHA-256 为准。 */
data class RestoreSummary(
  val createdAt: Long = 0,
  val books: Int = 0,
  val categories: Int = 0,
  val txns: Int = 0,
  val budgets: Int = 0,
  val skippedPrivateBooks: Int = 0,
  val skippedPrivateRows: Int = 0,
) {
  val hasSkippedPrivate: Boolean get() = skippedPrivateBooks > 0 || skippedPrivateRows > 0
}

data class RestoreResult(
  val insertedTxns: Int = 0,
  val skippedPrivateBooks: Int = 0,
  val skippedPrivateRows: Int = 0,
)

/**
 * `MOREMONEY_BACKUP` 导出/恢复（Android 独立版，schemaVersion=2）。
 *
 * - 导出：所有字符串字段 Base64(UTF-8)，数字十进制；不再生成 `MEMBER` 行，
 *   `TXN` 行 9 列；`BOOK` 行保持 13 列布局；不生成 `PRIVATE` 段。
 * - 恢复：兼容 schemaVersion=1：忽略 `MEMBER` 行与 TXN 的 member 列；
 *   跳过 `is_private=1` 的账本、`PRIVATE` 行及其引用的流水/预算；
 *   清空 5 张业务表（保留 `app_meta`），事务失败整体回滚。
 * - 校验：`checksum = SHA-256([BODY] 与 [END] 之间的文本, UTF-8)`，小写 hex。
 */
class BackupService(
  private val db: MoreMoneyDatabase,
  private val bookRepository: BookRepository,
  private val categoryRepository: CategoryRepository,
  private val txnRepository: TxnRepository,
  private val budgetRepository: BudgetRepository,
  private val settings: SettingsService,
) {
  companion object {
    /** 备份头记录的应用版本，跟随构建版本，避免与设置页展示不一致。 */
    val APP_VERSION: String = BuildConfig.VERSION_NAME
    private const val PLACEHOLDER_ITER = "10000"
    const val FILE_SUFFIX = ".mmbk"
  }

  suspend fun buildExport(now: Long = System.currentTimeMillis()): BackupExport {
    val books = bookRepository.list()
    val groups = categoryRepository.listGroups()
    val categories = categoryRepository.list()
    val budgets = budgetRepository.listAll()
    val txns = txnRepository.listActive()

    val lines = ArrayList<BackupLine>()
    for (book in books) {
      lines.add(bookLine(book))
    }
    for (group in groups) {
      lines.add(
        BackupLine(
          type = "GROUP",
          cells = listOf(enc(group.id), enc(group.name), group.sort.toString(), bool(group.isSystem)),
        )
      )
    }
    for (category in categories) {
      lines.add(
        BackupLine(
          type = "CATEGORY",
          cells = listOf(
            enc(category.id), enc(category.groupId), enc(category.name), enc(category.icon),
            enc(category.color), enc(category.pinyin), category.sort.toString(),
            bool(category.archived), category.createdAt.toString(),
          ),
        )
      )
    }
    for (txn in txns) {
      lines.add(
        BackupLine(
          type = "TXN",
          cells = listOf(
            enc(txn.id), enc(txn.bookId), enc(txn.categoryId),
            txn.amountCents.toString(), txn.occurredAt.toString(), enc(txn.dayKey),
            enc(txn.note), txn.createdAt.toString(), txn.updatedAt.toString(),
          ),
        )
      )
    }
    for (budget in budgets) {
      lines.add(
        BackupLine(
          type = "BUDGET",
          cells = listOf(
            enc(budget.id), enc(budget.bookId), enc(budget.period),
            budget.amountCents.toString(), budget.updatedAt.toString(),
          ),
        )
      )
    }

    val body = BackupFormat.buildBody(lines)
    val counts =
      BackupCounts(
        books = books.size,
        categories = categories.size,
        txns = txns.size,
        budgets = budgets.size,
        privateBooks = 0,
      )
    val checksum = sha256(body)
    val text = BackupFormat.wrap(body, checksum, counts, now, APP_VERSION)
    val stamp = csvStamp(now)
    return BackupExport(text = text, createdAt = now, fileName = "MoreMoney_$stamp$FILE_SUFFIX", txns = txns.size)
  }

  fun markExported(export: BackupExport) {
    settings.setLastBackup(export.createdAt, export.fileName)
  }

  fun parseAndVerify(text: String): BackupDocument {
    val doc = BackupFormat.parse(text)
    val actual = sha256(doc.body)
    if (actual != doc.checksum) {
      throw IllegalStateException("备份文件已损坏或被修改")
    }
    return doc
  }

  fun summary(doc: BackupDocument): RestoreSummary {
    var privateBooks = 0
    var privateRows = 0
    for (line in doc.lines) {
      when {
        line.type == "PRIVATE" -> privateRows += 1
        line.type == "BOOK" && line.cells.size >= 13 && line.cells[4] == "1" -> privateBooks += 1
      }
    }
    return RestoreSummary(
      createdAt = doc.createdAt,
      books = doc.counts.books - privateBooks,
      categories = doc.counts.categories,
      txns = doc.counts.txns,
      budgets = doc.counts.budgets,
      skippedPrivateBooks = privateBooks,
      skippedPrivateRows = privateRows,
    )
  }

  suspend fun restore(doc: BackupDocument): RestoreResult {
    val actual = sha256(doc.body)
    if (actual != doc.checksum) {
      throw IllegalStateException("备份文件已损坏或被修改")
    }

    val books = ArrayList<BookEntity>()
    val groups = ArrayList<CategoryGroupEntity>()
    val categories = ArrayList<CategoryEntity>()
    val txns = ArrayList<TxnEntity>()
    val budgets = ArrayList<BudgetEntity>()
    val skippedBookIds = HashSet<String>()
    var skippedPrivateBooks = 0
    var skippedPrivateRows = 0
    val legacy = doc.schemaVersion == BackupFormat.LEGACY_SCHEMA_VERSION
    val minTxnCells = if (legacy) 10 else 9

    for (line in doc.lines) {
      when {
        line.type == "PRIVATE" -> {
          skippedPrivateRows += 1
        }
        line.type == "BOOK" && line.cells.size >= 13 -> {
          if (line.cells[4] == "1") {
            skippedPrivateBooks += 1
            skippedBookIds.add(dec(line.cells[0]))
          } else {
            books.add(readBook(line))
          }
        }
        // 旧备份的 MEMBER 行直接忽略。
        line.type == "MEMBER" -> Unit
        line.type == "GROUP" && line.cells.size >= 4 -> groups.add(readGroup(line))
        line.type == "CATEGORY" && line.cells.size >= 9 -> categories.add(readCategory(line))
        line.type == "TXN" && line.cells.size >= minTxnCells -> {
          val txn = readTxn(line.cells, legacy)
          if (txn.bookId !in skippedBookIds) {
            txns.add(txn)
          }
        }
        line.type == "BUDGET" && line.cells.size >= 5 -> {
          val budget = readBudget(line)
          if (budget.bookId !in skippedBookIds) {
            budgets.add(budget)
          }
        }
        !BackupFormat.isKnownType(line.type) -> Unit
      }
    }

    if (books.isNotEmpty() && books.none { it.isDefault }) {
      val target = books.minByOrNull { it.sort } ?: books.first()
      books.replaceAll { if (it.id == target.id) it.copy(isDefault = true) else it }
    }

    db.withTransaction {
      val txnDao = db.txnDao()
      txnDao.deleteAll()
      db.budgetDao().deleteAll()
      db.categoryDao().deleteAllCategories()
      db.categoryDao().deleteAllGroups()
      db.bookDao().deleteAll()

      for (book in books) {
        db.bookDao().insert(book)
      }
      for (group in groups) {
        db.categoryDao().insertGroup(group)
      }
      for (category in categories) {
        db.categoryDao().insert(category)
      }
      for (txn in txns) {
        db.txnDao().insert(txn.copy(deletedAt = null))
      }
      for (budget in budgets) {
        db.budgetDao().upsert(budget)
      }
    }
    return RestoreResult(
      insertedTxns = txns.size,
      skippedPrivateBooks = skippedPrivateBooks,
      skippedPrivateRows = skippedPrivateRows,
    )
  }

  private fun bookLine(book: BookEntity): BackupLine =
    BackupLine(
      type = "BOOK",
      cells = listOf(
        enc(book.id), enc(book.name), enc(book.icon), enc(book.color),
        "0", "", "", PLACEHOLDER_ITER,
        bool(book.isDefault), book.sort.toString(), bool(book.archived),
        book.createdAt.toString(), book.updatedAt.toString(),
      ),
    )

  private fun readBook(line: BackupLine): BookEntity =
    BookEntity(
      id = dec(line.cells[0]),
      name = dec(line.cells[1]),
      icon = dec(line.cells[2]),
      color = dec(line.cells[3]),
      isDefault = line.cells[8] == "1",
      sort = line.cells[9].toIntOrNull() ?: 0,
      archived = line.cells[10] == "1",
      createdAt = line.cells[11].toLongOrNull() ?: 0,
      updatedAt = line.cells[12].toLongOrNull() ?: 0,
    )

  private fun readGroup(line: BackupLine): CategoryGroupEntity =
    CategoryGroupEntity(
      id = dec(line.cells[0]),
      name = dec(line.cells[1]),
      sort = line.cells[2].toIntOrNull() ?: 0,
      isSystem = line.cells[3] == "1",
    )

  private fun readCategory(line: BackupLine): CategoryEntity =
    CategoryEntity(
      id = dec(line.cells[0]),
      groupId = dec(line.cells[1]),
      name = dec(line.cells[2]),
      icon = dec(line.cells[3]),
      color = dec(line.cells[4]),
      pinyin = dec(line.cells[5]),
      sort = line.cells[6].toIntOrNull() ?: 0,
      archived = line.cells[7] == "1",
      createdAt = line.cells[8].toLongOrNull() ?: 0,
    )

  private fun readTxn(cells: List<String>, legacy: Boolean): TxnEntity {
    // v1 TXN: id, book, category, member, amount, occurredAt, dayKey, note, created, updated
    // v2 TXN: id, book, category, amount, occurredAt, dayKey, note, created, updated
    val offset = if (legacy) 1 else 0
    return TxnEntity(
      id = dec(cells[0]),
      bookId = dec(cells[1]),
      categoryId = dec(cells[2]),
      amountCents = cells[3 + offset].toLongOrNull() ?: 0,
      occurredAt = cells[4 + offset].toLongOrNull() ?: 0,
      dayKey = dec(cells[5 + offset]),
      note = dec(cells[6 + offset]),
      createdAt = cells[7 + offset].toLongOrNull() ?: 0,
      updatedAt = cells[8 + offset].toLongOrNull() ?: 0,
      deletedAt = null,
    )
  }

  private fun readBudget(line: BackupLine): BudgetEntity =
    BudgetEntity(
      id = dec(line.cells[0]),
      bookId = dec(line.cells[1]),
      period = dec(line.cells[2]),
      amountCents = line.cells[3].toLongOrNull() ?: 0,
      updatedAt = line.cells[4].toLongOrNull() ?: 0,
    )

  private fun enc(text: String): String = Base64.getEncoder().encodeToString(text.toByteArray(Charsets.UTF_8))

  private fun dec(text: String): String {
    if (text.isEmpty()) {
      return ""
    }
    return try {
      String(Base64.getDecoder().decode(text), Charsets.UTF_8)
    } catch (error: IllegalArgumentException) {
      ""
    }
  }

  private fun bool(value: Boolean): String = if (value) "1" else "0"

  private fun sha256(text: String): String {
    val digest = MessageDigest.getInstance("SHA-256").digest(text.toByteArray(Charsets.UTF_8))
    return digest.joinToString("") { "%02x".format(it) }
  }

  private fun csvStamp(timestamp: Long): String {
    val date = com.github.ppg007.moremoney.util.DateUtil.toLocalDateTime(timestamp)
    return "${date.year}${CsvFormat.pad2(date.monthValue)}${CsvFormat.pad2(date.dayOfMonth)}_" +
      "${CsvFormat.pad2(date.hour)}${CsvFormat.pad2(date.minute)}"
  }
}
