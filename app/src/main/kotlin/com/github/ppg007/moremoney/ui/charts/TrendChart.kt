package com.github.ppg007.moremoney.ui.charts

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.github.ppg007.moremoney.models.BucketSum
import com.github.ppg007.moremoney.ui.components.base.MoneyText
import com.github.ppg007.moremoney.ui.components.base.MoneyTone
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.withAlpha

/**
 * 趋势折线/面积图：2dp 线、点半径 3.4、末点 4.6；不引入第三方图表库。
 *
 * 金额隐藏时保留曲线形状（比例信息），隐藏最高值与坐标金额。
 */
@Composable
fun TrendChart(
  buckets: List<BucketSum>,
  hidden: Boolean,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  if (buckets.isEmpty()) {
    Box(
      modifier =
        modifier
          .fillMaxWidth()
          .height(190.dp)
          .background(colors.surface2, androidx.compose.foundation.shape.RoundedCornerShape(12.dp)),
      contentAlignment = Alignment.Center,
    ) {
      Text(text = "区间内暂无数据", style = MoreMoneyTextStyles.caption, color = colors.ink3)
    }
    return
  }
  val maxCents = buckets.maxOf { it.cents }.coerceAtLeast(1)

  Column(modifier = modifier.fillMaxWidth()) {
    Row(verticalAlignment = Alignment.CenterVertically) {
      Text(text = "最高", style = MoreMoneyTextStyles.caption, color = colors.ink3, modifier = Modifier.weight(1f))
      MoneyText(
        cents = maxCents,
        hidden = hidden,
        tone = MoneyTone.Ink,
        style = MoreMoneyTextStyles.caption.copy(fontWeight = FontWeight.SemiBold),
      )
    }
    Canvas(
      modifier =
        Modifier
          .fillMaxWidth()
          .height(170.dp)
          .padding(top = 8.dp, bottom = 4.dp),
    ) {
      val left = 4.dp.toPx()
      val right = size.width - 4.dp.toPx()
      val top = 10.dp.toPx()
      val bottom = size.height - 18.dp.toPx()
      val height = bottom - top
      val width = right - left

      // 三条水平网格线。
      repeat(3) { index ->
        val y = top + height * index / 2f
        drawLine(
          color = colors.line,
          start = Offset(left, y),
          end = Offset(right, y),
          strokeWidth = 1.dp.toPx(),
        )
      }

      val step = if (buckets.size > 1) width / (buckets.size - 1) else 0f
      val points =
        buckets.mapIndexed { index, bucket ->
          val x = if (buckets.size == 1) (left + right) / 2f else left + step * index
          val ratio = bucket.cents.toFloat() / maxCents
          val y = bottom - height * ratio
          Offset(x, y)
        }

      if (points.size > 1) {
        val area =
          Path().apply {
            moveTo(points.first().x, bottom)
            points.forEach { lineTo(it.x, it.y) }
            lineTo(points.last().x, bottom)
            close()
          }
        drawPath(
          path = area,
          brush =
            Brush.verticalGradient(
              colors = listOf(withAlpha(colors.brand, 0.3f), withAlpha(colors.brand, 0f)),
              startY = top,
              endY = bottom,
            ),
        )
        val line =
          Path().apply {
            moveTo(points.first().x, points.first().y)
            points.drop(1).forEach { lineTo(it.x, it.y) }
          }
        drawPath(
          path = line,
          color = colors.brandInk,
          style = Stroke(width = 2.dp.toPx(), cap = StrokeCap.Round),
        )
      }

      points.forEachIndexed { index, point ->
        val last = index == points.lastIndex
        drawCircle(
          color = colors.surface,
          radius = (if (last) 4.6f else 3.4f).dp.toPx(),
          center = point,
        )
        drawCircle(
          color = colors.brandInk,
          radius = (if (last) 4.6f else 3.4f).dp.toPx(),
          center = point,
          style = Stroke(width = 2.dp.toPx()),
        )
      }
    }
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
      Text(
        text = buckets.first().label,
        style = MoreMoneyTextStyles.caption,
        color = colors.ink3,
      )
      if (buckets.size > 2) {
        Text(
          text = buckets[buckets.size / 2].label,
          style = MoreMoneyTextStyles.caption,
          color = colors.ink3,
        )
      }
      Text(
        text = buckets.last().label,
        style = MoreMoneyTextStyles.caption,
        color = colors.ink3,
      )
    }
  }
}

/** 最高 3 天：日期、金额与比例条。 */
@Composable
fun TopDaysList(
  days: List<BucketSum>,
  hidden: Boolean,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  if (days.isEmpty()) {
    return
  }
  val max = days.maxOf { it.cents }.coerceAtLeast(1)
  Column(modifier = modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(6.dp)) {
    Text(
      text = "最高 3 天",
      style = MoreMoneyTextStyles.body.copy(fontWeight = FontWeight.Bold),
      color = colors.ink,
    )
    days.forEach { day ->
      Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(text = day.label, style = MoreMoneyTextStyles.caption, color = colors.ink3, modifier = Modifier.width(44.dp))
        Box(
          modifier =
            Modifier
              .weight(1f)
              .height(5.dp)
              .background(colors.surface2, androidx.compose.foundation.shape.RoundedCornerShape(3.dp)),
        ) {
          if (!hidden) {
            Box(
              modifier =
                Modifier
                  .fillMaxWidth(day.cents.toFloat() / max)
                  .height(5.dp)
                  .background(colors.brand, androidx.compose.foundation.shape.RoundedCornerShape(3.dp)),
            )
          }
        }
        MoneyText(
          cents = day.cents,
          hidden = hidden,
          tone = MoneyTone.Ink,
          style = MoreMoneyTextStyles.settingsTitle.copy(fontWeight = FontWeight.SemiBold),
        )
      }
    }
  }
}
