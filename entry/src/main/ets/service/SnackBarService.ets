import { UiStore } from '../state/UiStore';

export class SnackBarOptions {
  message: string = '';
  actionLabel: string = '';
  durationMs: number = 5000;
  onAction: () => void = () => {
  };
}

export class SnackBarService {
  private static timer: number = -1;
  private static action: () => void = () => {
  };

  static show(options: SnackBarOptions): void {
    const ui = UiStore.instance();
    ui.snackbar.message = options.message;
    ui.snackbar.actionLabel = options.actionLabel;
    ui.snackbar.visible = true;
    ui.snackbar.token += 1;
    SnackBarService.action = options.onAction;
    SnackBarService.clearTimer();
    SnackBarService.timer = setTimeout(() => {
      SnackBarService.dismiss();
    }, options.durationMs);
  }

  static dismiss(): void {
    const ui = UiStore.instance();
    ui.snackbar.visible = false;
    ui.snackbar.actionLabel = '';
    SnackBarService.action = () => {
    };
    SnackBarService.clearTimer();
  }

  static runAction(): void {
    const action: () => void = SnackBarService.action;
    SnackBarService.dismiss();
    action();
  }

  private static clearTimer(): void {
    if (SnackBarService.timer !== -1) {
      clearTimeout(SnackBarService.timer);
      SnackBarService.timer = -1;
    }
  }
}
