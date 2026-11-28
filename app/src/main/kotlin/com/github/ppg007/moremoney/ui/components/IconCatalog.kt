package com.github.ppg007.moremoney.ui.components

import androidx.annotation.DrawableRes
import com.github.ppg007.moremoney.R

/**
 * 图标名 → drawable 映射。
 *
 * 数据库里保存的是历史图标名（如 `ic_cat_food`），Android 端通过这里解析，
 * 未知名称统一回退到 `ic_cat_other`，避免因旧数据崩溃。
 */
@DrawableRes
fun iconResOf(name: String): Int =
  when (name) {
    "ic_archive" -> R.drawable.ic_archive
    "ic_back" -> R.drawable.ic_back
    "ic_book" -> R.drawable.ic_book
    "ic_book_daily" -> R.drawable.ic_book_daily
    "ic_book_family" -> R.drawable.ic_book_family
    "ic_book_repair" -> R.drawable.ic_book_repair
    "ic_book_study" -> R.drawable.ic_book_study
    "ic_book_travel" -> R.drawable.ic_book_travel
    "ic_book_work" -> R.drawable.ic_book_work
    "ic_calendar" -> R.drawable.ic_calendar
    "ic_cat_beauty" -> R.drawable.ic_cat_beauty
    "ic_cat_carwash" -> R.drawable.ic_cat_carwash
    "ic_cat_clothing" -> R.drawable.ic_cat_clothing
    "ic_cat_daily" -> R.drawable.ic_cat_daily
    "ic_cat_entertain" -> R.drawable.ic_cat_entertain
    "ic_cat_food" -> R.drawable.ic_cat_food
    "ic_cat_gift" -> R.drawable.ic_cat_gift
    "ic_cat_home" -> R.drawable.ic_cat_home
    "ic_cat_medical" -> R.drawable.ic_cat_medical
    "ic_cat_other" -> R.drawable.ic_cat_other
    "ic_cat_parking" -> R.drawable.ic_cat_parking
    "ic_cat_phone" -> R.drawable.ic_cat_phone
    "ic_cat_power" -> R.drawable.ic_cat_power
    "ic_cat_repair" -> R.drawable.ic_cat_repair
    "ic_cat_shopping" -> R.drawable.ic_cat_shopping
    "ic_cat_social" -> R.drawable.ic_cat_social
    "ic_cat_study" -> R.drawable.ic_cat_study
    "ic_cat_tax" -> R.drawable.ic_cat_tax
    "ic_cat_transport" -> R.drawable.ic_cat_transport
    "ic_cat_travel" -> R.drawable.ic_cat_travel
    "ic_cat_water" -> R.drawable.ic_cat_water
    "ic_cat_work" -> R.drawable.ic_cat_work
    "ic_check" -> R.drawable.ic_check
    "ic_chevron_left" -> R.drawable.ic_chevron_left
    "ic_chevron_right" -> R.drawable.ic_chevron_right
    "ic_close" -> R.drawable.ic_close
    "ic_cloud" -> R.drawable.ic_cloud
    "ic_edit" -> R.drawable.ic_edit
    "ic_eye" -> R.drawable.ic_eye
    "ic_eye_off" -> R.drawable.ic_eye_off
    "ic_file" -> R.drawable.ic_file
    "ic_more" -> R.drawable.ic_more
    "ic_plus" -> R.drawable.ic_plus
    "ic_search" -> R.drawable.ic_search
    "ic_tab_books" -> R.drawable.ic_tab_books
    "ic_tab_budget" -> R.drawable.ic_tab_budget
    "ic_tab_charts" -> R.drawable.ic_tab_charts
    "ic_tab_settings" -> R.drawable.ic_tab_settings
    "ic_trash" -> R.drawable.ic_trash
    "ic_undo" -> R.drawable.ic_undo
    "ic_warning" -> R.drawable.ic_warning
    else -> R.drawable.ic_cat_other
  }

/** 分类图标可选列表（新建/编辑分类时展示）。 */
val CategoryIconNames: List<String> =
  listOf(
    "ic_cat_food",
    "ic_cat_daily",
    "ic_cat_shopping",
    "ic_cat_transport",
    "ic_cat_parking",
    "ic_cat_carwash",
    "ic_cat_social",
    "ic_cat_home",
    "ic_cat_gift",
    "ic_cat_clothing",
    "ic_cat_entertain",
    "ic_cat_beauty",
    "ic_cat_medical",
    "ic_cat_tax",
    "ic_cat_study",
    "ic_cat_water",
    "ic_cat_power",
    "ic_cat_phone",
    "ic_cat_travel",
    "ic_cat_work",
    "ic_cat_repair",
    "ic_cat_other",
  )

/** 账本封面可选列表。 */
val BookIconNames: List<String> =
  listOf(
    "ic_book_daily",
    "ic_book_travel",
    "ic_book_family",
    "ic_book_study",
    "ic_book_work",
    "ic_book_repair",
  )
