package com.github.ppg007.moremoney.ui.books

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.github.ppg007.moremoney.R
import com.github.ppg007.moremoney.appContainer
import com.github.ppg007.moremoney.data.db.entity.BookEntity
import com.github.ppg007.moremoney.models.BudgetCycle
import com.github.ppg007.moremoney.service.BudgetCycleUtil
import com.github.ppg007.moremoney.ui.budget.BudgetEditDialog
import com.github.ppg007.moremoney.ui.common.SystemBarAppearance
import com.github.ppg007.moremoney.ui.components.BookIconNames
import com.github.ppg007.moremoney.ui.components.base.AmountBar
import com.github.ppg007.moremoney.ui.components.base.AppBottomSheet
import com.github.ppg007.moremoney.ui.components.base.AppSwitch
import com.github.ppg007.moremoney.ui.components.base.AppTextField
import com.github.ppg007.moremoney.ui.components.base.Badge
import com.github.ppg007.moremoney.ui.components.base.BadgeTone
import com.github.ppg007.moremoney.ui.components.base.ConfirmDialog
import com.github.ppg007.moremoney.ui.components.base.EyeButton
import com.github.ppg007.moremoney.ui.components.base.dashedBorder
import com.github.ppg007.moremoney.ui.components.base.ListRow
import com.github.ppg007.moremoney.ui.components.base.MiniButton
import com.github.ppg007.moremoney.ui.components.base.PrimaryButton
import com.github.ppg007.moremoney.ui.components.base.SheetTitle
import com.github.ppg007.moremoney.ui.components.iconResOf
import com.github.ppg007.moremoney.ui.components.layout.PageHeader
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.ui.theme.SeedColors
import com.github.ppg007.moremoney.ui.theme.Spacing
import com.github.ppg007.moremoney.ui.theme.parseColorOf
import com.github.ppg007.moremoney.ui.theme.withAlpha
import com.github.ppg007.moremoney.util.DateUtil
import com.github.ppg007.moremoney.util.ErrorUtil
import com.github.ppg007.moremoney.util.IdUtil
import com.github.ppg007.moremoney.util.MoneyUtil
import kotlinx.coroutines.launch

/**
 * 账本管理：CRUD、默认、归档、预算入口。
 *
 * 不包含私密账本；有流水的账本只能归档，默认账本必须先指定新默认才能删除。
 */
@Composable
fun BookManageScreen(onBack: () -> Unit) {
  val container = LocalContext.current.appContainer
  val scope = rememberCoroutineScope()
  val colors = MoreMoneyTheme.colors
  val books by container.bookRepository.observeAll().collectAsStateWithLifecycle(emptyList())
  val budgets by container.budgetRepository.observeAll().collectAsStateWithLifecycle(emptyList())
  val txns by container.txnRepository.observeActive().collectAsStateWithLifecycle(emptyList())
  val monthKey = DateUtil.monthKey(DateUtil.today())

  var editingBook by remember { mutableStateOf<BookEntity?>(null) }
  var creating by remember { mutableStateOf(false) }
  var actionBook by remember { mutableStateOf<BookEntity?>(null) }
  var budgetBook by remember { mutableStateOf<BookEntity?>(null) }
  var deletingBook by remember { mutableStateOf<BookEntity?>(null) }

  SystemBarAppearance()

  Column(modifier = Modifier.fillMaxSize().background(colors.background).navigationBarsPadding()) {
    PageHeader(
      title = "账本管理",
      onBack = onBack,
      trailing = { EyeButton(ui = container.ui) },
    )

    val active = books.filter { !it.archived }
    val archived = books.filter { it.archived }

    Column(
      modifier = Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = Spacing.page),
      verticalArrangement = Arrangement.spacedBy(Spacing.x3),
    ) {
      active.forEach { book ->
        val budget = budgets.firstOrNull { it.bookId == book.id && it.amountCents > 0 }
        val range = budget?.let { BudgetCycleUtil.range(it.cycle) }
        val count =
          if (range == null) {
            txns.count { it.bookId == book.id && it.dayKey.startsWith(monthKey) }
          } else {
            txns.count { it.bookId == book.id && it.occurredAt in range.startMs..range.endMs }
          }
        val spent =
          if (range == null) {
            0L
          } else {
            txns.filter { it.bookId == book.id && it.occurredAt in range.startMs..range.endMs }
              .sumOf { it.amountCents }
          }
        BookCard(
          book = book,
          budgetCents = budget?.amountCents ?: 0,
          cycle = budget?.cycle,
          spentCents = spent,
          count = count,
          hidden = container.ui.hideAmount,
          onClick = { actionBook = book },
          onSetBudget = { budgetBook = book },
        )
      }

      PrimaryButton(
        text = "新建账本",
        onClick = { creating = true },
        leadingIcon = R.drawable.ic_plus,
        modifier = Modifier.padding(top = Spacing.x2),
      )

      if (archived.isNotEmpty()) {
        Text(
          text = "已归档",
          style = MoreMoneyTextStyles.body.copy(fontWeight = FontWeight.Bold),
          color = colors.ink,
          modifier = Modifier.padding(top = Spacing.x5),
        )
        archived.forEach { book ->
          ListRow(
            title = book.name,
            subtitle = "已归档 · 不出现在首页与记账选择器",
            iconRes = iconResOf(book.icon),
            iconTint = parseColorOf(book.color),
            iconBackground = withAlpha(parseColorOf(book.color), 0.14f),
            trailing = {
              MiniButton(
                text = "恢复",
                onClick = {
                  scope.launch {
                    runCatching { container.bookRepository.unarchive(book.id) }
                  }
                },
              )
            },
            onClick = { actionBook = book },
            modifier =
              Modifier
                .clip(RoundedCornerShape(Radius.card))
                .background(colors.surface)
                .border(1.dp, colors.line, RoundedCornerShape(Radius.card)),
          )
        }
      }
      Spacer(Modifier.height(120.dp))
    }
  }

  if (creating || editingBook != null) {
    BookEditSheet(
      existing = editingBook,
      defaultColorIndex = books.size,
      onDismiss = {
        creating = false
        editingBook = null
      },
      onSave = { name, icon, color, isDefault ->
        val current = editingBook
        scope.launch {
          try {
            val now = System.currentTimeMillis()
            val entity =
              current?.copy(
                name = name,
                icon = icon,
                color = color,
                updatedAt = now,
              )
                ?: BookEntity(
                  id = "book_${IdUtil.next()}",
                  name = name,
                  icon = icon,
                  color = color,
                  isDefault = false,
                  sort = books.size,
                  archived = false,
                  createdAt = now,
                  updatedAt = now,
                )
            container.bookRepository.save(entity)
            if (isDefault) {
              container.bookRepository.setDefault(entity.id)
              container.settings.setDefaultBookId(entity.id)
            }
            container.ui.showSnack(if (current == null) "账本已创建" else "账本已更新")
            creating = false
            editingBook = null
          } catch (error: Exception) {
            container.ui.showSnack("保存失败：${ErrorUtil.messageOf(error)}")
          }
        }
      },
    )
  }

  actionBook?.let { book ->
    val activeBooks = books.filter { !it.archived }
    val position = activeBooks.indexOfFirst { it.id == book.id }
    AppBottomSheet(onDismiss = { actionBook = null }) {
      SheetTitle(title = book.name, subtitle = "本月 ${txns.count { it.bookId == book.id && it.dayKey.startsWith(monthKey) }} 笔")
      ActionRow("编辑账本") {
        actionBook = null
        editingBook = book
      }
      ActionRow("设置预算") {
        actionBook = null
        budgetBook = book
      }
      if (!book.archived && position > 0) {
        ActionRow("上移") {
          scope.launch {
            runCatching { container.bookRepository.move(book.id, -1) }
            actionBook = null
          }
        }
      }
      if (!book.archived && position >= 0 && position < activeBooks.size - 1) {
        ActionRow("下移") {
          scope.launch {
            runCatching { container.bookRepository.move(book.id, 1) }
            actionBook = null
          }
        }
      }
      if (!book.isDefault) {
        ActionRow("设为默认账本") {
          scope.launch {
            runCatching {
              container.bookRepository.setDefault(book.id)
              container.settings.setDefaultBookId(book.id)
            }
            container.ui.showSnack("已设为默认账本")
            actionBook = null
          }
        }
      }
      if (book.archived) {
        ActionRow("取消归档") {
          scope.launch {
            runCatching { container.bookRepository.unarchive(book.id) }
            actionBook = null
          }
        }
      } else {
        ActionRow("归档账本") {
          scope.launch {
            runCatching { container.bookRepository.archive(book.id) }
            container.ui.showSnack("账本已归档")
            actionBook = null
          }
        }
      }
      ActionRow("删除账本", danger = true) {
        actionBook = null
        deletingBook = book
      }
    }
  }

  budgetBook?.let { book ->
    val current = budgets.firstOrNull { it.bookId == book.id && it.amountCents > 0 }
    BudgetEditDialog(
      visible = true,
      bookName = book.name,
      currentCycle = current?.cycle ?: BudgetCycle.MONTH,
      currentCents = current?.amountCents ?: 0,
      onSave = { cycle, cents ->
        scope.launch {
          runCatching { container.budgetService.setBudget(book.id, cycle, cents) }
            .onFailure { container.ui.showSnack("设置失败：${ErrorUtil.messageOf(it)}") }
          budgetBook = null
        }
      },
      onClear = {
        scope.launch {
          runCatching { container.budgetService.removeBudget(book.id) }
          budgetBook = null
        }
      },
      onDismiss = { budgetBook = null },
    )
  }

  val deleting = deletingBook
  ConfirmDialog(
    visible = deleting != null,
    title = "删除账本「${deleting?.name.orEmpty()}」？",
    message = "有流水的账本不能删除；如有流水请改用归档。",
    confirmLabel = "删除",
    danger = true,
    onConfirm = {
      if (deleting != null) {
        scope.launch {
          try {
            container.bookRepository.delete(deleting)
            container.ui.showSnack("账本已删除")
          } catch (error: Exception) {
            container.ui.showSnack(ErrorUtil.messageOf(error))
          }
          deletingBook = null
        }
      }
    },
    onDismiss = { deletingBook = null },
  )
}

@Composable
private fun BookCard(
  book: BookEntity,
  budgetCents: Long,
  cycle: BudgetCycle?,
  spentCents: Long,
  count: Int,
  hidden: Boolean,
  onClick: () -> Unit,
  onSetBudget: () -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  val color = parseColorOf(book.color)
  val hasBudget = budgetCents > 0 && cycle != null
  val percent = if (hasBudget) (spentCents.toFloat() / budgetCents).coerceIn(0f, 1f) else 0f
  val remaining = budgetCents - spentCents
  val overspent = remaining < 0
  Column(
    modifier =
      Modifier
        .fillMaxWidth()
        .clip(RoundedCornerShape(Radius.card))
        .background(colors.surface)
        .border(1.dp, colors.line, RoundedCornerShape(Radius.card))
        .clickable(onClick = onClick)
        .padding(13.dp),
    verticalArrangement = Arrangement.spacedBy(9.dp),
  ) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(9.dp)) {
      Box(
        modifier =
          Modifier
            .size(46.dp)
            .clip(RoundedCornerShape(14.dp))
            .background(withAlpha(color, 0.16f)),
        contentAlignment = Alignment.Center,
      ) {
        Icon(
          painter = painterResource(iconResOf(book.icon)),
          contentDescription = null,
          tint = color,
          modifier = Modifier.size(23.dp),
        )
      }
      Column(modifier = Modifier.weight(1f)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(5.dp)) {
          Text(
            text = book.name,
            style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.Bold),
            color = colors.ink,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
          )
          if (book.isDefault) {
            Badge("默认")
          }
        }
        Text(
          text =
            if (hasBudget) {
              "${BudgetCycleUtil.shortLabel(cycle)} $count 笔 · " +
                "${BudgetCycleUtil.label(cycle)} ${MoneyUtil.formatCents(budgetCents)}"
            } else {
              "本月 $count 笔"
            },
          style = MoreMoneyTextStyles.caption,
          color = colors.ink3,
          maxLines = 1,
          overflow = TextOverflow.Ellipsis,
        )
      }
      if (!hasBudget) {
        MiniButton(text = "设置预算", onClick = onSetBudget)
      }
    }
    if (hasBudget) {
      AmountBar(progress = percent, hidden = hidden, height = 5.dp)
      Row {
        Text(
          text = if (hidden) "已用 ¥••••" else "已用 ${MoneyUtil.formatCents(spentCents)}",
          style = MoreMoneyTextStyles.caption,
          color = colors.ink3,
          modifier = Modifier.weight(1f),
        )
        Text(
          text =
            if (hidden) "${if (overspent) "超支" else "剩余"} ¥••••"
            else "${if (overspent) "超支" else "剩余"} ${MoneyUtil.formatCents(if (overspent) -remaining else remaining)}",
          style = MoreMoneyTextStyles.caption,
          color = if (overspent) colors.expense else colors.good,
        )
      }
    } else {
      Box(
        modifier =
          Modifier
            .fillMaxWidth()
            .height(5.dp)
            .clip(RoundedCornerShape(Radius.pill))
            .dashedBorder(colors.line, Radius.pill, 1.dp),
      )
      Text(text = "还没有预算", style = MoreMoneyTextStyles.caption, color = colors.ink3)
    }
  }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun BookEditSheet(
  existing: BookEntity?,
  defaultColorIndex: Int,
  onDismiss: () -> Unit,
  onSave: (name: String, icon: String, color: String, isDefault: Boolean) -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  var name by remember(existing) { mutableStateOf(existing?.name.orEmpty()) }
  var icon by remember(existing) { mutableStateOf(existing?.icon ?: BookIconNames.first()) }
  var color by remember(existing) { mutableStateOf(existing?.color ?: SeedColors.at(defaultColorIndex)) }
  var isDefault by remember(existing) { mutableStateOf(existing?.isDefault ?: false) }

  AppBottomSheet(onDismiss = onDismiss) {
    SheetTitle(title = if (existing == null) "新建账本" else "编辑账本")
    AppTextField(value = name, onValueChange = { name = it.take(20) }, placeholder = "账本名称", height = 44)
    Text(text = "封面", style = MoreMoneyTextStyles.legend, color = colors.ink3)
    FlowRow(horizontalArrangement = Arrangement.spacedBy(Spacing.x3), verticalArrangement = Arrangement.spacedBy(Spacing.x3)) {
      BookIconNames.forEach { item ->
        val selected = icon == item
        Box(
          modifier =
            Modifier
              .size(48.dp)
              .clip(RoundedCornerShape(14.dp))
              .background(if (selected) colors.brandWash else colors.surface2)
              .border(1.dp, if (selected) colors.brandInk else colors.line, RoundedCornerShape(14.dp))
              .clickable { icon = item },
          contentAlignment = Alignment.Center,
        ) {
          Icon(
            painter = painterResource(iconResOf(item)),
            contentDescription = null,
            tint = if (selected) colors.brandInk else colors.ink2,
            modifier = Modifier.size(23.dp),
          )
        }
      }
    }
    Text(text = "颜色", style = MoreMoneyTextStyles.legend, color = colors.ink3)
    FlowRow(horizontalArrangement = Arrangement.spacedBy(Spacing.x3), verticalArrangement = Arrangement.spacedBy(Spacing.x3)) {
      SeedColors.all.forEach { item ->
        val selected = color == item
        Box(
          modifier =
            Modifier
              .size(30.dp)
              .clip(CircleShape)
              .background(parseColorOf(item))
              .border(if (selected) 3.dp else 0.dp, if (selected) colors.surface else colors.surface, CircleShape)
              .clickable { color = item },
          contentAlignment = Alignment.Center,
        ) {
          if (selected) {
            Icon(
              painter = painterResource(R.drawable.ic_check),
              contentDescription = null,
              tint = colors.buttonForeground,
              modifier = Modifier.size(15.dp),
            )
          }
        }
      }
    }
    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
      Column(modifier = Modifier.weight(1f)) {
        Text(text = "设为默认账本", style = MoreMoneyTextStyles.settingsTitle, color = colors.ink)
        Text(text = "默认账本全局唯一", style = MoreMoneyTextStyles.caption, color = colors.ink3)
      }
      AppSwitch(checked = isDefault, onCheckedChange = { isDefault = it })
    }
    PrimaryButton(
      text = "保存",
      enabled = name.trim().isNotEmpty(),
      onClick = { onSave(name.trim(), icon, color, isDefault) },
    )
  }
}

@Composable
private fun ActionRow(
  text: String,
  danger: Boolean = false,
  onClick: () -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  Row(
    modifier =
      Modifier
        .fillMaxWidth()
        .clip(RoundedCornerShape(Radius.chip))
        .background(colors.surface2)
        .clickable(onClick = onClick)
        .padding(vertical = 12.dp),
    horizontalArrangement = Arrangement.Center,
  ) {
    Text(
      text = text,
      style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.SemiBold),
      color = if (danger) colors.expense else colors.ink,
    )
  }
}
