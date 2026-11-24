package com.github.ppg007.moremoney

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.github.ppg007.moremoney.ui.components.base.SnackbarHost
import com.github.ppg007.moremoney.ui.theme.MoreMoneyTheme

class MainActivity : ComponentActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    enableEdgeToEdge()
    val container = appContainer
    setContent {
      MoreMoneyTheme {
        Surface(
          modifier = Modifier.fillMaxSize(),
          color = MoreMoneyTheme.colors.background,
        ) {
          MainRoot(container)
        }
      }
    }
  }
}

@Composable
private fun MainRoot(container: AppContainer) {
  Box(modifier = Modifier.fillMaxSize()) {
    MainNavigation(container)
    SnackbarHost(ui = container.ui)
  }
}
