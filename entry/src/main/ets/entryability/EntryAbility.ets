import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { SystemBarService } from '../service/SystemBarService';
import { SettingsService } from '../service/SettingsService';
import { UiStore } from '../state/UiStore';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    UiStore.instance().isDark =
      this.context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    SystemBarService.applyFullScreen(windowStage);

    SettingsService.init(this.context).then(() => {
      this.applySavedAppearance();
      this.loadRoot(windowStage);
    }).catch(() => {
      this.applySavedAppearance();
      this.loadRoot(windowStage);
    });
  }

  private applySavedAppearance(): void {
    const mode: number = SettingsService.appearance();
    let colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
    if (mode === 1) {
      colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
    } else if (mode === 2) {
      colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    }
    try {
      this.context.getApplicationContext().setColorMode(colorMode);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    if (mode === 1) {
      UiStore.instance().isDark = false;
    } else if (mode === 2) {
      UiStore.instance().isDark = true;
    }
  }

  private loadRoot(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    UiStore.instance().isDark =
      newConfig.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
