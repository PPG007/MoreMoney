package com.github.ppg007.moremoney.data.repository

import com.github.ppg007.moremoney.data.db.MoreMoneyDatabase
import com.github.ppg007.moremoney.data.db.entity.BudgetEntity
import com.github.ppg007.moremoney.models.BudgetCycle
import kotlinx.coroutines.flow.Flow

/** 预算仓库：每个账本最多一条预算（`book_id` 唯一），设置后按周期自动重复。 */
class BudgetRepository(private val db: MoreMoneyDatabase) {
  private val dao = db.budgetDao()

  fun observeAll(): Flow<List<BudgetEntity>> = dao.observeAll()

  fun observeByBook(bookId: String): Flow<BudgetEntity?> = dao.observeByBook(bookId)

  suspend fun get(bookId: String): BudgetEntity? = dao.get(bookId)

  suspend fun listAll(): List<BudgetEntity> = dao.listAll()

  suspend fun upsert(bookId: String, cycle: BudgetCycle, amountCents: Long) {
    val existing = dao.get(bookId)
    val id = existing?.id ?: "budget_$bookId"
    dao.upsert(
      BudgetEntity(
        id = id,
        bookId = bookId,
        cycle = cycle,
        amountCents = amountCents,
        updatedAt = System.currentTimeMillis(),
      )
    )
  }

  suspend fun remove(bookId: String) = dao.remove(bookId)
}
