package com.github.ppg007.moremoney.ui.charts

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp
import androidx.compose.material3.Text
import com.github.ppg007.moremoney.ui.components.base.MoneyText
import com.github.ppg007.moremoney.ui.components.base.MoneyTone
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import kotlin.math.atan2
import kotlin.math.sqrt

data class DonutSlice(
  val cents: Long,
  val color: Color,
  val name: String,
)

/**
 * 环形图：起始 -90°，段间 2° 间隙，选中扇区外扩 4dp，点按扇区可选中。
 *
 * 不依赖第三方图表库；隐藏金额时中心只打码，扇区比例保留。
 */
@Composable
fun DonutChart(
  slices: List<DonutSlice>,
  totalCents: Long,
  hidden: Boolean,
  selectedIndex: Int,
  onSelect: (Int) -> Unit,
  modifier: Modifier = Modifier,
  size: Int = 232,
  centerLabel: String = "支出",
) {
  val colors = MoreMoneyTheme.colors
  val safeTotal = if (totalCents > 0) totalCents else slices.sumOf { it.cents }

  Box(modifier = modifier.size(size.dp), contentAlignment = Alignment.Center) {
    Canvas(
      modifier =
        Modifier
          .size(size.dp)
          .pointerInput(slices, safeTotal) {
            detectTapGestures { offset ->
              if (slices.isEmpty() || safeTotal <= 0) {
                return@detectTapGestures
              }
              val cx = this.size.width / 2f
              val cy = this.size.height / 2f
              val dx = offset.x - cx
              val dy = offset.y - cy
              val radius = sqrt(dx * dx + dy * dy)
              val outer = this.size.width / 2f
              if (radius < outer * 0.45f || radius > outer) {
                return@detectTapGestures
              }
              var angle = Math.toDegrees(atan2(dy.toDouble(), dx.toDouble())).toFloat()
              angle = (angle + 360f) % 360f
              // 转换到以 -90° 为起点的顺时针角度。
              val normalized = (angle + 90f) % 360f
              var acc = 0f
              slices.forEachIndexed { index, slice ->
                val sweep = if (safeTotal > 0) slice.cents.toFloat() / safeTotal * 360f else 0f
                if (normalized >= acc && normalized < acc + sweep) {
                  onSelect(if (selectedIndex == index) -1 else index)
                  return@detectTapGestures
                }
                acc += sweep
              }
            }
          },
    ) {
      val stroke = 30.dp.toPx() * (this.size.width / 280f)
      val gap = 2f
      val inset = stroke / 2f
      val arcSize = Size(this.size.width - stroke, this.size.height - stroke)
      if (slices.isEmpty() || safeTotal <= 0) {
        drawArc(
          color = colors.surface2,
          startAngle = -90f,
          sweepAngle = 360f,
          useCenter = false,
          topLeft = Offset(inset, inset),
          size = arcSize,
          style = Stroke(width = stroke, cap = StrokeCap.Butt),
        )
      } else {
        var start = -90f
        slices.forEachIndexed { index, slice ->
          val sweep = slice.cents.toFloat() / safeTotal * 360f
          val selected = index == selectedIndex
          val extra = if (selected) 4.dp.toPx() else 0f
          drawArc(
            color = slice.color,
            startAngle = start,
            sweepAngle = (sweep - gap).coerceAtLeast(1f),
            useCenter = false,
            topLeft = Offset(inset - extra, inset - extra),
            size = Size(arcSize.width + extra * 2, arcSize.height + extra * 2),
            style = Stroke(width = stroke, cap = StrokeCap.Butt),
          )
          start += sweep
        }
      }
    }

    val selected = slices.getOrNull(selectedIndex)
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
      if (selected != null && selectedIndex >= 0) {
        Text(
          text = selected.name,
          style = MoreMoneyTextStyles.caption,
          color = colors.ink3,
        )
        MoneyText(
          cents = selected.cents,
          hidden = hidden,
          tone = MoneyTone.Ink,
          style = MoreMoneyTextStyles.donutCenter,
        )
        Text(
          text = if (safeTotal > 0) "占比 ${(selected.cents.toFloat() / safeTotal * 100).toInt()}%" else "",
          style = MoreMoneyTextStyles.caption,
          color = colors.ink3,
        )
      } else {
        Text(text = centerLabel, style = MoreMoneyTextStyles.caption, color = colors.ink3)
        MoneyText(
          cents = safeTotal,
          hidden = hidden,
          tone = MoneyTone.Ink,
          style = MoreMoneyTextStyles.donutCenter,
        )
        Text(
          text = if (slices.isEmpty()) "暂无数据" else "${slices.size} 个分类",
          style = MoreMoneyTextStyles.caption,
          color = colors.ink3,
        )
      }
    }
  }
}
