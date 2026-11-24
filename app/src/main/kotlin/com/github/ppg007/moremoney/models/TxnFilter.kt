package com.github.ppg007.moremoney.models

/** 流水筛选条件；空列表表示不限，时间戳为毫秒闭区间。 */
data class TxnFilter(
  val bookIds: List<String> = emptyList(),
  val startMs: Long = 0,
  val endMs: Long = 0,
)
