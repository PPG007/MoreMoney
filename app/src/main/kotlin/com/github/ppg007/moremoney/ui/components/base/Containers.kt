package com.github.ppg007.moremoney.ui.components.base

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.github.ppg007.moremoney.ui.components.iconResOf
import com.github.ppg007.moremoney.ui.theme.IconSize
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTextStyles
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme
import com.github.ppg007.moremoney.ui.theme.Radius
import com.github.ppg007.moremoney.ui.theme.Spacing
import com.github.ppg007.moremoney.ui.theme.parseColorOf
import com.github.ppg007.moremoney.ui.theme.withAlpha

@Composable
fun SectionHeader(
  title: String,
  modifier: Modifier = Modifier,
  subtitle: String? = null,
  trailing: (@Composable () -> Unit)? = null,
) {
  val colors = MoreMoneyTheme.colors
  Row(
    modifier = modifier.fillMaxWidth(),
    verticalAlignment = Alignment.CenterVertically,
  ) {
    Column(modifier = Modifier.weight(1f)) {
      Text(text = title, style = MoreMoneyTextStyles.body.copy(fontWeight = FontWeight.Bold), color = colors.ink)
      if (subtitle != null) {
        Text(text = subtitle, style = MoreMoneyTextStyles.caption, color = colors.ink3)
      }
    }
    trailing?.invoke()
  }
}

/** 设置/列表通用行：图标 + 标题/副标题 + 尾部。 */
@Composable
fun ListRow(
  title: String,
  modifier: Modifier = Modifier,
  subtitle: String? = null,
  iconRes: Int? = null,
  iconTint: Color? = null,
  iconBackground: Color? = null,
  trailing: (@Composable () -> Unit)? = null,
  onClick: (() -> Unit)? = null,
) {
  val colors = MoreMoneyTheme.colors
  Row(
    modifier =
      modifier
        .fillMaxWidth()
        .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
        .padding(horizontal = 13.dp, vertical = 11.dp),
    verticalAlignment = Alignment.CenterVertically,
    horizontalArrangement = Arrangement.spacedBy(Spacing.x4),
  ) {
    if (iconRes != null) {
      Box(
        modifier =
          Modifier
            .size(31.dp)
            .clip(RoundedCornerShape(10.dp))
            .background(iconBackground ?: colors.surface2),
        contentAlignment = Alignment.Center,
      ) {
        Icon(
          painter = painterResource(iconRes),
          contentDescription = null,
          tint = iconTint ?: colors.ink2,
          modifier = Modifier.size(16.dp),
        )
      }
    }
    Column(modifier = Modifier.weight(1f)) {
      Text(text = title, style = MoreMoneyTextStyles.settingsTitle, color = colors.ink)
      if (subtitle != null) {
        Text(text = subtitle, style = MoreMoneyTextStyles.caption, color = colors.ink3)
      }
    }
    trailing?.invoke()
  }
}

@Composable
fun ToggleRow(
  title: String,
  checked: Boolean,
  onCheckedChange: (Boolean) -> Unit,
  modifier: Modifier = Modifier,
  subtitle: String? = null,
) {
  val colors = MoreMoneyTheme.colors
  Row(
    modifier =
      modifier
        .fillMaxWidth()
        .clickable { onCheckedChange(!checked) }
        .padding(horizontal = 13.dp, vertical = 11.dp),
    verticalAlignment = Alignment.CenterVertically,
  ) {
    Column(modifier = Modifier.weight(1f)) {
      Text(text = title, style = MoreMoneyTextStyles.settingsTitle, color = colors.ink)
      if (subtitle != null) {
        Text(text = subtitle, style = MoreMoneyTextStyles.caption, color = colors.ink3)
      }
    }
    AppSwitch(checked = checked, onCheckedChange = onCheckedChange)
  }
}

/** 38×22 的胶囊开关；整行可点，热区由父布局保证 ≥48dp。 */
@Composable
fun AppSwitch(
  checked: Boolean,
  onCheckedChange: (Boolean) -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  Box(
    modifier =
      Modifier
        .size(width = 38.dp, height = 22.dp)
        .clip(CircleShape)
        .background(if (checked) colors.buttonBackground else colors.surface3)
        .clickable { onCheckedChange(!checked) }
        .padding(3.dp),
    contentAlignment = if (checked) Alignment.CenterEnd else Alignment.CenterStart,
  ) {
    Box(
      modifier =
        Modifier
          .size(16.dp)
          .clip(CircleShape)
          .background(if (checked) colors.buttonForeground else colors.surface),
    )
  }
}

@Composable
fun EmptyState(
  title: String,
  description: String,
  modifier: Modifier = Modifier,
  iconName: String = "ic_cat_other",
) {
  val colors = MoreMoneyTheme.colors
  Column(
    modifier = modifier.fillMaxWidth().padding(vertical = Spacing.x9),
    horizontalAlignment = Alignment.CenterHorizontally,
  ) {
    Box(
      modifier =
        Modifier
          .size(56.dp)
          .clip(RoundedCornerShape(Radius.icon))
          .background(colors.surface2),
      contentAlignment = Alignment.Center,
    ) {
      Icon(
        painter = painterResource(iconResOf(iconName)),
        contentDescription = null,
        tint = colors.ink3,
        modifier = Modifier.size(IconSize.empty),
      )
    }
    Spacer(Modifier.height(Spacing.x5))
    Text(text = title, style = MoreMoneyTextStyles.body.copy(fontWeight = FontWeight.SemiBold), color = colors.ink)
    Spacer(Modifier.height(Spacing.x1))
    Text(text = description, style = MoreMoneyTextStyles.caption, color = colors.ink3)
  }
}

@Composable
fun ErrorRetry(
  message: String,
  onRetry: () -> Unit,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  Column(
    modifier = modifier.fillMaxWidth().padding(Spacing.x7),
    horizontalAlignment = Alignment.CenterHorizontally,
  ) {
    Icon(
      painter = painterResource(com.github.ppg007.moremoney.R.drawable.ic_warning),
      contentDescription = null,
      tint = colors.warn,
      modifier = Modifier.size(IconSize.empty),
    )
    Spacer(Modifier.height(Spacing.x5))
    Text(text = message, style = MoreMoneyTextStyles.body, color = colors.ink2)
    Spacer(Modifier.height(Spacing.x5))
    MiniButton(text = "重试", onClick = onRetry)
  }
}

@Composable
fun SkeletonList(
  rows: Int = 4,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  Column(
    modifier = modifier.fillMaxWidth().padding(horizontal = Spacing.page),
    verticalArrangement = Arrangement.spacedBy(Spacing.x3),
  ) {
    repeat(rows) {
      Row(
        modifier =
          Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Radius.card))
            .background(colors.surface)
            .padding(13.dp),
        horizontalArrangement = Arrangement.spacedBy(11.dp),
        verticalAlignment = Alignment.CenterVertically,
      ) {
        Box(Modifier.size(42.dp).clip(RoundedCornerShape(Radius.icon)).background(colors.surface2))
        Column(verticalArrangement = Arrangement.spacedBy(6.dp), modifier = Modifier.weight(1f)) {
          Box(Modifier.fillMaxWidth(0.55f).height(10.dp).clip(RoundedCornerShape(4.dp)).background(colors.surface2))
          Box(Modifier.fillMaxWidth(0.35f).height(8.dp).clip(RoundedCornerShape(4.dp)).background(colors.surface2))
        }
      }
    }
  }
}

@Composable
fun SegmentedControl(
  options: List<String>,
  selectedIndex: Int,
  onSelect: (Int) -> Unit,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  Row(
    modifier =
      modifier
        .fillMaxWidth()
        .clip(RoundedCornerShape(13.dp))
        .background(colors.surface2)
        .padding(3.dp),
    horizontalArrangement = Arrangement.spacedBy(3.dp),
  ) {
    options.forEachIndexed { index, label ->
      val selected = index == selectedIndex
      Box(
        modifier =
          Modifier
            .weight(1f)
            .height(30.dp)
            .clip(RoundedCornerShape(10.dp))
            .background(if (selected) colors.surface else Color.Transparent)
            .clickable { onSelect(index) },
        contentAlignment = Alignment.Center,
      ) {
        Text(
          text = label,
          style = MoreMoneyTextStyles.caption.copy(fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium),
          color = if (selected) colors.brandInk else colors.ink2,
        )
      }
    }
  }
}

/** 通用输入框：圆角 10、36 高、可选前置图标。 */
@Composable
fun AppTextField(
  value: String,
  onValueChange: (String) -> Unit,
  modifier: Modifier = Modifier,
  placeholder: String = "",
  leadingIcon: Int? = null,
  singleLine: Boolean = true,
  height: Int = 36,
  style: TextStyle = MoreMoneyTextStyles.caption,
  keyboardOptions: androidx.compose.foundation.text.KeyboardOptions =
    androidx.compose.foundation.text.KeyboardOptions.Default,
) {
  val colors = MoreMoneyTheme.colors
  Row(
    modifier =
      modifier
        .height(height.dp)
        .clip(RoundedCornerShape(Radius.input))
        .background(colors.surface)
        .border(1.dp, colors.line, RoundedCornerShape(Radius.input))
        .padding(horizontal = 10.dp),
    verticalAlignment = Alignment.CenterVertically,
    horizontalArrangement = Arrangement.spacedBy(6.dp),
  ) {
    if (leadingIcon != null) {
      Icon(
        painter = painterResource(leadingIcon),
        contentDescription = null,
        tint = colors.ink3,
        modifier = Modifier.size(IconSize.action),
      )
    }
    Box(modifier = Modifier.weight(1f)) {
      if (value.isEmpty()) {
        Text(text = placeholder, style = style, color = colors.ink3)
      }
      BasicTextField(
        value = value,
        onValueChange = onValueChange,
        singleLine = singleLine,
        textStyle = style.copy(color = colors.ink),
        cursorBrush = SolidColor(colors.brandInk),
        keyboardOptions = keyboardOptions,
        modifier = Modifier.fillMaxWidth(),
      )
    }
  }
}

/** 胶囊 chip，用于周期/筛选。 */
@Composable
fun Chip(
  text: String,
  selected: Boolean,
  onClick: () -> Unit,
  modifier: Modifier = Modifier,
) {
  val colors = MoreMoneyTheme.colors
  Text(
    text = text,
    style = MoreMoneyTextStyles.caption.copy(fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal),
    color = if (selected) colors.buttonForeground else colors.ink2,
    modifier =
      modifier
        .clip(RoundedCornerShape(Radius.pill))
        .background(if (selected) colors.brandInk else colors.surface)
        .border(1.dp, if (selected) colors.brandInk else colors.line, RoundedCornerShape(Radius.pill))
        .clickable(onClick = onClick)
        .padding(horizontal = 10.dp, vertical = 5.dp),
  )
}

/** 分类图标圆片：色底 13% + 图标。 */
@Composable
fun CategoryCircle(
  iconName: String,
  colorText: String,
  modifier: Modifier = Modifier,
  size: Int = 42,
  iconSize: Int = 21,
  cornerRadius: Int = 14,
) {
  val color = parseColorOf(colorText)
  Box(
    modifier =
      modifier
        .size(size.dp)
        .clip(RoundedCornerShape(cornerRadius.dp))
        .background(withAlpha(color, 0.13f)),
    contentAlignment = Alignment.Center,
  ) {
    Icon(
      painter = painterResource(iconResOf(iconName)),
      contentDescription = null,
      tint = color,
      modifier = Modifier.size(iconSize.dp),
    )
  }
}

@Composable
fun Badge(
  text: String,
  modifier: Modifier = Modifier,
  tone: BadgeTone = BadgeTone.Brand,
) {
  val colors = MoreMoneyTheme.colors
  val background = if (tone == BadgeTone.Brand) colors.brandWash else withAlpha(colors.warn, 0.12f)
  val foreground = if (tone == BadgeTone.Brand) colors.brandInk else colors.warn
  Text(
    text = text,
    style = MoreMoneyTextStyles.caption.copy(fontWeight = FontWeight.SemiBold, fontSize = 8.sp),
    color = foreground,
    modifier =
      modifier
        .clip(RoundedCornerShape(Radius.pill))
        .background(background)
        .padding(horizontal = 6.dp, vertical = 1.dp),
  )
}

enum class BadgeTone {
  Brand,
  Warn,
}

@Composable
fun DividerLine(modifier: Modifier = Modifier) {
  Box(modifier = modifier.fillMaxWidth().height(1.dp).background(MoreMoneyTheme.colors.line))
}

/** 占位高度，防止内容被 FAB 与底部栏遮住。 */
@Composable
fun BottomSpacer(height: Int = 120) {
  Spacer(Modifier.height(height.dp))
}

@Composable
fun CardColumn(
  modifier: Modifier = Modifier,
  content: @Composable ColumnScope.() -> Unit,
) {
  val colors = MoreMoneyTheme.colors
  Column(
    modifier =
      modifier
        .fillMaxWidth()
        .clip(RoundedCornerShape(Radius.card))
        .background(colors.surface)
        .border(1.dp, colors.line, RoundedCornerShape(Radius.card)),
    content = content,
  )
}
