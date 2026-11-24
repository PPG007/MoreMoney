package com.github.ppg007.moremoney.ui.theme

import androidx.compose.runtime.Immutable
import androidx.compose.ui.graphics.Color

/**
 * MoreMoney 设计 token。
 *
 * 来源：HarmonyOS 版 `entry/src/main/resources/base|dark/element/color.json`。
 * 组件不应直接写十六进制颜色，统一通过 [MoreMoneyTheme.colors] 取用。
 */
@Immutable
data class MoreMoneyColors(
  val background: Color,
  val surface: Color,
  val surface2: Color,
  val surface3: Color,
  val ink: Color,
  val ink2: Color,
  val ink3: Color,
  val line: Color,
  val chartSurface: Color,
  val tabBackground: Color,
  val scrim: Color,
  val brand: Color,
  val brandInk: Color,
  val brandSoft: Color,
  val brandWash: Color,
  val buttonBackground: Color,
  val buttonForeground: Color,
  val expense: Color,
  val good: Color,
  val warn: Color,
  val heroStart: Color,
  val heroMiddle: Color,
  val heroEnd: Color,
  val onHero: Color,
  val heroGlass: Color,
  val heroLine: Color,
  val heroGlow: Color,
)

internal val LightMoreMoneyColors =
  MoreMoneyColors(
    background = Color(0xFFFAF8F7),
    surface = Color(0xFFFFFFFF),
    surface2 = Color(0xFFF5F0F1),
    surface3 = Color(0xFFECE4E6),
    ink = Color(0xFF272231),
    ink2 = Color(0xFF6B6272),
    ink3 = Color(0xFF756B7B),
    line = Color(0xFFEEE4E6),
    chartSurface = Color(0xFFFFFFFF),
    tabBackground = Color(0xD6FFFFFF),
    scrim = Color(0x6B181430),
    brand = Color(0xFF6366F1),
    brandInk = Color(0xFF4338CA),
    brandSoft = Color(0xFFE0E7FF),
    brandWash = Color(0xFFEEF2FF),
    buttonBackground = Color(0xFF4338CA),
    buttonForeground = Color(0xFFFFFFFF),
    expense = Color(0xFFC62F3D),
    good = Color(0xFF137A57),
    warn = Color(0xFF8A5200),
    heroStart = Color(0xFF4F46E5),
    heroMiddle = Color(0xFF4338CA),
    heroEnd = Color(0xFF312E81),
    onHero = Color(0xFFFFFFFF),
    heroGlass = Color(0x4716123C),
    heroLine = Color(0x2EFFFFFF),
    heroGlow = Color(0x2EFFFFFF),
  )

internal val DarkMoreMoneyColors =
  MoreMoneyColors(
    background = Color(0xFF121017),
    surface = Color(0xFF1C1925),
    surface2 = Color(0xFF25212E),
    surface3 = Color(0xFF302A3B),
    ink = Color(0xFFF4F0FA),
    ink2 = Color(0xFFC3BCCD),
    ink3 = Color(0xFF9C93A8),
    line = Color(0xFF332D40),
    chartSurface = Color(0xFF1C1925),
    tabBackground = Color(0xDB1C1925),
    scrim = Color(0x94000000),
    brand = Color(0xFF818CF8),
    brandInk = Color(0xFFA5B4FC),
    brandSoft = Color(0xFF2E2A5E),
    brandWash = Color(0xFF1E1B3A),
    buttonBackground = Color(0xFFA5B4FC),
    buttonForeground = Color(0xFF1E1B3A),
    expense = Color(0xFFFF9A9A),
    good = Color(0xFF4FD1A0),
    warn = Color(0xFFF0B45A),
    heroStart = Color(0xFF312E81),
    heroMiddle = Color(0xFF25225F),
    heroEnd = Color(0xFF181638),
    onHero = Color(0xFFFFFFFF),
    heroGlass = Color(0x17FFFFFF),
    heroLine = Color(0x24FFFFFF),
    heroGlow = Color(0x1F8C96FF),
  )
