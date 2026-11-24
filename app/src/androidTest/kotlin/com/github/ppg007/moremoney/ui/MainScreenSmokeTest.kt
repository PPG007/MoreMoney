package com.github.ppg007.moremoney.ui

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeLeft
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.github.ppg007.moremoney.MainActivity
import com.github.ppg007.moremoney.MoreMoneyApp
import com.github.ppg007.moremoney.util.DateUtil
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * 一级 Tab、金额隐藏与记一笔的 Compose UI 测试。
 *
 * 使用真实 Application 容器（seeded 数据库），每个测试开始前恢复金额显示。
 */
@RunWith(AndroidJUnit4::class)
class MainScreenSmokeTest {
  @get:Rule
  val composeRule = createAndroidComposeRule<MainActivity>()

  @Before
  fun resetUiState() {
    val app = ApplicationProvider.getApplicationContext<MoreMoneyApp>()
    app.container.ui.updateHideAmount(false)
  }

  @Test
  fun fourTabsAreVisibleAndSwitch() {
    composeRule.waitUntil(10_000) {
      composeRule.onAllNodesWithTag("tab_ledger").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("tab_ledger").assertIsDisplayed()
    composeRule.onNodeWithTag("tab_budget").assertIsDisplayed()
    composeRule.onNodeWithTag("tab_charts").assertIsDisplayed()
    composeRule.onNodeWithTag("tab_settings").assertIsDisplayed()

    composeRule.onNodeWithTag("tab_budget").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithText("预算合计").fetchSemanticsNodes().isNotEmpty()
    }

    composeRule.onNodeWithTag("tab_charts").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithText("趋势").fetchSemanticsNodes().isNotEmpty()
    }

    composeRule.onNodeWithTag("tab_settings").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithText("账本管理").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("tab_ledger").performClick()
  }

  @Test
  fun hideAmountBlursAllAmounts() {
    composeRule.waitUntil(10_000) {
      composeRule.onAllNodesWithTag("eye_button").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("eye_button").performClick()
    composeRule.waitUntil(3_000) {
      composeRule.onAllNodesWithText("¥••••").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("eye_button").performClick()
  }

  @Test
  fun addTransactionSavesAndReturnsHome() {
    composeRule.waitUntil(10_000) {
      composeRule.onAllNodesWithTag("fab_add").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("fab_add").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("save_txn").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("key_1").performClick()
    composeRule.onNodeWithTag("key_2").performClick()
    composeRule.waitUntil(3_000) {
      composeRule.onAllNodesWithText("合计 ¥12.00").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("save_txn").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("fab_add").fetchSemanticsNodes().isNotEmpty()
    }
    // 直接查库确认 12.00 已落库；首页汇总金额会随其他测试数据变化，不能写死断言。
    val app = ApplicationProvider.getApplicationContext<MoreMoneyApp>()
    val saved = runBlocking { app.container.txnRepository.listActive().any { it.amountCents == 1200L } }
    assertTrue(saved)
  }

  @Test
  fun dayRecordsCollapseAndExpand() {
    composeRule.waitUntil(10_000) {
      composeRule.onAllNodesWithTag("fab_add").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("fab_add").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("save_txn").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("key_1").performClick()
    composeRule.waitUntil(3_000) {
      composeRule.onAllNodesWithText("合计 ¥1.00").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("save_txn").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("fab_add").fetchSemanticsNodes().isNotEmpty()
    }

    val dayKey = DateUtil.nowDayKey()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("day_$dayKey").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("day_header_$dayKey").performClick()
    composeRule.waitUntil(3_000) {
      composeRule.onAllNodesWithTag("day_$dayKey").fetchSemanticsNodes().isEmpty()
    }
    composeRule.onNodeWithTag("day_header_$dayKey").performClick()
    composeRule.waitUntil(3_000) {
      composeRule.onAllNodesWithTag("day_$dayKey").fetchSemanticsNodes().isNotEmpty()
    }
  }

  @Test
  fun swipeRowRevealsActionsWithDeleteConfirm() {
    composeRule.waitUntil(10_000) {
      composeRule.onAllNodesWithTag("fab_add").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("fab_add").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("save_txn").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("key_1").performClick()
    composeRule.waitUntil(3_000) {
      composeRule.onAllNodesWithText("合计 ¥1.00").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("save_txn").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("fab_add").fetchSemanticsNodes().isNotEmpty()
    }

    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("txn_row").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onAllNodesWithTag("txn_row")[0].performTouchInput { swipeLeft() }
    composeRule.waitUntil(3_000) {
      composeRule.onAllNodesWithTag("swipe_actions").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("swipe_delete").performClick()
    composeRule.waitUntil(3_000) {
      composeRule.onAllNodesWithText("删除这笔记录？").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithText("取消").performClick()
  }

  @Test
  fun leadingZeroIsIgnored() {
    composeRule.waitUntil(10_000) {
      composeRule.onAllNodesWithTag("fab_add").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("fab_add").performClick()
    composeRule.waitUntil(5_000) {
      composeRule.onAllNodesWithTag("save_txn").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithTag("key_0").performClick()
    composeRule.onNodeWithTag("key_0").performClick()
    composeRule.onNodeWithTag("save_txn").assertIsNotEnabled()
    composeRule.onNodeWithTag("key_5").performClick()
    composeRule.waitUntil(3_000) {
      composeRule.onAllNodesWithText("合计 ¥5.00").fetchSemanticsNodes().isNotEmpty()
    }
  }

  @Test
  fun searchScreenOpensFromHome() {
    composeRule.waitUntil(10_000) {
      composeRule.onAllNodesWithTag("tab_ledger").fetchSemanticsNodes().isNotEmpty()
    }
    composeRule.onNodeWithText("最近记录").assertIsDisplayed()
  }
}
