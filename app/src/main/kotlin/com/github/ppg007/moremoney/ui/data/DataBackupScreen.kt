package com.github.ppg007.moremoney.ui.data

import android.content.Context
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.github.ppg007.moremoney.R
import com.github.ppg007.moremoney.appContainer
import com.github.ppg007.moremoney.models.PeriodRange
import com.github.ppg007.moremoney.models.PeriodType
import com.github.ppg007.moremoney.models.TxnFilter
import com.github.ppg007.moremoney.service.BackupExport
import com.github.ppg007.moremoney.service.BackupFormat
import com.github.ppg007.moremoney.service.CsvFormat
import com.github.ppg007.moremoney.service.ImportPreview
import com.github.ppg007.moremoney.service.PeriodResolver
import com.github.ppg007.moremoney.service.RestoreSummary
import com.github.ppg007.moremoney.ui.common.SystemBarAppearance
import com.github.ppg007.moremoney.ui.components.base.AppBottomSheet
import com.github.ppg007.moremoney.ui.components.base.AppDatePickerDialog
import com.github.ppg007.moremoney.ui.components.base.CardColumn
import com.github.ppg007.moremoney.ui.components.base.DividerLine
import com.github.ppg007.moremoney.ui.components.base.ListRow
import com.github.ppg007.moremoney.ui.components.base.PrimaryButton
import com.github.ppg007.moremoney.ui.components.base.SecondaryButton
import com.github.ppg007.moremoney.ui.components.base.SheetTitle
import com.github.ppg007.moremoney.ui.components.layout.PageHeader
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.ui.theme.Spacing
import com.github.ppg007.moremoney.util.DateUtil
import com.github.ppg007.moremoney.util.ErrorUtil
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * 数据与备份：
 * - 备份 `MOREMONEY_BACKUP` v1（只含普通账本）；
 * - 恢复前预览，包含跳过私密账本的提示；
 * - CSV 导入导出通过 SAF，不申请存储权限。
 */
@Composable
fun DataBackupScreen(onBack: () -> Unit) {
  val container = LocalContext.current.appContainer
  val context = LocalContext.current
  val scope = rememberCoroutineScope()
  val colors = MoreMoneyTheme.colors
  val settings by container.settings.state.collectAsStateWithLifecycle()
  val books by container.bookRepository.observeAll().collectAsStateWithLifecycle(emptyList())
  val categories by container.categoryRepository.observeAll().collectAsStateWithLifecycle(emptyList())
  val txns by container.txnRepository.observeActive().collectAsStateWithLifecycle(emptyList())

  var pendingBackup by remember { mutableStateOf<BackupExport?>(null) }
  var pendingCsvText by remember { mutableStateOf("") }
  var pendingCsvName by remember { mutableStateOf("") }
  var showExportFilter by remember { mutableStateOf(false) }
  var importPreview by remember { mutableStateOf<ImportPreview?>(null) }
  var restoreSummary by remember { mutableStateOf<RestoreSummary?>(null) }
  var pendingRestoreText by remember { mutableStateOf("") }
  var showTemplate by remember { mutableStateOf(false) }

  SystemBarAppearance()

  val backupLauncher =
    rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/octet-stream")) { uri ->
      val export = pendingBackup
      if (uri != null && export != null) {
        scope.launch {
          try {
            writeText(context, uri, export.text)
            container.backupService.markExported(export)
            container.ui.showSnack("已备份 ${export.txns} 笔流水")
          } catch (error: Exception) {
            container.ui.showSnack("备份失败：${ErrorUtil.messageOf(error)}")
          } finally {
            pendingBackup = null
          }
        }
      }
    }

  val csvLauncher =
    rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("text/csv")) { uri ->
      if (uri != null && pendingCsvText.isNotEmpty()) {
        val text = pendingCsvText
        val name = pendingCsvName
        scope.launch {
          try {
            writeText(context, uri, text)
            container.ui.showSnack("已导出 $name")
          } catch (error: Exception) {
            container.ui.showSnack("导出失败：${ErrorUtil.messageOf(error)}")
          } finally {
            pendingCsvText = ""
          }
        }
      }
    }

  val csvImportLauncher =
    rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
      if (uri != null) {
        scope.launch {
          try {
            val text = readText(context, uri) ?: throw IllegalStateException("文件超过 5MB 上限或无法读取")
            importPreview = container.csvImportService.preview(text)
          } catch (error: Exception) {
            container.ui.showSnack("读取失败：${ErrorUtil.messageOf(error)}")
          }
        }
      }
    }

  val restoreLauncher =
    rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
      if (uri != null) {
        scope.launch {
          try {
            val text = readText(context, uri, 20 * 1024 * 1024)
              ?: throw IllegalStateException("备份文件无法读取")
            val doc = container.backupService.parseAndVerify(text)
            pendingRestoreText = text
            restoreSummary = container.backupService.summary(doc)
          } catch (error: Exception) {
            container.ui.showSnack("恢复失败：${ErrorUtil.messageOf(error)}")
          }
        }
      }
    }

  Column(modifier = Modifier.fillMaxSize().background(colors.background).navigationBarsPadding()) {
    PageHeader(title = "数据与备份", onBack = onBack)

    Column(
      modifier = Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = Spacing.page),
      verticalArrangement = Arrangement.spacedBy(Spacing.x4),
    ) {
      Column(
        modifier =
          Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(22.dp))
            .background(colors.surface)
            .border(1.dp, colors.line, RoundedCornerShape(22.dp))
            .padding(15.dp),
        verticalArrangement = Arrangement.spacedBy(Spacing.x3),
      ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
          Box(
            modifier =
              Modifier
                .size(41.dp)
                .clip(RoundedCornerShape(13.dp))
                .background(colors.brandWash),
            contentAlignment = Alignment.Center,
          ) {
            Icon(
              painter = painterResource(R.drawable.ic_cloud),
              contentDescription = null,
              tint = colors.brandInk,
              modifier = Modifier.size(21.dp),
            )
          }
          Column(modifier = Modifier.weight(1f)) {
            Text(text = "本地备份", style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.Bold), color = colors.ink)
            Text(
              text =
                if (settings.lastBackupAt > 0) {
                  "上次备份：${DateUtil.formatShortDateTime(settings.lastBackupAt)}"
                } else {
                  "还没有备份"
                },
              style = MoreMoneyTextStyles.caption,
              color = colors.ink3,
            )
            if (settings.lastBackupName.isNotEmpty()) {
              Text(text = settings.lastBackupName, style = MoreMoneyTextStyles.caption, color = colors.ink3)
            }
          }
        }
        Text(
          text = "备份包含普通账本、分类、预算与流水；不包含私密账本，也不会上传到网络。",
          style = MoreMoneyTextStyles.caption,
          color = colors.ink3,
        )
        PrimaryButton(
          text = "立即备份",
          onClick = {
            scope.launch {
              try {
                val export = container.backupService.buildExport()
                pendingBackup = export
                backupLauncher.launch(export.fileName)
              } catch (error: Exception) {
                container.ui.showSnack("备份失败：${ErrorUtil.messageOf(error)}")
              }
            }
          },
        )
        SecondaryButton(
          text = "从备份恢复",
          onClick = { restoreLauncher.launch(arrayOf("*/*")) },
        )
      }

      CardColumn {
        ListRow(
          title = "导出 CSV",
          subtitle = "按日期、账本筛选导出",
          iconRes = R.drawable.ic_file,
          onClick = { showExportFilter = true },
          trailing = { Chevron() },
        )
        DividerLine()
        ListRow(
          title = "导入 CSV",
          subtitle = "选择文件、预览校验后导入",
          iconRes = R.drawable.ic_file,
          // 部分文件管理器把 .csv 报成 application/octet-stream；放开类型，由服务校验表头。
          onClick = { csvImportLauncher.launch(arrayOf("*/*")) },
          trailing = { Chevron() },
        )
        DividerLine()
        ListRow(
          title = "CSV 模板与校验",
          subtitle = "固定 10 列、UTF-8 BOM、CRLF",
          iconRes = R.drawable.ic_warning,
          onClick = { showTemplate = true },
          trailing = { Chevron() },
        )
      }

      Column(
        modifier =
          Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Radius.card))
            .background(colors.surface)
            .border(1.dp, colors.line, RoundedCornerShape(Radius.card))
            .padding(13.dp),
        verticalArrangement = Arrangement.spacedBy(Spacing.x2),
      ) {
        Text(text = "数据统计", style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.Bold), color = colors.ink)
        StatLine("账本", "${books.count { !it.archived }} 个")
        StatLine("分类", "${categories.count { !it.archived }} 个")
        StatLine("流水", "${txns.size} 笔")
      }

      Text(
        text = "完全离线：不申请网络权限，数据仅保存在本机。恢复会覆盖当前业务数据，必须二次确认；包含私密账本的旧备份会跳过私密账本与 PRIVATE 段。",
        style = MoreMoneyTextStyles.caption,
        color = colors.ink3,
        modifier = Modifier.padding(bottom = 120.dp),
      )
    }
  }

  if (showExportFilter) {
    ExportFilterSheet(
      books = books.filter { !it.archived }.map { it.id to it.name },
      onDismiss = { showExportFilter = false },
      onConfirm = { filter ->
        showExportFilter = false
        scope.launch {
          try {
            val rows = container.csvExportService.prepareRows(filter)
            if (rows.isEmpty()) {
              container.ui.showSnack("没有可导出的记录")
            } else {
              pendingCsvText = CsvFormat.build(rows)
              pendingCsvName = CsvFormat.fileName(System.currentTimeMillis())
              csvLauncher.launch(pendingCsvName)
            }
          } catch (error: Exception) {
            container.ui.showSnack("导出失败：${ErrorUtil.messageOf(error)}")
          }
        }
      },
    )
  }

  importPreview?.let { preview ->
    ImportPreviewSheet(
      preview = preview,
      onDismiss = { importPreview = null },
      onConfirm = {
        scope.launch {
          try {
            val result = container.csvImportService.execute(preview)
            container.ui.showSnack("已导入 ${result.inserted} 笔，跳过重复 ${result.skipped} 笔")
            importPreview = null
          } catch (error: Exception) {
            container.ui.showSnack("导入失败：${ErrorUtil.messageOf(error)}")
          }
        }
      },
    )
  }

  restoreSummary?.let { summary ->
    RestorePreviewSheet(
      summary = summary,
      onDismiss = {
        restoreSummary = null
        pendingRestoreText = ""
      },
      onConfirm = {
        scope.launch {
          try {
            val doc = container.backupService.parseAndVerify(pendingRestoreText)
            val result = container.backupService.restore(doc)
            container.ui.showSnack(
              "已恢复 ${result.insertedTxns} 笔流水" +
                if (result.skippedPrivateBooks > 0) "，跳过 ${result.skippedPrivateBooks} 个私密账本" else ""
            )
            restoreSummary = null
            pendingRestoreText = ""
          } catch (error: Exception) {
            container.ui.showSnack("恢复失败：${ErrorUtil.messageOf(error)}")
          }
        }
      },
    )
  }

  if (showTemplate) {
    AlertDialog(
      onDismissRequest = { showTemplate = false },
      containerColor = colors.surface,
      shape = RoundedCornerShape(Radius.card),
      title = { Text(text = "CSV 模板", style = MoreMoneyTextStyles.subTitle, color = colors.ink) },
      text = {
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
          Text(text = CsvFormat.HEADER, style = MoreMoneyTextStyles.caption, color = colors.ink2)
          Text(
            text = "2026-11-09,12:30,expense,日常账本,餐饮,餐饮,自己,32.00,午餐,uuid",
            style = MoreMoneyTextStyles.caption,
            color = colors.ink3,
          )
          Text(
            text = "· UTF-8 BOM、CRLF\n· 金额两位小数，无千分位\n· type 固定 expense\n· 备注以 = + - @ 开头会自动加 ' 转义",
            style = MoreMoneyTextStyles.caption,
            color = colors.ink3,
          )
        }
      },
      confirmButton = {
        TextButton(onClick = { showTemplate = false }) {
          Text(text = "知道了", style = MoreMoneyTextStyles.row, color = colors.brandInk)
        }
      },
    )
  }
}

@Composable
private fun StatLine(label: String, value: String) {
  val colors = MoreMoneyTheme.colors
  Row(modifier = Modifier.fillMaxWidth()) {
    Text(text = label, style = MoreMoneyTextStyles.caption, color = colors.ink3, modifier = Modifier.weight(1f))
    Text(text = value, style = MoreMoneyTextStyles.settingsTitle, color = colors.ink)
  }
}

@Composable
private fun Chevron() {
  Icon(
    painter = painterResource(R.drawable.ic_chevron_right),
    contentDescription = null,
    tint = MoreMoneyTheme.colors.ink3,
    modifier = Modifier.size(14.dp),
  )
}

@Composable
private fun ExportFilterSheet(
  books: List<Pair<String, String>>,
  onDismiss: () -> Unit,
  onConfirm: (TxnFilter) -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  var periodIndex by remember { mutableStateOf(0) }
  var bookId by remember { mutableStateOf("") }
  var customStart by remember { mutableStateOf(DateUtil.nowDayKey()) }
  var customEnd by remember { mutableStateOf(DateUtil.nowDayKey()) }
  var showStartPicker by remember { mutableStateOf(false) }
  var showEndPicker by remember { mutableStateOf(false) }

  fun rangeOf(): PeriodRange =
    when (periodIndex) {
      1 -> {
        val prev = DateUtil.addMonths(DateUtil.monthKey(DateUtil.today()), -1)
        val range = DateUtil.rangeOfMonth(prev)
        PeriodRange(range.startMs, range.endMs, DateUtil.formatMonthCn(prev))
      }
      2 -> PeriodResolver.resolve(PeriodType.YEAR, java.time.Instant.now(), 1)
      3 -> PeriodRange(0, System.currentTimeMillis(), "全部")
      4 -> PeriodResolver.custom(customStart, customEnd)
      else -> PeriodResolver.resolve(PeriodType.MONTH, java.time.Instant.now(), 1)
    }

  AppBottomSheet(onDismiss = onDismiss) {
    SheetTitle(title = "导出 CSV", subtitle = "选择日期范围与账本")
    Row(
      modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
      horizontalArrangement = Arrangement.spacedBy(Spacing.x2),
    ) {
      listOf("本月", "上月", "今年", "全部", "自定义").forEachIndexed { index, label ->
        Text(
          text = label,
          style = MoreMoneyTextStyles.caption.copy(fontWeight = if (periodIndex == index) FontWeight.SemiBold else FontWeight.Normal),
          color = if (periodIndex == index) colors.brandInk else colors.ink2,
          modifier =
            Modifier
              .clip(RoundedCornerShape(Radius.pill))
              .background(if (periodIndex == index) colors.brandWash else colors.surface2)
              .border(1.dp, if (periodIndex == index) colors.brandSoft else colors.line, RoundedCornerShape(Radius.pill))
              .clickable {
                periodIndex = index
                if (index == 4) {
                  showStartPicker = true
                }
              }
              .padding(horizontal = 10.dp, vertical = 5.dp),
        )
      }
    }
    if (periodIndex == 4) {
      Text(
        text = "$customStart 至 $customEnd",
        style = MoreMoneyTextStyles.caption,
        color = colors.ink3,
      )
    }
    Text(text = "账本", style = MoreMoneyTextStyles.legend, color = colors.ink3)
    Row(modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(Spacing.x2)) {
      FilterChip("全部账本", bookId.isEmpty()) { bookId = "" }
      books.forEach { (id, name) -> FilterChip(name, bookId == id) { bookId = id } }
    }
    PrimaryButton(
      text = "选择保存位置",
      onClick = {
        val range = rangeOf()
        onConfirm(
          TxnFilter(
            bookIds = if (bookId.isEmpty()) emptyList() else listOf(bookId),
            startMs = range.startMs,
            endMs = range.endMs,
          )
        )
      },
    )
  }

  if (showStartPicker) {
    AppDatePickerDialog(
      initial = DateUtil.parseDayKey(customStart),
      title = "选择开始日期",
      onConfirm = { start ->
        customStart = DateUtil.dayKey(start)
        showStartPicker = false
        showEndPicker = true
      },
      onDismiss = { showStartPicker = false },
    )
  }

  if (showEndPicker) {
    AppDatePickerDialog(
      initial = DateUtil.parseDayKey(customEnd),
      title = "选择结束日期",
      onConfirm = { end ->
        customEnd = DateUtil.dayKey(end)
        showEndPicker = false
      },
      onDismiss = { showEndPicker = false },
    )
  }
}

@Composable
private fun FilterChip(text: String, selected: Boolean, onClick: () -> Unit) {
  val colors = MoreMoneyTheme.colors
  Text(
    text = text,
    style = MoreMoneyTextStyles.caption.copy(fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal),
    color = if (selected) colors.brandInk else colors.ink2,
    modifier =
      Modifier
        .clip(RoundedCornerShape(Radius.pill))
        .background(if (selected) colors.brandWash else colors.surface2)
        .border(1.dp, if (selected) colors.brandSoft else colors.line, RoundedCornerShape(Radius.pill))
        .clickable(onClick = onClick)
        .padding(horizontal = 10.dp, vertical = 5.dp),
  )
}

@Composable
private fun ImportPreviewSheet(
  preview: ImportPreview,
  onDismiss: () -> Unit,
  onConfirm: () -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  AppBottomSheet(onDismiss = onDismiss) {
    SheetTitle(title = "导入预览", subtitle = if (preview.hasErrors) "存在错误，无法导入" else "校验通过")
    PreviewLine("总行数", preview.total.toString())
    PreviewLine("可导入", preview.toInsert.toString())
    PreviewLine("重复跳过", preview.duplicates.toString())
    if (preview.newBooks.isNotEmpty()) {
      PreviewLine("新增账本", preview.newBooks.joinToString("、"))
    }
    if (preview.newCategories.isNotEmpty()) {
      PreviewLine("新增分类", preview.newCategories.joinToString("、"))
    }
    if (preview.hasErrors) {
      Text(
        text = "错误（最多显示 8 条）",
        style = MoreMoneyTextStyles.caption.copy(fontWeight = FontWeight.Bold),
        color = colors.expense,
      )
      preview.errors.take(8).forEach { error ->
        Text(
          text = "第 ${error.line} 行：${error.message}",
          style = MoreMoneyTextStyles.caption,
          color = colors.expense,
        )
      }
      if (preview.errors.size > 8) {
        Text(text = "还有 ${preview.errors.size - 8} 条错误", style = MoreMoneyTextStyles.caption, color = colors.expense)
      }
    }
    PrimaryButton(
      text = if (preview.hasErrors) "请先修复错误" else "确认导入",
      enabled = !preview.hasErrors && preview.toInsert > 0,
      onClick = onConfirm,
    )
  }
}

@Composable
private fun RestorePreviewSheet(
  summary: RestoreSummary,
  onDismiss: () -> Unit,
  onConfirm: () -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  AppBottomSheet(onDismiss = onDismiss) {
    SheetTitle(title = "恢复预览", subtitle = "恢复会覆盖当前业务数据")
    PreviewLine("备份时间", if (summary.createdAt > 0) DateUtil.formatShortDateTime(summary.createdAt) else "未知")
    PreviewLine("账本", summary.books.toString())
    PreviewLine("分类", summary.categories.toString())
    PreviewLine("流水", summary.txns.toString())
    PreviewLine("预算", summary.budgets.toString())
    if (summary.hasSkippedPrivate) {
      Text(
        text =
          "该备份包含私密账本：将跳过 ${summary.skippedPrivateBooks} 个私密账本" +
            if (summary.skippedPrivateRows > 0) "与 ${summary.skippedPrivateRows} 个 PRIVATE 段" else "",
        style = MoreMoneyTextStyles.caption,
        color = colors.warn,
      )
    }
    Text(
      text = "恢复前请确认已经备份当前数据。恢复失败会整体回滚，不会留下半套数据。",
      style = MoreMoneyTextStyles.caption,
      color = colors.ink3,
    )
    PrimaryButton(text = "确认恢复并覆盖", onClick = onConfirm)
    Spacer(Modifier.height(2.dp))
    Text(
      text = "取消",
      style = MoreMoneyTextStyles.row,
      color = colors.ink2,
      modifier = Modifier.fillMaxWidth().clickable(onClick = onDismiss).padding(vertical = 8.dp),
      textAlign = androidx.compose.ui.text.style.TextAlign.Center,
    )
  }
}

@Composable
private fun PreviewLine(label: String, value: String) {
  val colors = MoreMoneyTheme.colors
  Row(modifier = Modifier.fillMaxWidth()) {
    Text(text = label, style = MoreMoneyTextStyles.caption, color = colors.ink3, modifier = Modifier.weight(1f))
    Text(text = value, style = MoreMoneyTextStyles.settingsTitle, color = colors.ink)
  }
}

private suspend fun writeText(context: Context, uri: Uri, text: String) {
  withContext(Dispatchers.IO) {
    context.contentResolver.openOutputStream(uri)?.use { output ->
      output.write(text.toByteArray(Charsets.UTF_8))
      output.flush()
    } ?: throw IllegalStateException("无法写入所选位置")
  }
}

private suspend fun readText(context: Context, uri: Uri, maxBytes: Int = 5 * 1024 * 1024): String? =
  withContext(Dispatchers.IO) {
    context.contentResolver.openInputStream(uri)?.use { input ->
      val bytes = input.readBytes()
      if (bytes.size > maxBytes) {
        null
      } else {
        String(bytes, Charsets.UTF_8)
      }
    }
  }
