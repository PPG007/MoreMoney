package com.github.ppg007.moremoney.ui.components.base

import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.layout
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * 视觉上向上移动 [offset]，同时把自身报告的布局高度减去同样距离。
 *
 * 用于首页摘要卡压住 Hero 54dp：既不遮挡 Hero 内容，也不留下额外的空白。
 * 与 `offset` 的区别是布局高度同步收缩，后续内容紧贴视觉底部。
 */
fun Modifier.pullUp(offset: Dp): Modifier =
  layout { measurable, constraints ->
    val placeable = measurable.measure(constraints)
    val shift = offset.roundToPx()
    layout(placeable.width, (placeable.height - shift).coerceAtLeast(0)) {
      placeable.place(0, -shift)
    }
  }

/** 虚线圆角描边，用于“未设置预算”等空状态卡。 */
fun Modifier.dashedBorder(
  color: Color,
  cornerRadius: Dp,
  strokeWidth: Dp = 1.5.dp,
): Modifier =
  drawBehind {
    drawRoundRect(
      color = color,
      cornerRadius = CornerRadius(cornerRadius.toPx(), cornerRadius.toPx()),
      style =
        Stroke(
          width = strokeWidth.toPx(),
          pathEffect = PathEffect.dashPathEffect(floatArrayOf(12f, 9f), 0f),
        ),
    )
  }
