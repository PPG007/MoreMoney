package com.github.ppg007.moremoney.ui.settings

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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.github.ppg007.moremoney.BuildConfig
import com.github.ppg007.moremoney.R
import com.github.ppg007.moremoney.appContainer
import com.github.ppg007.moremoney.state.AppUiState
import com.github.ppg007.moremoney.ui.common.SystemBarAppearance
import com.github.ppg007.moremoney.ui.components.base.AppBottomSheet
import com.github.ppg007.moremoney.ui.components.base.CardColumn
import com.github.ppg007.moremoney.ui.components.base.DividerLine
import com.github.ppg007.moremoney.ui.components.base.EyeButton
import com.github.ppg007.moremoney.ui.components.base.ListRow
import com.github.ppg007.moremoney.ui.components.base.SheetTitle
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.ui.theme.Spacing
import com.github.ppg007.moremoney.ui.theme.SeedColors
import com.github.ppg007.moremoney.ui.theme.parseColorOf
import com.github.ppg007.moremoney.util.DateUtil

/**
 * 一级 Tab“设置”：备份状态、数据入口、周起始日、外观、关于。
 *
 * 不提供私密账本入口；外观固定“跟随系统”。
 */
@Composable
fun SettingsScreen(
  ui: AppUiState,
  onBookManage: () -> Unit,
  onCategoryManage: () -> Unit,
  onDataBackup: () -> Unit,
  modifier: Modifier = Modifier,
) {
  val container = LocalContext.current.appContainer
  val colors = MoreMoneyTheme.colors
  val settings by container.settings.state.collectAsStateWithLifecycle()
  val books by container.bookRepository.observeAll().collectAsStateWithLifecycle(emptyList())
  val categories by container.categoryRepository.observeAll().collectAsStateWithLifecycle(emptyList())
  var showWeekStart by remember { mutableStateOf(false) }

  SystemBarAppearance(darkIcons = true)

  Column(
    modifier =
      modifier
        .fillMaxSize()
        .background(colors.background)
        .verticalScroll(rememberScrollState())
        .statusBarsPadding()
        .padding(horizontal = Spacing.page)
        .padding(top = 10.dp),
  ) {
    Row(verticalAlignment = Alignment.CenterVertically) {
      Text(
        text = "设置",
        style = MoreMoneyTextStyles.pageTitle,
        color = colors.ink,
        modifier = Modifier.weight(1f),
      )
      EyeButton(ui = ui)
    }

    Column(
      modifier =
        Modifier
          .fillMaxWidth()
          .padding(top = Spacing.x5)
          .clip(RoundedCornerShape(Radius.card))
          .background(
            Brush.horizontalGradient(listOf(colors.brandWash, colors.surface))
          )
          .border(1.dp, colors.line, RoundedCornerShape(Radius.card))
          .clickable(onClick = onDataBackup)
          .padding(13.dp),
      verticalArrangement = Arrangement.spacedBy(3.dp),
    ) {
      Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Box(
          modifier =
            Modifier
              .size(39.dp)
              .clip(RoundedCornerShape(13.dp))
              .background(colors.brandWash),
          contentAlignment = Alignment.Center,
        ) {
          Icon(
            painter = painterResource(R.drawable.ic_cloud),
            contentDescription = null,
            tint = colors.brandInk,
            modifier = Modifier.size(20.dp),
          )
        }
        Column(modifier = Modifier.weight(1f)) {
          Text(
            text = "数据与备份",
            style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.Bold),
            color = colors.ink,
          )
          Text(
            text =
              if (settings.lastBackupAt > 0) {
                "上次备份 ${DateUtil.formatShortDateTime(settings.lastBackupAt)}"
              } else {
                "还没有备份，建议立即备份一次"
              },
            style = MoreMoneyTextStyles.caption,
            color = colors.ink3,
          )
        }
        Icon(
          painter = painterResource(R.drawable.ic_chevron_right),
          contentDescription = null,
          tint = colors.ink3,
          modifier = Modifier.size(14.dp),
        )
      }
    }

    GroupLabel("数据")
    CardColumn {
      ListRow(
        title = "账本管理",
        subtitle = "${books.count { !it.archived }} 个账本",
        iconRes = R.drawable.ic_book,
        iconTint = parseColorOf(SeedColors.c1),
        onClick = onBookManage,
        trailing = { Chevron() },
      )
      DividerLine()
      ListRow(
        title = "分类管理",
        subtitle = "${categories.count { !it.archived }} 个分类",
        iconRes = R.drawable.ic_cat_other,
        onClick = onCategoryManage,
        trailing = { Chevron() },
      )
    }

    GroupLabel("通用")
    CardColumn {
      ListRow(
        title = "周起始日",
        subtitle = "影响本周统计与趋势分组",
        iconRes = R.drawable.ic_calendar,
        onClick = { showWeekStart = true },
        trailing = {
          Text(
            text = if (settings.weekStart == 7) "周日" else "周一",
            style = MoreMoneyTextStyles.settingsTitle,
            color = colors.ink2,
          )
        },
      )
      DividerLine()
      ListRow(
        title = "外观",
        subtitle = "跟随系统深色 / 浅色",
        iconRes = R.drawable.ic_eye,
        trailing = {
          Text(text = "跟随系统", style = MoreMoneyTextStyles.settingsTitle, color = colors.ink2)
        },
      )
      DividerLine()
      ListRow(
        title = "关于",
        subtitle = "来财 ${BuildConfig.VERSION_NAME}",
        iconRes = R.drawable.ic_book,
        trailing = {
          Text(text = "完全离线", style = MoreMoneyTextStyles.settingsTitle, color = colors.ink2)
        },
      )
    }

    Text(
      text = "来财完全离线运行：不申请网络权限，账本数据仅保存在本机；不包含私密账本、密码或生物识别。恢复旧备份时会跳过私密账本并在预览中提示。",
      style = MoreMoneyTextStyles.caption,
      color = colors.ink3,
      modifier = Modifier.padding(top = Spacing.x5, bottom = 120.dp),
    )
  }

  if (showWeekStart) {
    AppBottomSheet(onDismiss = { showWeekStart = false }) {
      SheetTitle(title = "周起始日")
      listOf(1 to "周一", 7 to "周日").forEach { (value, label) ->
        Row(
          modifier =
            Modifier
              .fillMaxWidth()
              .clip(RoundedCornerShape(Radius.chip))
              .background(if (settings.weekStart == value) colors.brandWash else colors.surface)
              .clickable {
                container.settings.setWeekStart(value)
                showWeekStart = false
              }
              .padding(horizontal = 12.dp, vertical = 12.dp),
          verticalAlignment = Alignment.CenterVertically,
        ) {
          Text(text = label, style = MoreMoneyTextStyles.settingsTitle, color = colors.ink, modifier = Modifier.weight(1f))
          if (settings.weekStart == value) {
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
}

@Composable
private fun GroupLabel(text: String) {
  Text(
    text = text,
    style = MoreMoneyTextStyles.caption.copy(fontWeight = FontWeight.Bold),
    color = MoreMoneyTheme.colors.ink3,
    modifier = Modifier.padding(top = Spacing.x5, bottom = Spacing.x2),
  )
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
