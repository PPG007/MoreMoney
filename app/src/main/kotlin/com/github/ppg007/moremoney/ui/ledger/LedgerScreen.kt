package com.github.ppg007.moremoney.ui.ledger

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.listSaver
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.github.ppg007.moremoney.R
import com.github.ppg007.moremoney.data.db.entity.TxnEntity
import com.github.ppg007.moremoney.state.AppUiState
import com.github.ppg007.moremoney.ui.common.HomeViewModel
import com.github.ppg007.moremoney.ui.common.SystemBarAppearance
import com.github.ppg007.moremoney.ui.common.appViewModel
import com.github.ppg007.moremoney.ui.components.base.ConfirmDialog
import com.github.ppg007.moremoney.ui.components.base.EmptyState
import com.github.ppg007.moremoney.ui.components.base.ErrorRetry
import com.github.ppg007.moremoney.ui.components.base.MoneyText
import com.github.ppg007.moremoney.ui.components.base.MoneyTone
import com.github.ppg007.moremoney.ui.components.base.SkeletonList
import com.github.ppg007.moremoney.ui.components.base.pullUp
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.ui.theme.Spacing
import com.github.ppg007.moremoney.util.DateUtil

private const val MAX_ROWS_PER_DAY = 20

/**
 * 一级 Tab“账本”：Hero、摘要卡、最近记录、按日分组流水与 FAB。
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun LedgerScreen(
  ui: AppUiState,
  onAdd: (bookId: String, dayKey: String) -> Unit,
  onSearch: () -> Unit,
  onEditTxn: (String) -> Unit,
  onGoBudget: () -> Unit,
  modifier: Modifier = Modifier,
) {
  val viewModel: HomeViewModel = appViewModel { HomeViewModel(it) }
  val state by viewModel.state.collectAsStateWithLifecycle()
  val colors = MoreMoneyTheme.colors
  var detailTxn by remember { mutableStateOf<TxnEntity?>(null) }
  var pendingDelete by remember { mutableStateOf<TxnEntity?>(null) }
  var revealedTxnId by remember { mutableStateOf<String?>(null) }
  var showAllDay by remember { mutableStateOf("") }
  var collapsedDays by rememberSaveable(
    stateSaver =
      listSaver<Set<String>, String>(
        save = { it.toList() },
        restore = { it.toSet() },
      ),
  ) { mutableStateOf(emptySet<String>()) }

  SystemBarAppearance(darkIcons = false)

  Box(modifier = modifier.fillMaxSize().background(colors.background)) {
    if (state.loading) {
      Column(modifier = Modifier.padding(top = 120.dp)) {
        SkeletonList(rows = 5)
      }
    } else {
      LazyColumn(modifier = Modifier.fillMaxSize()) {
        item(key = "hero") {
          Column(modifier = Modifier.fillMaxWidth()) {
            HomeHero(
              ui = ui,
              monthLabel = DateUtil.formatMonthCn(state.monthKey),
              books = state.books,
              selectedBookId = state.selectedBookId,
              onSelectBook = viewModel::selectBook,
              onSearch = onSearch,
              onPrevMonth = { viewModel.changeMonth(-1) },
              onNextMonth = { viewModel.changeMonth(1) },
            )
            SummaryCard(
              spentCents = state.spentCents,
              budgetCents = state.budgetCents,
              hasBudget = state.hasBudget,
              perDayCents = state.perDayCents,
              hidden = ui.hideAmount,
              onGoBudget = onGoBudget,
              modifier =
                Modifier
                  .padding(horizontal = Spacing.page)
                  .pullUp(54.dp),
            )
          }
        }

        item(key = "recent") {
          Column(
            modifier = Modifier.padding(horizontal = Spacing.page).padding(top = Spacing.x3),
            verticalArrangement = Arrangement.spacedBy(Spacing.x2),
          ) {
            Text(
              text = "最近记录",
              style = MoreMoneyTextStyles.body.copy(fontWeight = FontWeight.Bold),
              color = colors.ink,
            )
          }
        }

        if (state.days.isEmpty()) {
          item(key = "empty") {
            EmptyState(
              title = "本月还没有记账",
              description = "点右下角按钮记一笔",
              modifier = Modifier.padding(horizontal = Spacing.page, vertical = Spacing.x7),
            )
          }
        } else {
          state.days.forEach { group ->
            val collapsed = group.dayKey in collapsedDays
            item(key = "day-${group.dayKey}") {
              val showAll = showAllDay == group.dayKey
              val visible = if (showAll) group.txns else group.txns.take(MAX_ROWS_PER_DAY)
              Column(
                modifier =
                  Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Spacing.page)
                    .padding(bottom = Spacing.x3)
                    .clip(RoundedCornerShape(Radius.card))
                    .background(colors.surface)
                    .border(1.dp, colors.line, RoundedCornerShape(Radius.card)),
              ) {
                DayCardHeader(
                  dayKey = group.dayKey,
                  cents = group.cents,
                  hidden = ui.hideAmount,
                  expanded = !collapsed,
                  onToggle = {
                    collapsedDays =
                      if (collapsed) collapsedDays - group.dayKey else collapsedDays + group.dayKey
                    revealedTxnId = null
                  },
                  modifier = Modifier.testTag("day_header_${group.dayKey}"),
                )
                if (!collapsed) {
                  Box(Modifier.fillMaxWidth().height(1.dp).background(colors.line))
                  Column(modifier = Modifier.testTag("day_${group.dayKey}")) {
                    visible.forEachIndexed { index, txn ->
                      val isRevealed = revealedTxnId == txn.id
                      SwipeTxnRow(
                        txn = txn,
                        category = state.categoryOf(txn.categoryId),
                        hidden = ui.hideAmount,
                        revealed = isRevealed,
                        onRevealChange = { open ->
                          revealedTxnId =
                            when {
                              open -> txn.id
                              revealedTxnId == txn.id -> null
                              else -> revealedTxnId
                            }
                        },
                        onClick = {
                          if (isRevealed) {
                            revealedTxnId = null
                          } else {
                            revealedTxnId = null
                            detailTxn = txn
                          }
                        },
                        onEdit = {
                          revealedTxnId = null
                          onEditTxn(txn.id)
                        },
                        onDelete = { pendingDelete = txn },
                      )
                      if (index != visible.size - 1) {
                        Box(
                          modifier =
                            Modifier
                              .padding(start = 66.dp)
                              .height(1.dp)
                              .fillMaxWidth()
                              .background(colors.line),
                        )
                      }
                    }
                    if (!showAll && group.txns.size > MAX_ROWS_PER_DAY) {
                      Row(
                        modifier =
                          Modifier
                            .fillMaxWidth()
                            .height(36.dp)
                            .clickable { showAllDay = group.dayKey },
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically,
                      ) {
                        Text(
                          text = "其余 ${group.txns.size - MAX_ROWS_PER_DAY} 笔",
                          style = MoreMoneyTextStyles.caption.copy(fontWeight = FontWeight.SemiBold),
                          color = colors.brandInk,
                        )
                      }
                    }
                  }
                }
              }
            }
          }
        }

        item(key = "bottom") { Spacer(Modifier.height(150.dp)) }
      }
    }

    if (state.error.isNotEmpty()) {
      ErrorRetry(
        message = state.error,
        onRetry = { viewModel.selectBook(state.selectedBookId) },
        modifier = Modifier.align(Alignment.Center),
      )
    }

    Box(
      modifier =
        Modifier
          .align(Alignment.BottomEnd)
          .padding(end = Spacing.page, bottom = Spacing.page)
          .size(70.dp)
          .clip(CircleShape)
          .background(colors.buttonBackground)
          .testTag("fab_add")
          .clickable { onAdd(state.selectedBookId, DateUtil.nowDayKey()) },
      contentAlignment = Alignment.Center,
    ) {
      Icon(
        painter = painterResource(R.drawable.ic_edit),
        contentDescription = stringResource(R.string.cd_add_txn),
        tint = colors.buttonForeground,
        modifier = Modifier.size(29.dp),
      )
    }
  }

  detailTxn?.let { txn ->
    TxnDetailSheet(
      txn = txn,
      category = state.categoryOf(txn.categoryId),
      book = state.bookById[txn.bookId],
      hidden = ui.hideAmount,
      onDismiss = { detailTxn = null },
      onEdit = {
        detailTxn = null
        onEditTxn(txn.id)
      },
      onDelete = {
        detailTxn = null
        viewModel.deleteTxn(txn)
      },
    )
  }

  pendingDelete?.let { txn ->
    ConfirmDialog(
      visible = true,
      title = "删除这笔记录？",
      message = "删除后 5 秒内可在列表底部撤销。",
      confirmLabel = "删除",
      danger = true,
      onConfirm = {
        pendingDelete = null
        revealedTxnId = null
        viewModel.deleteTxn(txn)
      },
      onDismiss = {
        pendingDelete = null
        revealedTxnId = null
      },
    )
  }
}

/** 日期卡片头：左侧折叠按钮 + 日期 + 当天小计。 */
@Composable
private fun DayCardHeader(
  dayKey: String,
  cents: Long,
  hidden: Boolean,
  expanded: Boolean,
  onToggle: () -> Unit,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  Row(
    modifier =
      modifier
        .fillMaxWidth()
        .background(colors.surface2)
        .clickable(onClick = onToggle)
        .padding(horizontal = 12.dp)
        .height(44.dp),
    verticalAlignment = Alignment.CenterVertically,
    horizontalArrangement = Arrangement.spacedBy(9.dp),
  ) {
    Box(
      modifier =
        Modifier
          .size(26.dp)
          .clip(RoundedCornerShape(9.dp))
          .background(colors.brandWash),
      contentAlignment = Alignment.Center,
    ) {
      Icon(
        painter = painterResource(R.drawable.ic_chevron_right),
        contentDescription = if (expanded) "收起" else "展开",
        tint = colors.brandInk,
        modifier = Modifier.size(14.dp).rotate(if (expanded) 90f else 0f),
      )
    }
    Text(
      text = DateUtil.formatDayCn(dayKey),
      style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.Bold),
      color = colors.ink,
      modifier = Modifier.weight(1f),
    )
    MoneyText(
      cents = cents,
      hidden = hidden,
      tone = MoneyTone.Ink,
      style = MoreMoneyTextStyles.settingsTitle.copy(fontWeight = FontWeight.Bold),
    )
  }
}

