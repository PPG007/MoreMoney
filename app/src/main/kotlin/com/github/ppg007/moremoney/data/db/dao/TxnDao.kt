package com.github.ppg007.moremoney.data.db.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.github.ppg007.moremoney.data.db.entity.TxnEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface TxnDao {
  /** 所有未删除流水；页面按账本/月份在内存里过滤，保证列表实时刷新。 */
  @Query("SELECT * FROM txn WHERE deleted_at IS NULL ORDER BY occurred_at DESC, created_at DESC")
  fun observeActive(): Flow<List<TxnEntity>>

  @Query("SELECT * FROM txn WHERE deleted_at IS NULL ORDER BY occurred_at DESC, created_at DESC")
  suspend fun listActive(): List<TxnEntity>

  @Query("SELECT * FROM txn WHERE id = :id")
  suspend fun get(id: String): TxnEntity?

  @Query("SELECT * FROM txn WHERE deleted_at IS NULL AND day_key = :dayKey ORDER BY occurred_at DESC, created_at DESC")
  suspend fun listByDay(dayKey: String): List<TxnEntity>

  @Query(
    "SELECT * FROM txn WHERE deleted_at IS NULL AND occurred_at >= :startMs AND occurred_at <= :endMs " +
      "ORDER BY occurred_at DESC, created_at DESC",
  )
  suspend fun listBetween(startMs: Long, endMs: Long): List<TxnEntity>

  @Query("SELECT * FROM txn WHERE deleted_at IS NULL ORDER BY occurred_at DESC, created_at DESC LIMIT :limit")
  suspend fun listRecent(limit: Int): List<TxnEntity>

  @Query("SELECT * FROM txn WHERE deleted_at IS NOT NULL ORDER BY deleted_at DESC LIMIT :limit")
  suspend fun listDeleted(limit: Int): List<TxnEntity>

  @Insert(onConflict = OnConflictStrategy.REPLACE)
  suspend fun insert(txn: TxnEntity)

  @Insert(onConflict = OnConflictStrategy.IGNORE)
  suspend fun insertIgnore(txn: TxnEntity)

  @Update
  suspend fun update(txn: TxnEntity)

  @Query("UPDATE txn SET deleted_at = :now, updated_at = :now WHERE id = :id")
  suspend fun softDelete(id: String, now: Long)

  @Query("UPDATE txn SET deleted_at = NULL, updated_at = :now WHERE id = :id")
  suspend fun restore(id: String, now: Long)

  @Query("DELETE FROM txn WHERE deleted_at IS NOT NULL AND deleted_at < :before")
  suspend fun hardDeleteExpired(before: Long)

  @Query("UPDATE txn SET book_id = :toBookId, updated_at = :now WHERE book_id = :fromBookId AND deleted_at IS NULL")
  suspend fun moveToBook(fromBookId: String, toBookId: String, now: Long)

  @Query(
    "SELECT t.* FROM txn t INNER JOIN category c ON c.id = t.category_id " +
      "WHERE t.deleted_at IS NULL AND (t.note LIKE :like OR c.name LIKE :like) " +
      "AND t.book_id NOT IN (SELECT id FROM book WHERE archived = 1) " +
      "ORDER BY t.occurred_at DESC, t.created_at DESC LIMIT :limit",
  )
  suspend fun search(like: String, limit: Int): List<TxnEntity>

  @Query("SELECT COUNT(*) FROM txn WHERE deleted_at IS NULL")
  suspend fun countActive(): Int

  @Query("SELECT COUNT(*) FROM txn")
  suspend fun countAll(): Int

  @Query("SELECT COUNT(*) FROM txn WHERE book_id = :bookId AND deleted_at IS NULL")
  suspend fun countByBook(bookId: String): Int

  @Query("SELECT COUNT(*) FROM txn WHERE category_id = :categoryId AND deleted_at IS NULL")
  suspend fun countByCategory(categoryId: String): Int

  @Query("SELECT COALESCE(SUM(amount_cents), 0) FROM txn WHERE deleted_at IS NULL")
  suspend fun sumAll(): Long

  @Query("DELETE FROM txn")
  suspend fun deleteAll()

  @Query("SELECT id FROM txn")
  suspend fun allIds(): List<String>
}
