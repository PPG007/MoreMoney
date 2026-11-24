package com.github.ppg007.moremoney.ui.common

import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.github.ppg007.moremoney.AppContainer
import com.github.ppg007.moremoney.appContainer

/** 用应用容器创建 ViewModel，避免每个页面重复写工厂。 */
@Composable
inline fun <reified VM : ViewModel> appViewModel(crossinline create: (AppContainer) -> VM): VM {
  val container = LocalContext.current.appContainer
  return viewModel(
    factory =
      viewModelFactory {
        initializer { create(container) }
      },
  )
}
