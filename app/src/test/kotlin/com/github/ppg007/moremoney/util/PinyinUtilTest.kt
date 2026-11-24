package com.github.ppg007.moremoney.util

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class PinyinUtilTest {
  @Test
  fun transliteratesChineseNames() {
    // API 29+ 使用系统 ICU；JVM 测试走降级字表，结果必须一致。
    assertEquals("canyin", PinyinUtil.key("餐饮"))
    assertEquals("chuxing", PinyinUtil.key("出行"))
    assertEquals("jiaotong", PinyinUtil.key("交通"))
    assertEquals("gouwu", PinyinUtil.key("购物"))
  }

  @Test
  fun keepsEnglishAndNumbersLowercase() {
    assertEquals("food", PinyinUtil.key("Food"))
    assertEquals("123", PinyinUtil.key("123"))
    assertEquals("a1", PinyinUtil.key("A1"))
  }

  @Test
  fun handlesEmptyAndSpaces() {
    assertEquals("", PinyinUtil.key(""))
    assertEquals("", PinyinUtil.key("   "))
  }

  @Test
  fun matchesChineseAndPinyinKeywords() {
    assertTrue(PinyinUtil.matches("餐饮", "餐"))
    assertTrue(PinyinUtil.matches("餐饮", "canyin"))
    assertTrue(PinyinUtil.matches("餐饮", "cy"))
    assertTrue(PinyinUtil.matches("餐饮", "CAN"))
  }
}
