package com.github.ppg007.moremoney.ui.add

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.github.ppg007.moremoney.AppContainer
import com.github.ppg007.moremoney.data.db.entity.BookEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryEntity
import com.github.ppg007.moremoney.data.db.entity.CategoryGroupEntity
import com.github.ppg007.moremoney.data.db.entity.TxnEntity
import com.github.ppg007.moremoney.util.CalcEngine
import com.github.ppg007.moremoney.util.CalcError
import com.github.ppg007.moremoney.util.DateUtil
import com.github.ppg007.moremoney.util.ErrorUtil
import com.github.ppg007.moremoney.util.IdUtil
import com.github.ppg007.moremoney.util.MoneyUtil
import com.github.ppg007.moremoney.util.Operator
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.time.LocalTime

data class AddTxnUiState(
  val loading: Boolean = true,
  val books: List<BookEntity> = emptyList(),
  val groups: List<CategoryGroupEntity> = emptyList(),
  val categoriesByGroup: Map<String, List<CategoryEntity>> = emptyMap(),
  val frequent: List<CategoryEntity> = emptyList(),
  val bookId: String = "",
  val categoryId: String = "",
  val dayKey: String = DateUtil.nowDayKey(),
  val expression: String = "",
  val note: String = "",
  val previewText: String = "请输入金额",
  val previewValid: Boolean = false,
  val editing: Boolean = false,
) {
  val canSave: Boolean
    get() = previewValid && bookId.isNotEmpty() && categoryId.isNotEmpty()
}

/**
 * 记一笔：新增/编辑支出，金额表达式、分类、账本、日期、备注与删除。
 *
 * 默认账本优先级：路由参数 > 设置 > 数据库默认。
 */
class AddTxnViewModel(
  private val container: AppContainer,
  private val routeBookId: String,
  private val routeDayKey: String,
  private val txnId: String,
) : ViewModel() {
  private val engine = CalcEngine()
  private val _state = MutableStateFlow(AddTxnUiState())
  val state: StateFlow<AddTxnUiState> = _state.asStateFlow()

  private var initialSnapshot: AddTxnUiState? = null
  private var existing: TxnEntity? = null

  init {
    load()
  }

  private fun load() {
    viewModelScope.launch {
      try {
        val books = container.bookRepository.list().filter { !it.archived }
        val groups = container.categoryRepository.listGroups()
        val categories = container.categoryRepository.list()
        val categoriesByGroup = groups.associate { group ->
          group.id to categories.filter { it.groupId == group.id && !it.archived }
        }
        val since = System.currentTimeMillis() - 30L * 24 * 60 * 60 * 1000
        val frequent = container.categoryRepository.listFrequent(8, since).filter { !it.archived }

        existing = if (txnId.isNotEmpty()) container.txnRepository.get(txnId) else null
        val editing = existing
        val saved = existing

        val bookId =
          when {
            saved != null -> saved.bookId
            routeBookId.isNotEmpty() && books.any { it.id == routeBookId } -> routeBookId
            container.settings.defaultBookId() in books.map { it.id } -> container.settings.defaultBookId()
            else -> books.firstOrNull { it.isDefault }?.id ?: books.firstOrNull()?.id.orEmpty()
          }
        val categoryId =
          saved?.categoryId
            ?: frequent.firstOrNull()?.id
            ?: categories.firstOrNull()?.id
            ?: ""
        val dayKey = saved?.dayKey ?: routeDayKey.ifBlank { DateUtil.nowDayKey() }
        val expression = saved?.let { MoneyUtil.formatYuan(it.amountCents) } ?: ""
        val note = saved?.note ?: ""
        engine.setExpression(expression)
        val preview = engine.preview()

        val next =
          AddTxnUiState(
            loading = false,
            books = books,
            groups = groups,
            categoriesByGroup = categoriesByGroup,
            frequent = frequent,
            bookId = bookId,
            categoryId = categoryId,
            dayKey = dayKey,
            expression = expression,
            note = note,
            previewText = preview.text,
            previewValid = preview.valid,
            editing = editing != null,
          )
        _state.value = next
        initialSnapshot = next
      } catch (error: Exception) {
        _state.value = _state.value.copy(loading = false)
        container.ui.showSnack("加载失败：${ErrorUtil.messageOf(error)}")
      }
    }
  }

  fun appendDigit(d: String) {
    // 未输入金额时忽略 0，避免出现 “0”“000” 这类没有意义的前导 0。
    if (engine.expression.isEmpty() && d.isNotEmpty() && d.all { it == '0' }) {
      return
    }
    engine.appendDigit(d)
    refreshExpression()
  }

  fun appendOperator(op: Operator) {
    engine.appendOperator(op)
    refreshExpression()
  }

  fun backspace() {
    engine.backspace()
    refreshExpression()
  }

  fun clearAmount() {
    engine.clear()
    refreshExpression()
  }

  private fun refreshExpression() {
    val preview = engine.preview()
    _state.value =
      _state.value.copy(
        expression = engine.expression,
        previewText = preview.text,
        previewValid = preview.valid,
      )
  }

  fun selectCategory(id: String) {
    _state.value = _state.value.copy(categoryId = id)
  }

  fun selectBook(id: String) {
    _state.value = _state.value.copy(bookId = id)
  }

  fun setDay(dayKey: String) {
    _state.value = _state.value.copy(dayKey = dayKey)
  }

  fun setNote(note: String) {
    _state.value = _state.value.copy(note = note.take(100))
  }

  fun hasChanges(): Boolean {
    val initial = initialSnapshot ?: return false
    val current = _state.value
    return current.bookId != initial.bookId ||
      current.categoryId != initial.categoryId ||
      current.dayKey != initial.dayKey ||
      current.expression != initial.expression ||
      current.note != initial.note
  }

  fun save(onDone: () -> Unit) {
    val current = _state.value
    val result = engine.evaluate()
    if (!result.ok) {
      container.ui.showSnack(current.previewText)
      return
    }
    if (current.bookId.isEmpty() || current.categoryId.isEmpty()) {
      container.ui.showSnack("请选择账本和分类")
      return
    }
    viewModelScope.launch {
      try {
        val now = System.currentTimeMillis()
        val saved = existing
        val occurredAt =
          if (saved != null) {
            val time = DateUtil.toLocalDateTime(saved.occurredAt).toLocalTime()
            DateUtil.parseDayKey(current.dayKey).atTime(time).atZone(DateUtil.zone()).toInstant().toEpochMilli()
          } else {
            DateUtil.parseDayKey(current.dayKey).atTime(LocalTime.now())
              .atZone(DateUtil.zone()).toInstant().toEpochMilli()
          }
        val txn =
          TxnEntity(
            id = saved?.id ?: IdUtil.next(),
            bookId = current.bookId,
            categoryId = current.categoryId,
            amountCents = result.cents,
            occurredAt = occurredAt,
            dayKey = current.dayKey,
            note = current.note.trim(),
            createdAt = saved?.createdAt ?: now,
            updatedAt = now,
            deletedAt = null,
          )
        if (saved == null) {
          container.txnRepository.insert(txn)
        } else {
          container.txnRepository.update(txn)
        }
        container.ui.notifyTxnSaved(txn.bookId, txn.dayKey)
        onDone()
      } catch (error: Exception) {
        container.ui.showSnack("保存失败：${ErrorUtil.messageOf(error)}")
      }
    }
  }

  fun delete(onDone: () -> Unit) {
    val saved = existing ?: return
    viewModelScope.launch {
      try {
        container.deleteService.deleteTxn(saved.id)
        container.ui.showSnack("已删除 1 笔", "撤销", 5000) {
          viewModelScope.launch {
            runCatching { container.deleteService.undoDelete(saved.id) }
          }
        }
        onDone()
      } catch (error: Exception) {
        container.ui.showSnack("删除失败：${ErrorUtil.messageOf(error)}")
      }
    }
  }

  fun previewError(): CalcError = engine.evaluate().error
}
