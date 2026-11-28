package com.github.ppg007.moremoney.ui.search

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.github.ppg007.moremoney.R
import com.github.ppg007.moremoney.appContainer
import com.github.ppg007.moremoney.data.db.entity.TxnEntity
import com.github.ppg007.moremoney.state.AppUiState
import com.github.ppg007.moremoney.ui.common.SystemBarAppearance
import com.github.ppg007.moremoney.ui.components.base.AppIconButton
import com.github.ppg007.moremoney.ui.components.base.AppTextField
import com.github.ppg007.moremoney.ui.components.base.Chip
import com.github.ppg007.moremoney.ui.components.base.EmptyState
import com.github.ppg007.moremoney.ui.components.base.EyeButton
import com.github.ppg007.moremoney.ui.components.base.SheetTitle
import com.github.ppg007.moremoney.ui.components.base.AppBottomSheet
import com.github.ppg007.moremoney.ui.ledger.DayHeader
import com.github.ppg007.moremoney.ui.ledger.TxnDetailSheet
import com.github.ppg007.moremoney.ui.ledger.TxnRow
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.ui.theme.Spacing
import com.github.ppg007.moremoney.util.DateUtil
import com.github.ppg007.moremoney.util.MoneyUtil
import com.github.ppg007.moremoney.util.PinyinUtil
import kotlinx.coroutines.launch

/**
 * 搜索：备注、分类、金额；支持拼音全拼与首字母。
 *
 * 只搜索未归档账本；结果按日期分组，点击详情、长按删除并可撤销。
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun SearchScreen(
  initialBookId: String,
  ui: AppUiState,
  onBack: () -> Unit,
  onEditTxn: (String) -> Unit,
) {
  val container = LocalContext.current.appContainer
  val colors = MoreMoneyTheme.colors
  val books by container.bookRepository.observeAll().collectAsStateWithLifecycle(emptyList())
  val categories by container.categoryRepository.observeAll().collectAsStateWithLifecycle(emptyList())
  val txns by container.txnRepository.observeActive().collectAsStateWithLifecycle(emptyList())
  var keyword by remember { mutableStateOf("") }
  var recentSearches by remember { mutableStateOf(listOf<String>()) }
  var detailTxn by remember { mutableStateOf<TxnEntity?>(null) }
  var actionTxn by remember { mutableStateOf<TxnEntity?>(null) }

  SystemBarAppearance()

  val activeBookIds = books.filter { !it.archived }.map { it.id }.toSet()
  val categoryById = categories.associateBy { it.id }
  val bookById = books.associateBy { it.id }
  val trimmed = keyword.trim()
  val results =
    if (trimmed.isEmpty()) {
      emptyList()
    } else {
      txns.filter { txn ->
        if (txn.bookId !in activeBookIds) {
          return@filter false
        }
        if (initialBookId.isNotEmpty() && txn.bookId != initialBookId) {
          return@filter false
        }
        val category = categoryById[txn.categoryId]
        txn.note.contains(trimmed, ignoreCase = true) ||
          (category != null && (category.name.contains(trimmed, ignoreCase = true) || PinyinUtil.matches(category.name, trimmed))) ||
          MoneyUtil.formatYuan(txn.amountCents).contains(trimmed) ||
          MoneyUtil.formatCents(txn.amountCents, symbol = false).replace(",", "").contains(trimmed)
      }
    }

  val grouped = LinkedHashMap<String, MutableList<TxnEntity>>()
  for (txn in results) {
    grouped.getOrPut(txn.dayKey) { ArrayList() }.add(txn)
  }

  fun rememberKeyword() {
    if (trimmed.isNotEmpty()) {
      recentSearches = (listOf(trimmed) + recentSearches.filter { it != trimmed }).take(8)
    }
  }

  Column(modifier = Modifier.fillMaxSize().background(colors.background).navigationBarsPadding()) {
    Row(
      modifier =
        Modifier
          .fillMaxWidth()
          .statusBarsPadding()
          .height(52.dp)
          .padding(horizontal = Spacing.page),
      verticalAlignment = Alignment.CenterVertically,
      horizontalArrangement = Arrangement.spacedBy(Spacing.x2),
    ) {
      AppIconButton(
        iconRes = R.drawable.ic_back,
        contentDescription = stringResource(R.string.action_back),
        onClick = onBack,
      )
      AppTextField(
        value = keyword,
        onValueChange = { keyword = it },
        placeholder = "搜索备注、分类、金额",
        leadingIcon = R.drawable.ic_search,
        modifier = Modifier.weight(1f),
        singleLine = true,
        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
      )
      EyeButton(ui = ui)
    }

    Column(
      modifier = Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = Spacing.page),
    ) {
      if (trimmed.isEmpty()) {
        if (recentSearches.isNotEmpty()) {
          Text(
            text = "最近搜索",
            style = MoreMoneyTextStyles.body.copy(fontWeight = FontWeight.Bold),
            color = colors.ink,
            modifier = Modifier.padding(top = Spacing.x5, bottom = Spacing.x3),
          )
          FlowRow(horizontalArrangement = Arrangement.spacedBy(Spacing.x2), verticalArrangement = Arrangement.spacedBy(Spacing.x2)) {
            recentSearches.forEach { item ->
              Text(
                text = item,
                style = MoreMoneyTextStyles.caption,
                color = colors.ink2,
                modifier =
                  Modifier
                    .clip(RoundedCornerShape(Radius.pill))
                    .background(colors.surface)
                    .clickable { keyword = item }
                    .padding(horizontal = 10.dp, vertical = 5.dp),
              )
            }
          }
        }
        Text(
          text = "试试输入「午餐」「餐饮」或金额「32」。中文分类支持拼音与首字母。",
          style = MoreMoneyTextStyles.caption,
          color = colors.ink3,
          modifier = Modifier.padding(top = Spacing.x5),
        )
      } else {
        Text(
          text = "找到 ${results.size} 条",
          style = MoreMoneyTextStyles.caption,
          color = colors.ink3,
          modifier = Modifier.padding(vertical = Spacing.x3),
        )
        if (results.isEmpty()) {
          EmptyState(
            title = "没有找到相关记录",
            description = "换个关键词试试，或检查账本是否已归档",
          )
        } else {
          grouped.forEach { (dayKey, list) ->
            DayHeader(dayKey = dayKey, cents = list.sumOf { it.amountCents }, hidden = ui.hideAmount)
            Column(
              modifier =
                Modifier
                  .fillMaxWidth()
                  .padding(bottom = Spacing.x3)
                  .clip(RoundedCornerShape(Radius.card))
                  .background(colors.surface),
            ) {
              list.forEachIndexed { index, txn ->
                TxnRow(
                  txn = txn,
                  category = categoryById[txn.categoryId],
                  hidden = ui.hideAmount,
                  isFirst = index == 0,
                  isLast = index == list.size - 1,
                  onClick = {
                    rememberKeyword()
                    detailTxn = txn
                  },
                  onLongClick = {
                    rememberKeyword()
                    actionTxn = txn
                  },
                )
                if (index != list.size - 1) {
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
            }
          }
        }
      }
      Spacer(Modifier.height(120.dp))
    }
  }

  detailTxn?.let { txn ->
    TxnDetailSheet(
      txn = txn,
      category = categoryById[txn.categoryId],
      book = bookById[txn.bookId],
      hidden = ui.hideAmount,
      onDismiss = { detailTxn = null },
      onEdit = {
        detailTxn = null
        onEditTxn(txn.id)
      },
      onDelete = {
        detailTxn = null
        container.appScope.launch {
          runCatching { container.deleteService.deleteTxn(txn.id) }
            .onSuccess {
              container.ui.showSnack("已删除 1 笔", "撤销", 5000) {
                container.appScope.launch {
                  runCatching { container.deleteService.undoDelete(txn.id) }
                }
              }
            }
        }
      },
    )
  }

  actionTxn?.let { txn ->
    AppBottomSheet(onDismiss = { actionTxn = null }) {
      SheetTitle(title = "操作")
      Text(
        text = "删除这笔记录",
        style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.Bold),
        color = colors.expense,
        modifier =
          Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Radius.chip))
            .background(colors.surface2)
            .clickable {
              actionTxn = null
              container.appScope.launch {
                runCatching { container.deleteService.deleteTxn(txn.id) }
                  .onSuccess {
                    container.ui.showSnack("已删除 1 笔", "撤销", 5000) {
                      container.appScope.launch {
                        runCatching { container.deleteService.undoDelete(txn.id) }
                      }
                    }
                  }
              }
            }
            .padding(vertical = 12.dp),
        textAlign = androidx.compose.ui.text.style.TextAlign.Center,
      )
      Text(
        text = "取消",
        style = MoreMoneyTextStyles.row,
        color = colors.ink2,
        modifier =
          Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Radius.chip))
            .clickable { actionTxn = null }
            .padding(vertical = 12.dp),
        textAlign = androidx.compose.ui.text.style.TextAlign.Center,
      )
    }
  }
}
