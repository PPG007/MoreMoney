package com.github.ppg007.moremoney.service

import com.github.ppg007.moremoney.data.repository.TxnRepository

/** 删除与撤销：软删除保留 30 天，应用启动时清理过期数据。 */
class DeleteService(private val txnRepository: TxnRepository) {
  suspend fun deleteTxn(txnId: String) = txnRepository.softDelete(txnId)

  suspend fun undoDelete(txnId: String) = txnRepository.restore(txnId)

  suspend fun purgeExpired() = txnRepository.purgeExpired()
}
