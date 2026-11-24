package com.github.ppg007.moremoney

import android.content.Context
import com.github.ppg007.moremoney.data.db.MoreMoneyDatabase
import com.github.ppg007.moremoney.data.db.SeedData
import com.github.ppg007.moremoney.data.repository.BookRepository
import com.github.ppg007.moremoney.data.repository.BudgetRepository
import com.github.ppg007.moremoney.data.repository.CategoryRepository
import com.github.ppg007.moremoney.data.repository.TxnRepository
import com.github.ppg007.moremoney.service.BackupService
import com.github.ppg007.moremoney.service.BudgetService
import com.github.ppg007.moremoney.service.CsvExportService
import com.github.ppg007.moremoney.service.CsvImportService
import com.github.ppg007.moremoney.service.DeleteService
import com.github.ppg007.moremoney.service.StatsService
import com.github.ppg007.moremoney.state.AppUiState
import com.github.ppg007.moremoney.state.SettingsService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

/**
 * 应用级单例容器：数据库、仓库、服务与会话状态。
 *
 * 种子数据在构造时同步写入，保证第一帧查询就能拿到 3 个默认账本；
 * 过期软删清理放到后台协程，失败不阻断启动。
 */
class AppContainer(context: Context) {
  val db: MoreMoneyDatabase = MoreMoneyDatabase.create(context.applicationContext)
  val settings = SettingsService(context.applicationContext)
  val ui = AppUiState()

  val bookRepository = BookRepository(db)
  val categoryRepository = CategoryRepository(db)
  val txnRepository = TxnRepository(db)
  val budgetRepository = BudgetRepository(db)

  val statsService = StatsService(db)
  val budgetService = BudgetService(bookRepository, budgetRepository, statsService)
  val deleteService = DeleteService(txnRepository)
  val csvExportService = CsvExportService(bookRepository, categoryRepository, txnRepository)
  val csvImportService = CsvImportService(db, bookRepository, categoryRepository, txnRepository)
  val backupService = BackupService(db, bookRepository, categoryRepository, txnRepository, budgetRepository, settings)

  val appScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

  init {
    runBlocking(Dispatchers.IO) {
      SeedData.ensureSeeded(db)
    }
    appScope.launch {
      runCatching { deleteService.purgeExpired() }
    }
  }
}
