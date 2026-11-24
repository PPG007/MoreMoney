package com.github.ppg007.moremoney.data.repository

import com.github.ppg007.moremoney.data.db.MoreMoneyDatabase
import com.github.ppg007.moremoney.data.db.entity.BudgetEntity
import kotlinx.coroutines.flow.Flow

/** 预算仓库：`(bookId, period)` 唯一；首次写入 ID 为 `budget_<bookId>_<period>`。 */
class BudgetRepository(private val db: MoreMoneyDatabase) {
  private val dao = db.budgetDao()

  fun observeAll(): Flow<List<BudgetEntity>> = dao.observeAll()

  fun observeByPeriod(period: String): Flow<List<BudgetEntity>> = dao.observeByPeriod(period)

  suspend fun get(bookId: String, period: String): BudgetEntity? = dao.get(bookId, period)

  suspend fun listByPeriod(period: String): List<BudgetEntity> = dao.listByPeriod(period)

  suspend fun listAll(): List<BudgetEntity> = dao.listAll()

  suspend fun upsert(bookId: String, period: String, amountCents: Long) {
    val existing = dao.get(bookId, period)
    val id = existing?.id ?: "budget_${bookId}_$period"
    dao.upsert(
      BudgetEntity(
        id = id,
        bookId = bookId,
        period = period,
        amountCents = amountCents,
        updatedAt = System.currentTimeMillis(),
      )
    )
  }

  suspend fun remove(bookId: String, period: String) = dao.remove(bookId, period)
}
