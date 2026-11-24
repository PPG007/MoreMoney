package com.github.ppg007.moremoney.data.repository

import com.github.ppg007.moremoney.data.db.MoreMoneyDatabase
import com.github.ppg007.moremoney.data.db.entity.TxnEntity
import kotlinx.coroutines.flow.Flow

/** 流水仓库；软删除保留 30 天，可撤销。 */
class TxnRepository(private val db: MoreMoneyDatabase) {
  private val dao = db.txnDao()

  companion object {
    const val RETENTION_MS = 30L * 24 * 60 * 60 * 1000
  }

  fun observeActive(): Flow<List<TxnEntity>> = dao.observeActive()

  suspend fun listActive(): List<TxnEntity> = dao.listActive()

  suspend fun get(id: String): TxnEntity? = dao.get(id)

  suspend fun insert(txn: TxnEntity) = dao.insert(txn)

  suspend fun update(txn: TxnEntity) {
    if (dao.get(txn.id) == null) {
      dao.insert(txn)
    } else {
      dao.update(txn)
    }
  }

  suspend fun softDelete(id: String) = dao.softDelete(id, System.currentTimeMillis())

  suspend fun restore(id: String) = dao.restore(id, System.currentTimeMillis())

  suspend fun purgeExpired() = dao.hardDeleteExpired(System.currentTimeMillis() - RETENTION_MS)

  suspend fun listByDay(dayKey: String): List<TxnEntity> = dao.listByDay(dayKey)

  suspend fun listBetween(startMs: Long, endMs: Long): List<TxnEntity> = dao.listBetween(startMs, endMs)

  suspend fun listRecent(limit: Int): List<TxnEntity> = dao.listRecent(limit)

  suspend fun listDeleted(limit: Int): List<TxnEntity> = dao.listDeleted(limit)

  suspend fun moveToBook(fromBookId: String, toBookId: String) =
    dao.moveToBook(fromBookId, toBookId, System.currentTimeMillis())

  suspend fun search(keyword: String, limit: Int = 100): List<TxnEntity> =
    dao.search("%${keyword.trim()}%", limit)

  suspend fun allIds(): List<String> = dao.allIds()

  suspend fun countActive(): Int = dao.countActive()

  suspend fun countByBook(id: String): Int = dao.countByBook(id)

  suspend fun countByCategory(id: String): Int = dao.countByCategory(id)
}
