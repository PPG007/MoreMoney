import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { PrivateBookService } from '../../service/PrivateBookService';
import { ScreenPrivacyService } from '../../service/ScreenPrivacyService';
import { PrimaryButton } from '../../components/base/PrimaryButton';
import { SecondaryButton } from '../../components/base/SecondaryButton';

@ComponentV2
export struct UnlockSheet {
  @Param visible: boolean = false;
  @Param bookId: string = '';
  @Param bookName: string = '';
  @Event onUnlocked: (bookId: string) => void = (bookId: string) => {
  };
  @Event onClose: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local password: string = '';
  @Local errorText: string = '';
  @Local bioAvailable: boolean = false;
  @Local lockSeconds: number = 0;
  private timerId: number = -1;

  aboutToDisappear(): void {
    this.stopTimer();
  }

  @Monitor('visible')
  onVisibleChanged(): void {
    if (this.visible) {
      this.password = '';
      this.errorText = '';
      this.bioAvailable = PrivateBookService.biometricAvailable();
      this.lockSeconds = PrivateBookService.remainingLockSeconds(this.bookId);
      this.startTimer();
      const context = this.getUIContext().getHostContext();
      if (context !== undefined) {
        ScreenPrivacyService.enable(context).catch(() => {
        });
      }
    } else {
      this.stopTimer();
      const context = this.getUIContext().getHostContext();
      if (context !== undefined) {
        ScreenPrivacyService.disable(context).catch(() => {
        });
      }
    }
  }

  private startTimer(): void {
    this.stopTimer();
    this.timerId = setInterval(() => {
      this.lockSeconds = PrivateBookService.remainingLockSeconds(this.bookId);
    }, 1000);
  }

  private stopTimer(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private finishUnlock(): void {
    this.ui.unlockBook(this.bookId, 5);
    this.stopTimer();
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      ScreenPrivacyService.disable(context).catch(() => {
      });
    }
    this.onUnlocked(this.bookId);
  }

  private async submit(): Promise<void> {
    if (this.lockSeconds > 0) {
      this.errorText = '已锁定，请 '.concat(this.lockSeconds.toString()).concat(' 秒后重试');
      return;
    }
    if (this.password.length === 0) {
      this.errorText = '请输入密码';
      return;
    }
    const ok: boolean = await PrivateBookService.verify(this.bookId, this.password);
    if (ok) {
      this.finishUnlock();
      return;
    }
    const remain: number = PrivateBookService.remainingLockSeconds(this.bookId);
    if (remain > 0) {
      this.lockSeconds = remain;
      this.errorText = '错误次数过多，请 '.concat(remain.toString()).concat(' 秒后重试');
    } else {
      this.errorText = '密码错误，还可尝试 '.concat(PrivateBookService.remainingAttempts(this.bookId).toString())
        .concat(' 次');
    }
    this.password = '';
  }

  private async biometric(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    const ok: boolean = await PrivateBookService.authenticateBiometric(context);
    if (ok) {
      this.finishUnlock();
    } else {
      this.errorText = '生物识别未通过，请使用密码';
    }
  }

  private showForgot(): void {
    AlertDialog.show({
      title: '忘记密码',
      message: '密码无法恢复。请通过备份恢复数据，或删除该账本后重新创建。',
      primaryButton: {
        value: '知道了',
        action: () => {
        }
      }
    });
  }

  private close(): void {
    this.stopTimer();
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      ScreenPrivacyService.disable(context).catch(() => {
      });
    }
    this.onClose();
  }

  build() {
    if (this.visible) {
      Stack({ alignContent: Alignment.Bottom }) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.scrim'))
          .onClick(() => {
            this.close();
          })

        Column({ space: Space.x4 }) {
          Stack() {
            Image($r('app.media.ic_lock'))
              .width(28)
              .height(28)
              .fillColor($r('app.color.brand_ink'))
          }
          .width(60)
          .height(60)
          .borderRadius(22)
          .backgroundColor($r('app.color.brand_wash'))
          .alignSelf(ItemAlign.Start)

          Text('解锁「'.concat(this.bookName).concat('」'))
            .fontSize(AppFont.bookTitle)
            .fontWeight(AppFont.bold)
            .fontColor($r('app.color.ink'))
            .width('100%')
          Text('请输入密码查看该账本')
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.ink_3'))
            .width('100%')

          TextInput({ text: this.password, placeholder: '密码' })
            .width('100%')
            .height(45)
            .type(InputType.Password)
            .fontSize(AppFont.settings)
            .fontColor($r('app.color.ink'))
            .placeholderColor($r('app.color.ink_3'))
            .backgroundColor($r('app.color.surface_2'))
            .borderRadius(13)
            .maxLength(20)
            .onChange((value: string) => {
              this.password = value;
              this.errorText = '';
            })

          if (this.errorText.length > 0) {
            Text(this.errorText)
              .fontSize(AppFont.micro)
              .fontColor($r('app.color.expense'))
              .width('100%')
          }

          if (this.bioAvailable) {
            Row({ space: 6 }) {
              Image($r('app.media.ic_fingerprint'))
                .width(17)
                .height(17)
                .fillColor($r('app.color.brand_ink'))
              Text('使用指纹/面容解锁')
                .fontSize(AppFont.micro)
                .fontWeight(AppFont.semibold)
                .fontColor($r('app.color.brand_ink'))
            }
            .width('100%')
            .height(40)
            .justifyContent(FlexAlign.Center)
            .borderRadius(Radius.input)
            .backgroundColor($r('app.color.brand_wash'))
            .onClick(() => {
              this.biometric();
            })
          }

          Row({ space: Space.x2 }) {
            Column() {
              SecondaryButton({
                label: '取消',
                onTap: () => {
                  this.close();
                }
              })
            }
            .layoutWeight(1)
            Column() {
              PrimaryButton({
                label: '解锁',
                isEnabled: this.lockSeconds === 0,
                onTap: () => {
                  this.submit();
                }
              })
            }
            .layoutWeight(1.5)
          }
          .width('100%')

          Text('忘记密码？')
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.ink_3'))
            .decoration({ type: TextDecorationType.Underline, color: $r('app.color.ink_3') })
            .onClick(() => {
              this.showForgot();
            })
        }
        .width('100%')
        .padding({ left: 21, right: 21, top: 24, bottom: 26 + this.ui.bottomInset })
        .borderRadius({ topLeft: Radius.sheet, topRight: Radius.sheet })
        .backgroundColor($r('app.color.surface'))
        .shadow(Shadow.sheet(this.ui.isDark))
      }
      .width('100%')
      .height('100%')
    }
  }
}
