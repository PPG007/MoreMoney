package com.github.ppg007.moremoney.data.repository

import androidx.room.withTransaction
import com.github.ppg007.moremoney.data.db.MoreMoneyDatabase
import com.github.ppg007.moremoney.data.db.entity.BookEntity
import kotlinx.coroutines.flow.Flow

/**
 * 账本仓库。删除约束：
 * - 有流水（含软删）只能归档；
 * - 默认账本必须先在别处指定新默认才能删除。
 */
class BookRepository(private val db: MoreMoneyDatabase) {
  private val dao = db.bookDao()

  fun observeAll(): Flow<List<BookEntity>> = dao.observeAll()

  suspend fun list(): List<BookEntity> = dao.list()

  suspend fun get(id: String): BookEntity? = dao.get(id)

  suspend fun defaultBook(): BookEntity? = dao.defaultBook() ?: dao.list().firstOrNull()

  suspend fun save(book: BookEntity) {
    val existing = dao.get(book.id)
    if (existing == null) {
      dao.insert(book)
    } else {
      dao.update(book)
    }
  }

  suspend fun insertIgnore(book: BookEntity) = dao.insertIgnore(book)

  suspend fun setDefault(id: String) {
    val now = System.currentTimeMillis()
    db.withTransaction {
      dao.clearDefaults(now)
      dao.markDefault(id, now)
    }
  }

  suspend fun archive(id: String) = dao.archive(id, System.currentTimeMillis())

  suspend fun unarchive(id: String) = dao.unarchive(id, System.currentTimeMillis())

  suspend fun delete(book: BookEntity) {
    if (dao.countTxns(book.id) > 0) {
      throw IllegalStateException("该账本已有流水，请使用归档")
    }
    if (book.isDefault && dao.countOtherActive(book.id) > 0) {
      throw IllegalStateException("请先指定新的默认账本")
    }
    dao.deleteById(book.id)
  }

  suspend fun countTxns(id: String): Int = dao.countTxns(id)

  suspend fun countOtherActive(id: String): Int = dao.countOtherActive(id)

  suspend fun countAll(): Int = dao.countAll()

  /** 上移/下移账本并持久化 sort；只调整未归档账本。 */
  suspend fun move(bookId: String, delta: Int) {
    val active = dao.list().filter { !it.archived }.sortedWith(compareBy({ it.sort }, { it.createdAt }))
    val index = active.indexOfFirst { it.id == bookId }
    val target = index + delta
    if (index < 0 || target !in active.indices) {
      return
    }
    val reordered = active.toMutableList()
    val moved = reordered.removeAt(index)
    reordered.add(target, moved)
    val now = System.currentTimeMillis()
    db.withTransaction {
      reordered.forEachIndexed { position, book ->
        if (book.sort != position) {
          dao.update(book.copy(sort = position, updatedAt = now))
        }
      }
    }
  }
}
