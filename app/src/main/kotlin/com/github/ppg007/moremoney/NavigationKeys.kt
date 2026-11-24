package com.github.ppg007.moremoney

import androidx.navigation3.runtime.NavKey
import kotlinx.serialization.Serializable

/**
 * 导航键。
 *
 * 一级 Tab 不进入导航栈；二级页面全部使用 `@Serializable NavKey`，
 * 禁止使用字符串路由。
 */
@Serializable
data object Main : NavKey

/** 记一笔。`txnId` 非空时为编辑已有流水。 */
@Serializable
data class AddTxn(
  val bookId: String = "",
  val dayKey: String = "",
  val txnId: String = "",
) : NavKey

@Serializable
data object BookManage : NavKey

@Serializable
data object CategoryManage : NavKey

@Serializable
data object DataBackup : NavKey

@Serializable
data class Search(
  val bookId: String = "",
) : NavKey
