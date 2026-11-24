package com.github.ppg007.moremoney.ui.add

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
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
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.github.ppg007.moremoney.R
import com.github.ppg007.moremoney.data.db.entity.BookEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryEntity
import com.github.ppg007.moremoney.ui.common.SystemBarAppearance
import com.github.ppg007.moremoney.ui.common.appViewModel
import com.github.ppg007.moremoney.ui.components.iconResOf
import com.github.ppg007.moremoney.ui.components.base.AppBottomSheet
import com.github.ppg007.moremoney.ui.components.base.AppDatePickerDialog
import com.github.ppg007.moremoney.ui.components.base.CategoryCircle
import com.github.ppg007.moremoney.ui.components.base.ConfirmDialog
import com.github.ppg007.moremoney.ui.components.base.SheetTitle
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.ui.theme.Spacing
import com.github.ppg007.moremoney.ui.theme.parseColorOf
import com.github.ppg007.moremoney.ui.theme.withAlpha
import com.github.ppg007.moremoney.util.DateUtil
import com.github.ppg007.moremoney.util.Operator

/**
 * 记一笔：分类、选择器、金额/备注/保存、计算器键盘。
 *
 * 支持 + − × ÷ 与先乘除后加减；保存即求值，无 C、无 =。
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun AddTxnScreen(
  bookId: String,
  dayKey: String,
  txnId: String,
  onBack: () -> Unit,
) {
  val viewModel: AddTxnViewModel = appViewModel { AddTxnViewModel(it, bookId, dayKey, txnId) }
  val state by viewModel.state.collectAsStateWithLifecycle()
  val colors = MoreMoneyTheme.colors
  var showBookPicker by remember { mutableStateOf(false) }
  var showDatePicker by remember { mutableStateOf(false) }
  var showNoteEditor by remember { mutableStateOf(false) }
  var showDiscard by remember { mutableStateOf(false) }
  var showDelete by remember { mutableStateOf(false) }

  SystemBarAppearance(darkIcons = true)

  fun requestClose() {
    if (viewModel.hasChanges()) {
      showDiscard = true
    } else {
      onBack()
    }
  }

  Column(modifier = Modifier.fillMaxSize().background(colors.background).navigationBarsPadding()) {
    Row(
      modifier =
        Modifier
          .fillMaxWidth()
          .statusBarsPadding()
          .height(48.dp)
          .padding(horizontal = 16.dp),
      verticalAlignment = Alignment.CenterVertically,
    ) {
      Box(
        modifier =
          Modifier
            .size(34.dp)
            .clip(RoundedCornerShape(Radius.pill))
            .background(colors.surface)
            .border(1.dp, colors.line, RoundedCornerShape(Radius.pill))
            .clickable { requestClose() },
        contentAlignment = Alignment.Center,
      ) {
        Icon(
          painter = painterResource(R.drawable.ic_close),
          contentDescription = stringResource(R.string.action_close),
          tint = colors.ink,
          modifier = Modifier.size(17.dp),
        )
      }
      Text(
        text = if (state.editing) "编辑一笔" else "记一笔",
        style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.Bold),
        color = colors.ink,
        textAlign = TextAlign.Center,
        modifier = Modifier.weight(1f),
      )
      if (state.editing) {
        Box(
          modifier =
            Modifier
              .size(34.dp)
              .clip(RoundedCornerShape(Radius.pill))
              .clickable { showDelete = true },
          contentAlignment = Alignment.Center,
        ) {
          Icon(
            painter = painterResource(R.drawable.ic_trash),
            contentDescription = "删除",
            tint = colors.expense,
            modifier = Modifier.size(17.dp),
          )
        }
      } else {
        Text(text = "仅支出", style = MoreMoneyTextStyles.caption, color = colors.ink3, modifier = Modifier.width(48.dp), textAlign = TextAlign.End)
      }
    }

    BoxWithConstraints(modifier = Modifier.weight(1f)) {
      // 横屏/折叠屏高度不足时，整页滚动；分类区不再挤压到 0 高。
      val compact = maxHeight < 520.dp
      val form: @Composable () -> Unit = {
        AddTxnForm(
          state = state,
          onBook = { showBookPicker = true },
          onDate = { showDatePicker = true },
          onNote = { showNoteEditor = true },
          onSave = { viewModel.save(onBack) },
          onDigit = viewModel::appendDigit,
          onOperator = viewModel::appendOperator,
          onBackspace = viewModel::backspace,
        )
      }
      if (compact) {
        Column(modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
          AddTxnCategoryList(
            state = state,
            onSelect = viewModel::selectCategory,
            modifier = Modifier.fillMaxWidth(),
            scrollable = false,
            columns = 8,
          )
          form()
          Spacer(Modifier.height(Spacing.x4))
        }
      } else {
        Column(modifier = Modifier.fillMaxSize()) {
          AddTxnCategoryList(
            state = state,
            onSelect = viewModel::selectCategory,
            modifier = Modifier.weight(1f),
            scrollable = true,
          )
          form()
        }
      }
    }
  }

  if (showBookPicker) {
    BookPickerSheet(
      books = state.books,
      selectedId = state.bookId,
      onSelect = {
        viewModel.selectBook(it.id)
        showBookPicker = false
      },
      onDismiss = { showBookPicker = false },
    )
  }

  if (showDatePicker) {
    AppDatePickerDialog(
      initial = DateUtil.parseDayKey(state.dayKey),
      // 日期禁止未来。
      maxDate = DateUtil.today(),
      onConfirm = { date ->
        viewModel.setDay(DateUtil.dayKey(date))
        showDatePicker = false
      },
      onDismiss = { showDatePicker = false },
    )
  }

  if (showNoteEditor) {
    var draft by remember(state.note) { mutableStateOf(state.note) }
    AppBottomSheet(onDismiss = { showNoteEditor = false }) {
      SheetTitle(title = "备注", subtitle = "最多 100 字")
      Box(
        modifier =
          Modifier
            .fillMaxWidth()
            .height(108.dp)
            .clip(RoundedCornerShape(13.dp))
            .background(colors.surface)
            .border(1.dp, colors.line, RoundedCornerShape(13.dp))
            .padding(10.dp),
      ) {
        BasicTextField(
          value = draft,
          onValueChange = { draft = it.take(100) },
          textStyle = MoreMoneyTextStyles.body.copy(color = colors.ink),
          cursorBrush = SolidColor(colors.brandInk),
          keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
          modifier = Modifier.fillMaxSize(),
        )
        if (draft.isEmpty()) {
          Text(text = "写点什么，例如：午餐", style = MoreMoneyTextStyles.body, color = colors.ink3)
        }
      }
      Row(horizontalArrangement = Arrangement.End, modifier = Modifier.fillMaxWidth()) {
        Text(
          text = "${draft.length}/100",
          style = MoreMoneyTextStyles.caption,
          color = colors.ink3,
        )
      }
      Box(
        modifier =
          Modifier
            .fillMaxWidth()
            .height(46.dp)
            .clip(RoundedCornerShape(Radius.button))
            .background(colors.buttonBackground)
            .clickable {
              viewModel.setNote(draft)
              showNoteEditor = false
            },
        contentAlignment = Alignment.Center,
      ) {
        Text(text = "完成", style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.Bold), color = colors.buttonForeground)
      }
    }
  }

  ConfirmDialog(
    visible = showDiscard,
    title = "放弃这次修改？",
    message = "返回后当前输入不会保存。",
    confirmLabel = "放弃",
    danger = true,
    onConfirm = {
      showDiscard = false
      onBack()
    },
    onDismiss = { showDiscard = false },
  )

  ConfirmDialog(
    visible = showDelete,
    title = "删除这笔记录？",
    message = "删除后 5 秒内可在列表底部撤销。",
    confirmLabel = "删除",
    danger = true,
    onConfirm = {
      showDelete = false
      viewModel.delete(onBack)
    },
    onDismiss = { showDelete = false },
  )
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun AddTxnCategoryList(
  state: AddTxnUiState,
  onSelect: (String) -> Unit,
  modifier: Modifier = Modifier,
  scrollable: Boolean,
  columns: Int = 4,
) {
  Column(
    modifier =
      modifier
        .then(if (scrollable) Modifier.verticalScroll(rememberScrollState()) else Modifier)
        .padding(horizontal = Spacing.page),
    verticalArrangement = Arrangement.spacedBy(Spacing.x2),
  ) {
    if (state.frequent.isNotEmpty()) {
      CategorySectionHeader(title = "常用", count = state.frequent.size)
      FlowRow(
        modifier = Modifier.fillMaxWidth(),
        maxItemsInEachRow = columns,
        horizontalArrangement = Arrangement.spacedBy(Spacing.x3),
        verticalArrangement = Arrangement.spacedBy(Spacing.x3),
      ) {
        state.frequent.forEach { category ->
          CategoryButton(
            category = category,
            selected = state.categoryId == category.id,
            onClick = { onSelect(category.id) },
            modifier = Modifier.weight(1f),
          )
        }
        repeat((columns - state.frequent.size % columns) % columns) {
          Spacer(Modifier.weight(1f))
        }
      }
    }
    state.groups.forEach { group ->
      val list = state.categoriesByGroup[group.id].orEmpty()
      if (list.isNotEmpty()) {
        CategorySectionHeader(title = group.name, count = list.size)
        FlowRow(
          modifier = Modifier.fillMaxWidth(),
          maxItemsInEachRow = columns,
          horizontalArrangement = Arrangement.spacedBy(Spacing.x3),
          verticalArrangement = Arrangement.spacedBy(Spacing.x3),
        ) {
          list.forEach { category ->
            CategoryButton(
              category = category,
              selected = state.categoryId == category.id,
              onClick = { onSelect(category.id) },
              modifier = Modifier.weight(1f),
            )
          }
          repeat((columns - list.size % columns) % columns) {
            Spacer(Modifier.weight(1f))
          }
        }
      }
    }
    Spacer(Modifier.height(Spacing.x4))
  }
}

@Composable
private fun AddTxnForm(
  state: AddTxnUiState,
  onBook: () -> Unit,
  onDate: () -> Unit,
  onNote: () -> Unit,
  onSave: () -> Unit,
  onDigit: (String) -> Unit,
  onOperator: (Operator) -> Unit,
  onBackspace: () -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  MetaRow(
    bookName = state.books.firstOrNull { it.id == state.bookId }?.name ?: "选择账本",
    dateText = DateUtil.formatShortDay(state.dayKey),
    note = state.note,
    onBook = onBook,
    onDate = onDate,
    onNote = onNote,
  )

  Row(
    modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.page).padding(top = Spacing.x3),
    verticalAlignment = Alignment.CenterVertically,
    horizontalArrangement = Arrangement.spacedBy(Spacing.x3),
  ) {
    Box(
      modifier = Modifier.weight(1f),
      contentAlignment = Alignment.CenterEnd,
    ) {
      Row(
        modifier = Modifier.horizontalScroll(rememberScrollState()),
        verticalAlignment = Alignment.CenterVertically,
      ) {
        Text(text = "¥", style = MoreMoneyTextStyles.amountInput, color = colors.ink)
        Text(
          text = state.expression.ifEmpty { "0" },
          style = MoreMoneyTextStyles.amountInput,
          color = colors.ink,
        )
      }
    }
    Box(
      modifier =
        Modifier
          .height(38.dp)
          .width(64.dp)
          .clip(RoundedCornerShape(11.dp))
          .background(if (state.canSave) colors.buttonBackground else colors.surface3)
          .testTag("save_txn")
          .clickable(enabled = state.canSave, onClick = onSave),
      contentAlignment = Alignment.Center,
    ) {
      Text(
        text = "保存",
        style = MoreMoneyTextStyles.settingsTitle.copy(fontWeight = FontWeight.Bold),
        color = if (state.canSave) colors.buttonForeground else colors.ink3,
      )
    }
  }
  Box(
    modifier =
      Modifier
        .fillMaxWidth()
        .padding(horizontal = Spacing.page)
        .heightIn(min = 20.dp),
    contentAlignment = Alignment.CenterStart,
  ) {
    if (state.expression.isNotEmpty()) {
      Text(
        text = state.previewText,
        style = MoreMoneyTextStyles.caption,
        color = if (state.previewValid) colors.ink3 else colors.expense,
      )
    }
  }

  CalcKeypad(
    onDigit = onDigit,
    onOperator = onOperator,
    onBackspace = onBackspace,
    modifier = Modifier.padding(horizontal = Spacing.page).padding(bottom = Spacing.x2),
  )
}

@Composable
private fun CategorySectionHeader(title: String, count: Int) {
  val colors = MoreMoneyTheme.colors
  Row(
    modifier = Modifier.fillMaxWidth().padding(top = Spacing.x2, bottom = 2.dp),
    verticalAlignment = Alignment.CenterVertically,
  ) {
    Text(
      text = title,
      style = MoreMoneyTextStyles.legend.copy(fontWeight = FontWeight.Bold),
      color = colors.ink,
      modifier = Modifier.weight(1f),
    )
    Text(text = count.toString(), style = MoreMoneyTextStyles.caption, color = colors.ink3)
  }
}

@Composable
private fun CategoryButton(
  category: CategoryEntity,
  selected: Boolean,
  onClick: () -> Unit,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  val color = parseColorOf(category.color)
  Column(
    modifier =
      modifier
        .heightIn(min = 78.dp)
        .clip(RoundedCornerShape(16.dp))
        .background(if (selected) colors.surface else androidx.compose.ui.graphics.Color.Transparent)
        .border(
          width = 1.dp,
          color = if (selected) colors.brandInk else androidx.compose.ui.graphics.Color.Transparent,
          shape = RoundedCornerShape(16.dp),
        )
        .clickable(onClick = onClick)
        .padding(vertical = 7.dp, horizontal = 2.dp),
    horizontalAlignment = Alignment.CenterHorizontally,
    verticalArrangement = Arrangement.spacedBy(4.dp),
  ) {
    Box(
      modifier =
        Modifier
          .size(52.dp)
          .clip(RoundedCornerShape(16.dp))
          .background(withAlpha(color, 0.13f))
          .then(if (selected) Modifier.border(2.dp, colors.brandSoft, RoundedCornerShape(16.dp)) else Modifier),
      contentAlignment = Alignment.Center,
    ) {
      Icon(
        painter = painterResource(iconResOf(category.icon)),
        contentDescription = null,
        tint = color,
        modifier = Modifier.size(26.dp),
      )
    }
    Text(
      text = category.name,
      style = MoreMoneyTextStyles.caption.copy(fontSize = 10.sp),
      color = if (selected) colors.brandInk else colors.ink,
      maxLines = 1,
      overflow = TextOverflow.Ellipsis,
    )
  }
}

@Composable
private fun MetaRow(
  bookName: String,
  dateText: String,
  note: String,
  onBook: () -> Unit,
  onDate: () -> Unit,
  onNote: () -> Unit,
) {
  Row(
    modifier = Modifier.fillMaxWidth().padding(horizontal = Spacing.page).padding(top = Spacing.x2),
    horizontalArrangement = Arrangement.spacedBy(Spacing.x2),
  ) {
    SelectorCell(value = bookName, onClick = onBook, modifier = Modifier.weight(1f))
    SelectorCell(value = dateText, onClick = onDate, modifier = Modifier.weight(1f))
    NoteCell(note = note, onClick = onNote, modifier = Modifier.weight(1f))
  }
}

@Composable
private fun SelectorCell(
  value: String,
  onClick: () -> Unit,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  Row(
    modifier =
      modifier
        .height(36.dp)
        .clip(RoundedCornerShape(Radius.input))
        .background(colors.surface)
        .border(1.dp, colors.line, RoundedCornerShape(Radius.input))
        .clickable(onClick = onClick)
        .padding(horizontal = 8.dp),
    verticalAlignment = Alignment.CenterVertically,
    horizontalArrangement = Arrangement.spacedBy(4.dp),
  ) {
    Text(
      text = value,
      style = MoreMoneyTextStyles.caption.copy(fontWeight = FontWeight.SemiBold),
      color = colors.ink,
      maxLines = 1,
      overflow = TextOverflow.Ellipsis,
      modifier = Modifier.weight(1f),
    )
    Icon(
      painter = painterResource(R.drawable.ic_chevron_right),
      contentDescription = null,
      tint = colors.ink3,
      modifier = Modifier.size(11.dp),
    )
  }
}

/** 备注输入入口；保留“备注”占位标签。 */
@Composable
private fun NoteCell(
  note: String,
  onClick: () -> Unit,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  Box(
    modifier =
      modifier
        .height(36.dp)
        .clip(RoundedCornerShape(Radius.input))
        .background(colors.surface)
        .border(1.dp, colors.line, RoundedCornerShape(Radius.input))
        .clickable(onClick = onClick)
        .padding(horizontal = 8.dp),
    contentAlignment = Alignment.CenterStart,
  ) {
    Text(
      text = note.ifEmpty { "备注" },
      style = MoreMoneyTextStyles.caption,
      color = if (note.isEmpty()) colors.ink3 else colors.ink,
      maxLines = 1,
      overflow = TextOverflow.Ellipsis,
    )
  }
}

/** 计算器键盘：4×4 方格；数字为圆角方形，运算符与退格为圆形。 */
@Composable
private fun CalcKeypad(
  onDigit: (String) -> Unit,
  onOperator: (Operator) -> Unit,
  onBackspace: () -> Unit,
  modifier: Modifier = Modifier,
) {
  val gap = 8.dp
  val operators =
    listOf(
      "+" to Operator.PLUS,
      "−" to Operator.MINUS,
      "×" to Operator.MULTIPLY,
      "÷" to Operator.DIVIDE,
    )
  val digitRows =
    listOf(
      listOf("7", "8", "9"),
      listOf("4", "5", "6"),
      listOf("1", "2", "3"),
      listOf(".", "0"),
    )

  BoxWithConstraints(
    modifier = modifier.fillMaxWidth(),
    contentAlignment = Alignment.Center,
  ) {
    // 键盘铺满宽度；高度锁定为 72dp，避免 4×4 方格把下半区撑得过高。
    val keyHeight = minOf((maxWidth - gap * 3) / 4, 72.dp)
    Column(verticalArrangement = Arrangement.spacedBy(gap)) {
      digitRows.forEachIndexed { index, digits ->
        Row(
          modifier = Modifier.fillMaxWidth(),
          horizontalArrangement = Arrangement.spacedBy(gap),
        ) {
          val (label, operator) = operators[index]
          CalcOperatorKey(
            label = label,
            keyHeight = keyHeight,
            modifier = Modifier.weight(1f),
          ) { onOperator(operator) }
          digits.forEach { digit ->
            CalcDigitKey(
              label = digit,
              keyHeight = keyHeight,
              modifier = Modifier.weight(1f),
            ) { onDigit(digit) }
          }
          if (index == digitRows.lastIndex) {
            CalcBackspaceKey(
              keyHeight = keyHeight,
              modifier = Modifier.weight(1f),
              onClick = onBackspace,
            )
          }
        }
      }
    }
  }
}

@Composable
private fun CalcDigitKey(
  label: String,
  keyHeight: Dp,
  modifier: Modifier = Modifier,
  onClick: () -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  val shape = RoundedCornerShape(keyHeight * 0.25f)
  Box(
    modifier =
      modifier
        .height(keyHeight)
        .clip(shape)
        .background(colors.surface)
        .border(1.dp, colors.line, shape)
        .testTag("key_$label")
        .clickable(onClick = onClick),
    contentAlignment = Alignment.Center,
  ) {
    Text(
      text = label,
      style = MoreMoneyTextStyles.subTitle.copy(fontWeight = FontWeight.SemiBold, fontSize = 22.sp),
      color = colors.ink,
    )
  }
}

@Composable
private fun CalcOperatorKey(
  label: String,
  keyHeight: Dp,
  modifier: Modifier = Modifier,
  onClick: () -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  Box(
    modifier = modifier.height(keyHeight),
    contentAlignment = Alignment.Center,
  ) {
    Box(
      modifier =
        Modifier
          .fillMaxHeight()
          .aspectRatio(1f)
          .clip(CircleShape)
          .background(colors.brandWash)
          .border(1.dp, colors.brandSoft, CircleShape)
          .testTag("key_$label")
          .clickable(onClick = onClick),
      contentAlignment = Alignment.Center,
    ) {
      Text(
        text = label,
        style = MoreMoneyTextStyles.subTitle.copy(fontWeight = FontWeight.SemiBold, fontSize = 24.sp),
        color = colors.brandInk,
      )
    }
  }
}

@Composable
private fun CalcBackspaceKey(
  keyHeight: Dp,
  modifier: Modifier = Modifier,
  onClick: () -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  Box(
    modifier = modifier.height(keyHeight),
    contentAlignment = Alignment.Center,
  ) {
    Box(
      modifier =
        Modifier
          .fillMaxHeight()
          .aspectRatio(1f)
          .clip(CircleShape)
          .background(colors.surface2)
          .testTag("key_backspace")
          .clickable(onClick = onClick),
      contentAlignment = Alignment.Center,
    ) {
      Icon(
        painter = painterResource(R.drawable.ic_backspace),
        contentDescription = "退格",
        tint = colors.ink2,
        modifier = Modifier.size(25.dp),
      )
    }
  }
}

@Composable
private fun BookPickerSheet(
  books: List<BookEntity>,
  selectedId: String,
  onSelect: (BookEntity) -> Unit,
  onDismiss: () -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  AppBottomSheet(onDismiss = onDismiss) {
    SheetTitle(title = "选择账本")
    books.forEach { book ->
      val color = parseColorOf(book.color)
      Row(
        modifier =
          Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Radius.chip))
            .background(if (book.id == selectedId) colors.brandWash else colors.surface)
            .clickable { onSelect(book) }
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
      ) {
        Box(
          modifier =
            Modifier
              .size(30.dp)
              .clip(RoundedCornerShape(10.dp))
              .background(withAlpha(color, 0.16f)),
          contentAlignment = Alignment.Center,
        ) {
          Icon(
            painter = painterResource(iconResOf(book.icon)),
            contentDescription = null,
            tint = color,
            modifier = Modifier.size(16.dp),
          )
        }
        Text(
          text = book.name,
          style = MoreMoneyTextStyles.settingsTitle,
          color = colors.ink,
          modifier = Modifier.weight(1f),
        )
        if (book.id == selectedId) {
          Icon(
            painter = painterResource(R.drawable.ic_check),
            contentDescription = null,
            tint = colors.brandInk,
            modifier = Modifier.size(16.dp),
          )
        }
      }
    }
  }
}
