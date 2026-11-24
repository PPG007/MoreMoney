package com.github.ppg007.moremoney.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

private val LightColorScheme =
  lightColorScheme(
    primary = LightMoreMoneyColors.buttonBackground,
    onPrimary = LightMoreMoneyColors.buttonForeground,
    primaryContainer = LightMoreMoneyColors.brandSoft,
    onPrimaryContainer = LightMoreMoneyColors.brandInk,
    secondary = LightMoreMoneyColors.brand,
    onSecondary = Color.White,
    secondaryContainer = LightMoreMoneyColors.brandWash,
    onSecondaryContainer = LightMoreMoneyColors.brandInk,
    tertiary = LightMoreMoneyColors.good,
    onTertiary = Color.White,
    background = LightMoreMoneyColors.background,
    onBackground = LightMoreMoneyColors.ink,
    surface = LightMoreMoneyColors.surface,
    onSurface = LightMoreMoneyColors.ink,
    surfaceVariant = LightMoreMoneyColors.surface2,
    onSurfaceVariant = LightMoreMoneyColors.ink2,
    outline = LightMoreMoneyColors.line,
    outlineVariant = LightMoreMoneyColors.surface3,
    error = LightMoreMoneyColors.expense,
    onError = Color.White,
    scrim = LightMoreMoneyColors.scrim,
  )

private val DarkColorScheme =
  darkColorScheme(
    primary = DarkMoreMoneyColors.buttonBackground,
    onPrimary = DarkMoreMoneyColors.buttonForeground,
    primaryContainer = DarkMoreMoneyColors.brandSoft,
    onPrimaryContainer = DarkMoreMoneyColors.brandInk,
    secondary = DarkMoreMoneyColors.brand,
    onSecondary = DarkMoreMoneyColors.buttonForeground,
    secondaryContainer = DarkMoreMoneyColors.brandWash,
    onSecondaryContainer = DarkMoreMoneyColors.brandInk,
    tertiary = DarkMoreMoneyColors.good,
    onTertiary = Color(0xFF10241B),
    background = DarkMoreMoneyColors.background,
    onBackground = DarkMoreMoneyColors.ink,
    surface = DarkMoreMoneyColors.surface,
    onSurface = DarkMoreMoneyColors.ink,
    surfaceVariant = DarkMoreMoneyColors.surface2,
    onSurfaceVariant = DarkMoreMoneyColors.ink2,
    outline = DarkMoreMoneyColors.line,
    outlineVariant = DarkMoreMoneyColors.surface3,
    error = DarkMoreMoneyColors.expense,
    onError = Color(0xFF2B0B0E),
    scrim = DarkMoreMoneyColors.scrim,
  )

private val MoreMoneyShapes =
  Shapes(
    extraSmall = RoundedCornerShape(Radius.input),
    small = RoundedCornerShape(Radius.chip),
    medium = RoundedCornerShape(Radius.card),
    large = RoundedCornerShape(Radius.cardLg),
    extraLarge = RoundedCornerShape(Radius.sheet),
  )

private val LocalMoreMoneyColors = staticCompositionLocalOf { LightMoreMoneyColors }

/** 当前是否深色主题；用于图表色等无法从 ColorScheme 推导的 token。 */
@Composable
@ReadOnlyComposable
fun isDarkTheme(): Boolean = isSystemInDarkTheme()

/** 访问设计 token：`MoreMoneyTheme.colors.brand`。 */
object MoreMoneyTheme {
  val colors: MoreMoneyColors
    @Composable
    @ReadOnlyComposable
    get() = LocalMoreMoneyColors.current
}

@Composable
fun MoreMoneyTheme(
  darkTheme: Boolean = isSystemInDarkTheme(),
  content: @Composable () -> Unit,
) {
  val colors = if (darkTheme) DarkMoreMoneyColors else LightMoreMoneyColors

  CompositionLocalProvider(LocalMoreMoneyColors provides colors) {
    MaterialTheme(
      colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme,
      typography = MoreMoneyTypography,
      shapes = MoreMoneyShapes,
      content = content,
    )
  }
}
