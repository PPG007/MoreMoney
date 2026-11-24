package com.github.ppg007.moremoney.util

import android.os.Build
import java.text.Collator
import java.util.Locale

/**
 * 拼音工具。
 *
 * - 排序：统一使用 `Collator(Locale.CHINA)`，所有 API 级别一致；
 * - 转换：API 29+ 使用系统 `android.icu.text.Transliterator("Han-Latin")`；
 * - API 26–28（以及 JVM 单元测试）降级为内置常用字表，无法转换的字符保留原样。
 *
 * 降级只会影响自定义名称的拼音搜索，不改变排序与已存种子数据的拼音列。
 */
object PinyinUtil {
  fun key(name: String): String {
    val trimmed = name.trim()
    if (trimmed.isEmpty()) {
      return ""
    }
    val modern = transliterateModern(trimmed)
    if (!modern.isNullOrEmpty()) {
      return modern
    }
    return fallback(trimmed)
  }

  fun compare(a: String, b: String): Int = Collator.getInstance(Locale.CHINA).compare(a, b)

  /** 关键词是否命中：中文子串、拼音全拼或拼音首字母。 */
  fun matches(name: String, keyword: String): Boolean {
    val needle = keyword.trim().lowercase()
    if (needle.isEmpty()) {
      return true
    }
    if (name.lowercase().contains(needle)) {
      return true
    }
    val pinyin = key(name)
    if (pinyin.contains(needle)) {
      return true
    }
    return initialsOf(name).contains(needle)
  }

  /** 每个字取拼音首字母：餐饮 → cy，出行 → cx。 */
  private fun initialsOf(name: String): String {
    val builder = StringBuilder()
    for (ch in name) {
      when {
        ch in 'a'..'z' || ch in 'A'..'Z' || ch in '0'..'9' -> builder.append(ch.lowercaseChar())
        ch.isWhitespace() -> Unit
        else -> key(ch.toString()).firstOrNull { it in 'a'..'z' || it in '0'..'9' }?.let { builder.append(it) }
      }
    }
    return builder.toString()
  }

  private fun transliterateModern(text: String): String? {
    // API 26–28 没有系统汉字转拉丁能力，统一走内置字表。
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
      return null
    }
    return try {
      val transliterator = android.icu.text.Transliterator.getInstance("Han-Latin")
      val raw = transliterator.transliterate(text).lowercase()
      val plain = normalize(raw)
      plain.ifEmpty { null }
    } catch (error: Throwable) {
      null
    }
  }

  private fun normalize(raw: String): String {
    val decomposed = java.text.Normalizer.normalize(raw, java.text.Normalizer.Form.NFD)
    val builder = StringBuilder()
    for (ch in decomposed) {
      when {
        ch in '̀'..'ͯ' -> Unit
        ch in 'a'..'z' -> builder.append(ch)
        ch in '0'..'9' -> builder.append(ch)
        else -> Unit
      }
    }
    return builder.toString()
  }

  private fun fallback(text: String): String {
    val builder = StringBuilder()
    var i = 0
    while (i < text.length) {
      // 优先匹配两字及以上的常用词，处理多音字。
      val pair = if (i + 1 < text.length) text.substring(i, i + 2) else ""
      val wordHit = WORD_MAP[pair]
      if (wordHit != null) {
        builder.append(wordHit)
        i += 2
        continue
      }
      val ch = text[i]
      when {
        ch in 'a'..'z' || ch in 'A'..'Z' -> builder.append(ch.lowercaseChar())
        ch in '0'..'9' -> builder.append(ch)
        CHAR_MAP.containsKey(ch) -> builder.append(CHAR_MAP[ch])
        else -> Unit
      }
      i += 1
    }
    return builder.toString().ifEmpty { text.lowercase() }
  }

  private val WORD_MAP =
    mapOf(
      "出行" to "chuxing",
      "银行" to "yinhang",
      "行李" to "xingli",
      "重要" to "zhongyao",
      "重庆" to "chongqing",
      "长大" to "zhangda",
      "音乐" to "yinyue",
      "快乐" to "kuaile",
      "便宜" to "pianyi",
    )

  private val CHAR_MAP: Map<Char, String> =
    mapOf(
      '餐' to "can", '饮' to "yin", '食' to "shi", '饭' to "fan", '早' to "zao", '午' to "wu",
      '晚' to "wan", '茶' to "cha", '咖' to "ka", '啡' to "fei", '水' to "shui", '果' to "guo",
      '菜' to "cai", '肉' to "rou", '酒' to "jiu", '奶' to "nai",
      '出' to "chu", '行' to "xing", '交' to "jiao", '通' to "tong", '车' to "che", '地' to "di",
      '铁' to "tie", '飞' to "fei", '机' to "ji", '打' to "da", '油' to "you", '停' to "ting",
      '居' to "ju", '家' to "jia", '房' to "fang", '租' to "zu", '电' to "dian", '煤' to "mei",
      '气' to "qi", '物' to "wu", '业' to "ye", '维' to "wei", '修' to "xiu",
      '购' to "gou", '买' to "mai", '衣' to "yi", '服' to "fu", '鞋' to "xie", '包' to "bao",
      '化' to "hua", '妆' to "zhuang", '品' to "pin", '日' to "ri", '用' to "yong",
      '娱' to "yu", '乐' to "le", '玩' to "wan", '游' to "you", '戏' to "xi", '电' to "dian",
      '影' to "ying", '书' to "shu", '旅' to "lv", '行' to "xing",
      '医' to "yi", '疗' to "liao", '药' to "yao", '诊' to "zhen", '检' to "jian", '查' to "cha",
      '学' to "xue", '习' to "xi", '教' to "jiao", '育' to "yu", '培' to "pei", '训' to "xun",
      '通' to "tong", '讯' to "xun", '话' to "hua", '网' to "wang", '费' to "fei",
      '其' to "qi", '他' to "ta", '自' to "zi", '己' to "ji", '人' to "ren", '孩' to "hai",
      '子' to "zi", '朋' to "peng", '友' to "you", '父' to "fu", '母' to "mu", '老' to "lao",
      '公' to "gong", '婆' to "po", '账' to "zhang", '本' to "ben", '记' to "ji", '账' to "zhang",
      '装' to "zhuang", '修' to "xiu", '旅' to "lv", '日' to "ri", '常' to "chang",
      '宠' to "chong", '物' to "wu", '礼' to "li", '物' to "wu", '红' to "hong", '包' to "bao",
      '保' to "bao", '险' to "xian", '税' to "shui", '捐' to "juan", '款' to "kuan",
      '工' to "gong", '资' to "zi", '奖' to "jiang", '金' to "jin", '投' to "tou", '资' to "zi",
      '还' to "huan", '贷' to "dai", '信' to "xin", '卡' to "ka", '转' to "zhuan", '账' to "zhang",
      '零' to "ling", '花' to "hua", '固' to "gu", '定' to "ding", '储' to "chu", '蓄' to "xu",
    )
}
