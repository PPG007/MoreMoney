package com.github.ppg007.moremoney.data.db.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.github.ppg007.moremoney.data.db.entity.BookEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface BookDao {
  @Query("SELECT * FROM book ORDER BY archived ASC, sort ASC, created_at ASC")
  fun observeAll(): Flow<List<BookEntity>>

  @Query("SELECT * FROM book ORDER BY archived ASC, sort ASC, created_at ASC")
  suspend fun list(): List<BookEntity>

  @Query("SELECT * FROM book WHERE id = :id")
  suspend fun get(id: String): BookEntity?

  @Insert(onConflict = OnConflictStrategy.REPLACE)
  suspend fun insert(book: BookEntity)

  @Insert(onConflict = OnConflictStrategy.IGNORE)
  suspend fun insertIgnore(book: BookEntity)

  @Update
  suspend fun update(book: BookEntity)

  @Query("UPDATE book SET is_default = 0, updated_at = :now WHERE is_default = 1")
  suspend fun clearDefaults(now: Long)

  @Query("UPDATE book SET is_default = 1, updated_at = :now WHERE id = :id")
  suspend fun markDefault(id: String, now: Long)

  @Query("UPDATE book SET archived = 1, updated_at = :now WHERE id = :id")
  suspend fun archive(id: String, now: Long)

  @Query("UPDATE book SET archived = 0, updated_at = :now WHERE id = :id")
  suspend fun unarchive(id: String, now: Long)

  @Query("DELETE FROM book WHERE id = :id")
  suspend fun deleteById(id: String)

  @Query("SELECT COUNT(*) FROM txn WHERE book_id = :bookId")
  suspend fun countTxns(bookId: String): Int

  @Query("SELECT COUNT(*) FROM book WHERE archived = 0 AND id <> :id")
  suspend fun countOtherActive(id: String): Int

  @Query("SELECT COUNT(*) FROM book")
  suspend fun countAll(): Int

  @Query("SELECT * FROM book WHERE is_default = 1 LIMIT 1")
  suspend fun defaultBook(): BookEntity?

  @Query("DELETE FROM book")
  suspend fun deleteAll()
}
