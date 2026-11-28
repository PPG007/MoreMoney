package com.github.ppg007.moremoney.models

/** 账本预算周期。一个账本只能配置其中一个周期，设置后自动按周期重复。 */
enum class BudgetCycle {
  YEAR,
  QUARTER,
  MONTH,
}
