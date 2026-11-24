package com.github.ppg007.moremoney.ui.ledger

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.Orientation
import androidx.compose.foundation.gestures.draggable
import androidx.compose.foundation.gestures.rememberDraggableState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.github.ppg007.moremoney.R
import com.github.ppg007.moremoney.data.db.entity.CategoryEntity
import com.github.ppg007.moremoney.data.db.entity.TxnEntity
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

private val SwipeActionWidth = 64.dp
private val SwipeActionsWidth = SwipeActionWidth * 2

/**
 * 可左滑的流水行：左滑露出编辑/删除按钮。
 *
 * `revealed` 由列表统一持有，保证同时只有一行处于展开状态。
 */
@Composable
internal fun SwipeTxnRow(
  txn: TxnEntity,
  category: CategoryEntity?,
  hidden: Boolean,
  revealed: Boolean,
  onRevealChange: (Boolean) -> Unit,
  onClick: () -> Unit,
  onEdit: () -> Unit,
  onDelete: () -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  val actionsWidthPx = with(LocalDensity.current) { SwipeActionsWidth.toPx() }
  val offset = remember { Animatable(0f) }
  val scope = rememberCoroutineScope()
  val settleSpec = tween<Float>(durationMillis = 180)

  LaunchedEffect(revealed) {
    offset.animateTo(if (revealed) -actionsWidthPx else 0f, settleSpec)
  }

  Box(modifier = Modifier.fillMaxWidth()) {
    Row(
      modifier =
        Modifier
          .matchParentSize()
          .then(if (revealed) Modifier.testTag("swipe_actions") else Modifier),
      horizontalArrangement = Arrangement.End,
    ) {
      SwipeAction(
        iconRes = R.drawable.ic_edit,
        description = "编辑",
        background = colors.brandWash,
        tint = colors.brandInk,
        modifier =
          Modifier
            .width(SwipeActionWidth)
            .fillMaxHeight()
            .then(if (revealed) Modifier.testTag("swipe_edit") else Modifier),
        onClick = onEdit,
      )
      SwipeAction(
        iconRes = R.drawable.ic_trash,
        description = "删除",
        background = colors.expense,
        tint = colors.buttonForeground,
        modifier =
          Modifier
            .width(SwipeActionWidth)
            .fillMaxHeight()
            .then(if (revealed) Modifier.testTag("swipe_delete") else Modifier),
        onClick = onDelete,
      )
    }
    Box(
      modifier =
        Modifier
          .fillMaxWidth()
          .offset { IntOffset(offset.value.roundToInt(), 0) }
          .draggable(
            orientation = Orientation.Horizontal,
            state =
              rememberDraggableState { delta ->
                scope.launch {
                  offset.snapTo((offset.value + delta).coerceIn(-actionsWidthPx, 0f))
                }
              },
            onDragStopped = {
              val open = offset.value <= -actionsWidthPx / 2f
              onRevealChange(open)
              offset.animateTo(if (open) -actionsWidthPx else 0f, settleSpec)
            },
          )
          .testTag("txn_row"),
    ) {
      TxnRow(
        txn = txn,
        category = category,
        hidden = hidden,
        isFirst = false,
        isLast = false,
        onClick = onClick,
      )
    }
  }
}

@Composable
private fun SwipeAction(
  iconRes: Int,
  description: String,
  background: Color,
  tint: Color,
  modifier: Modifier = Modifier,
  onClick: () -> Unit,
) {
  Box(
    modifier = modifier.background(background).clickable(onClick = onClick),
    contentAlignment = Alignment.Center,
  ) {
    Icon(
      painter = painterResource(iconRes),
      contentDescription = description,
      tint = tint,
      modifier = Modifier.size(20.dp),
    )
  }
}
