package com.github.ppg007.moremoney.debug

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.lifecycleScope
import com.github.ppg007.moremoney.appContainer
import com.github.ppg007.moremoney.ui.components.AppCard
import com.github.ppg007.moremoney.ui.components.base.AmountBar
import com.github.ppg007.moremoney.ui.components.base.Badge
import com.github.ppg007.moremoney.ui.components.base.CategoryCircle
import com.github.ppg007.moremoney.ui.components.base.EyeButton
import com.github.ppg007.moremoney.ui.components.base.MoneyText
import com.github.ppg007.moremoney.ui.components.base.MoneyTone
import com.github.ppg007.moremoney.ui.components.base.PrimaryButton
import com.github.ppg007.moremoney.ui.components.base.RingProgress
import com.github.ppg007.moremoney.ui.components.base.SecondaryButton
import com.github.ppg007.moremoney.ui.components.base.SegmentedControl
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.SeedColors
import kotlinx.coroutines.launch

/**
 * debug 包组件 Gallery：用于快速检查组件在浅色/深色下的状态。
 * 不进入正式包与正式导航。
 */
class GalleryActivity : ComponentActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContent {
      MoreMoneyTheme {
        GalleryContent(
          onSeed = {
            lifecycleScope.launch {
              DebugSeedService.seed(appContainer)
            }
          },
        )
      }
    }
  }
}

@Composable
private fun GalleryContent(onSeed: () -> Unit) {
  val colors = MoreMoneyTheme.colors
  val container = LocalContext.current.appContainer
  var segment by remember { mutableIntStateOf(0) }
  Column(
    modifier =
      Modifier
        .fillMaxSize()
        .background(colors.background)
        .verticalScroll(rememberScrollState())
        .padding(16.dp),
    verticalArrangement = Arrangement.spacedBy(12.dp),
  ) {
    Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
      Text(text = "组件 Gallery", style = MoreMoneyTextStyles.pageTitle, color = colors.ink, modifier = Modifier.weight(1f))
      EyeButton(ui = container.ui)
    }
    AppCard {
      Text(text = "金额", style = MoreMoneyTextStyles.caption, color = colors.ink3)
      MoneyText(cents = 128640, tone = MoneyTone.Expense, style = MoreMoneyTextStyles.heroAmount)
      MoneyText(cents = 128640, hidden = container.ui.hideAmount, tone = MoneyTone.Ink, style = MoreMoneyTextStyles.stat)
      MoneyText(cents = 5000, tone = MoneyTone.Good, style = MoreMoneyTextStyles.body)
    }
    AppCard {
      Text(text = "按钮与分段控件", style = MoreMoneyTextStyles.caption, color = colors.ink3)
      PrimaryButton(text = "主按钮", onClick = {})
      SecondaryButton(text = "次按钮", onClick = {})
      SegmentedControl(options = listOf("分类", "趋势", "日历"), selectedIndex = segment, onSelect = { segment = it })
    }
    AppCard {
      Text(text = "徽标与分类", style = MoreMoneyTextStyles.caption, color = colors.ink3)
      Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Badge("默认")
        Badge("已归档", tone = com.github.ppg007.moremoney.ui.components.base.BadgeTone.Warn)
      }
      Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        CategoryCircle("ic_cat_food", SeedColors.c2)
        CategoryCircle("ic_cat_transport", SeedColors.c1)
        CategoryCircle("ic_cat_home", SeedColors.c3)
      }
    }
    AppCard {
      Text(text = "进度", style = MoreMoneyTextStyles.caption, color = colors.ink3)
      AmountBar(progress = 0.62f, hidden = container.ui.hideAmount)
      Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        RingProgress(progress = 0.42f, hidden = container.ui.hideAmount, size = 84.dp, stroke = 9.dp)
        RingProgress(progress = 1f, hidden = container.ui.hideAmount, size = 84.dp, stroke = 9.dp, overflow = true)
      }
    }
    PrimaryButton(
      text = "生成演示数据（4 账本 / 30 笔 / 2 预算）",
      onClick = {
        onSeed()
        container.ui.showSnack("演示数据已写入")
      },
    )
    Text(
      text = "提示：在系统设置中切换深色模式，可检查深色 token。",
      style = MoreMoneyTextStyles.caption,
      color = colors.ink3,
      fontWeight = FontWeight.Normal,
    )
  }
}
