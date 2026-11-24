package com.github.ppg007.moremoney.ui.components.base

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.Radius

@Composable
fun PrimaryButton(
  text: String,
  onClick: () -> Unit,
  modifier: Modifier = Modifier,
  enabled: Boolean = true,
  leadingIcon: Int? = null,
) {
  val colors = MoreMoneyTheme.colors
  Row(
    modifier =
      modifier
        .fillMaxWidth()
        .height(46.dp)
        .clip(RoundedCornerShape(Radius.button))
        .background(if (enabled) colors.buttonBackground else colors.surface3)
        .clickable(enabled = enabled, onClick = onClick),
    horizontalArrangement = Arrangement.Center,
    verticalAlignment = Alignment.CenterVertically,
  ) {
    if (leadingIcon != null) {
      Icon(
        painter = painterResource(leadingIcon),
        contentDescription = null,
        tint = if (enabled) colors.buttonForeground else colors.ink3,
        modifier = Modifier.size(15.dp),
      )
    }
    Text(
      text = text,
      color = if (enabled) colors.buttonForeground else colors.ink3,
      style = MoreMoneyTextStyles.row.copy(fontWeight = FontWeight.Bold),
      modifier = if (leadingIcon == null) Modifier else Modifier.padding(start = 6.dp),
    )
  }
}

@Composable
fun SecondaryButton(
  text: String,
  onClick: () -> Unit,
  modifier: Modifier = Modifier,
  enabled: Boolean = true,
  leadingIcon: Int? = null,
) {
  val colors = MoreMoneyTheme.colors
  Row(
    modifier =
      modifier
        .fillMaxWidth()
        .height(46.dp)
        .clip(RoundedCornerShape(Radius.button))
        .background(colors.surface)
        .border(1.dp, colors.line, RoundedCornerShape(Radius.button))
        .clickable(enabled = enabled, onClick = onClick),
    horizontalArrangement = Arrangement.Center,
    verticalAlignment = Alignment.CenterVertically,
  ) {
    if (leadingIcon != null) {
      Icon(
        painter = painterResource(leadingIcon),
        contentDescription = null,
        tint = colors.ink2,
        modifier = Modifier.size(15.dp),
      )
    }
    Text(
      text = text,
      color = colors.ink,
      style = MoreMoneyTextStyles.settingsTitle.copy(fontWeight = FontWeight.SemiBold),
      modifier = if (leadingIcon == null) Modifier else Modifier.padding(start = 6.dp),
    )
  }
}

/** 34×34 圆形图标按钮；热区 44dp。 */
@Composable
fun AppIconButton(
  iconRes: Int,
  contentDescription: String?,
  onClick: () -> Unit,
  modifier: Modifier = Modifier,
  tint: Color? = null,
  background: Color? = null,
  borderColor: Color? = null,
  size: Int = 34,
  iconSize: Int = 17,
) {
  val colors = MoreMoneyTheme.colors
  Box(
    modifier =
      modifier
        .defaultMinSize(minWidth = 44.dp, minHeight = 44.dp)
        .clickable(onClick = onClick),
    contentAlignment = Alignment.Center,
  ) {
    Box(
      modifier =
        Modifier
          .size(size.dp)
          .clip(CircleShape)
          .background(background ?: colors.surface)
          .border(BorderStroke(1.dp, borderColor ?: colors.line), CircleShape),
      contentAlignment = Alignment.Center,
    ) {
      Icon(
        painter = painterResource(iconRes),
        contentDescription = contentDescription,
        tint = tint ?: colors.ink,
        modifier = Modifier.size(iconSize.dp),
      )
    }
  }
}

/** 胶囊迷你操作按钮，如“去设置”“解锁”。 */
@Composable
fun MiniButton(
  text: String,
  onClick: () -> Unit,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  Text(
    text = text,
    color = colors.brandInk,
    style = MoreMoneyTextStyles.caption.copy(fontWeight = FontWeight.Bold),
    modifier =
      modifier
        .clip(RoundedCornerShape(Radius.pill))
        .background(colors.brandWash)
        .clickable(onClick = onClick)
        .padding(horizontal = 9.dp, vertical = 5.dp),
  )
}
