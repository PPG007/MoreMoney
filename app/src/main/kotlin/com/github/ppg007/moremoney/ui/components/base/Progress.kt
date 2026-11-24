package com.github.ppg007.moremoney.ui.components.base

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius

/**
 * 预算进度条。隐藏金额时保留轨道、不绘制填充，避免从长度反推金额。
 */
@Composable
fun AmountBar(
  progress: Float,
  hidden: Boolean,
  modifier: Modifier = Modifier,
  height: Dp = 8.dp,
) {
  val colors = MoreMoneyTheme.colors
  val ratio = progress.coerceIn(0f, 1f)
  Box(
    modifier =
      modifier
        .fillMaxWidth()
        .height(height)
        .clip(RoundedCornerShape(Radius.pill))
        .background(colors.surface2),
  ) {
    if (!hidden && ratio > 0f) {
      Box(
        modifier =
          Modifier
            .fillMaxWidth(ratio)
            .height(height)
            .clip(RoundedCornerShape(Radius.pill))
            .background(Brush.horizontalGradient(listOf(colors.brand, colors.brandInk))),
      )
    }
  }
}

/**
 * 环形进度：116dp、stroke 11，中心可放置百分比。
 *
 * 隐藏金额时只画轨道。
 */
@Composable
fun RingProgress(
  progress: Float,
  hidden: Boolean,
  modifier: Modifier = Modifier,
  size: Dp = 116.dp,
  stroke: Dp = 11.dp,
  overflow: Boolean = false,
  center: (@Composable () -> Unit)? = null,
) {
  val colors = MoreMoneyTheme.colors
  val ratio = progress.coerceIn(0f, 1f)
  Box(modifier = modifier.size(size), contentAlignment = Alignment.Center) {
    Canvas(modifier = Modifier.size(size)) {
      val strokePx = stroke.toPx()
      val inset = strokePx / 2f
      val arcSize = Size(this.size.width - strokePx, this.size.height - strokePx)
      drawArc(
        color = colors.surface2,
        startAngle = -90f,
        sweepAngle = 360f,
        useCenter = false,
        topLeft = Offset(inset, inset),
        size = arcSize,
        style = Stroke(width = strokePx, cap = StrokeCap.Round),
      )
      if (!hidden && ratio > 0f) {
        drawArc(
          brush =
            Brush.sweepGradient(
              listOf(
                if (overflow) colors.expense else colors.brand,
                if (overflow) colors.expense else colors.brandInk,
              )
            ),
          startAngle = -90f,
          sweepAngle = 360f * ratio,
          useCenter = false,
          topLeft = Offset(inset, inset),
          size = arcSize,
          style = Stroke(width = strokePx, cap = StrokeCap.Round),
        )
      }
    }
    center?.invoke()
  }
}
