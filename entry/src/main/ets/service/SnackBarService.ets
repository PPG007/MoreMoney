import { UiStore } from '../state/UiStore';

export enum SnackTone {
  AUTO = 'auto',
  SUCCESS = 'success',
  ERROR = 'error',
  WARNING = 'warning',
  INFO = 'info'
}

export class SnackBarOptions {
  message: string = '';
  actionLabel: string = '';
  durationMs: number = 5000;
  tone: SnackTone = SnackTone.AUTO;
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
    ui.snackbar.tone = SnackBarService.resolveTone(options);
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

  private static resolveTone(options: SnackBarOptions): string {
    if (options.tone !== SnackTone.AUTO) {
      return options.tone;
    }
    const message: string = options.message;
    if (message.indexOf('失败') >= 0 || message.indexOf('错误') >= 0 || message.indexOf('无法') >= 0 ||
      message.indexOf('不能') >= 0 || message.indexOf('不可') >= 0) {
      return SnackTone.ERROR;
    }
    if (message.indexOf('请') >= 0 || message.indexOf('至少') >= 0 || message.indexOf('需要') >= 0) {
      return SnackTone.WARNING;
    }
    if (message.indexOf('已') >= 0 || message.indexOf('成功') >= 0) {
      return SnackTone.SUCCESS;
    }
    return SnackTone.INFO;
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
