package com.github.ppg007.moremoney.util

import java.util.UUID

/** ID 生成：使用随机 UUID。 */
object IdUtil {
  fun next(): String = UUID.randomUUID().toString()
}
