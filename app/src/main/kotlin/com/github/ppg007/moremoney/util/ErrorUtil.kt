package com.github.ppg007.moremoney.util

/** 把异常转成可直接展示给用户的中文消息。 */
object ErrorUtil {
  fun messageOf(error: Throwable): String {
    val message = error.message
    return if (message.isNullOrBlank()) error.javaClass.simpleName else message
  }

  fun messageOf(error: Throwable, fallback: String): String {
    val message = error.message
    return if (message.isNullOrBlank()) fallback else message
  }
}
