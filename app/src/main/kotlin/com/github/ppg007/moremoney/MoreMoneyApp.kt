package com.github.ppg007.moremoney

import android.app.Application
import android.content.Context

class MoreMoneyApp : Application() {
  lateinit var container: AppContainer
    private set

  override fun onCreate() {
    super.onCreate()
    container = AppContainer(this)
  }
}

/** 从任意 Context 获取应用容器（Activity/Composable 均可）。 */
val Context.appContainer: AppContainer
  get() {
    val app = applicationContext
    check(app is MoreMoneyApp) { "Application is not MoreMoneyApp" }
    return app.container
  }
