package com.github.ppg007.moremoney.data.db.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.github.ppg007.moremoney.data.db.entity.BudgetEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface BudgetDao {
  @Query("SELECT * FROM budget ORDER BY updated_at DESC")
  fun observeAll(): Flow<List<BudgetEntity>>

  @Query("SELECT * FROM budget WHERE book_id = :bookId LIMIT 1")
  suspend fun get(bookId: String): BudgetEntity?

  @Query("SELECT * FROM budget WHERE book_id = :bookId LIMIT 1")
  fun observeByBook(bookId: String): Flow<BudgetEntity?>

  @Query("SELECT * FROM budget")
  suspend fun listAll(): List<BudgetEntity>

  @Insert(onConflict = OnConflictStrategy.REPLACE)
  suspend fun upsert(budget: BudgetEntity)

  @Query("DELETE FROM budget WHERE book_id = :bookId")
  suspend fun remove(bookId: String)

  @Query("DELETE FROM budget")
  suspend fun deleteAll()
}
