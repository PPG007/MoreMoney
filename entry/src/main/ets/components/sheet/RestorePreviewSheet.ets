import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { PrivatePrompt, RestoreSummary } from '../../service/BackupService';
import { PrimaryButton } from '../../components/base/PrimaryButton';
import { SecondaryButton } from '../../components/base/SecondaryButton';

@ComponentV2
export struct RestorePreviewSheet {
  @Param visible: boolean = false;
  @Param summary: RestoreSummary | null = null;
  @Param busy: boolean = false;
  @Event onConfirm: (passwords: Record<string, string>) => void =
    (passwords: Record<string, string>) => {
    };
  @Event onClose: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local passwords: Record<string, string> = {};

  @Monitor('visible')
  onVisibleChanged(): void {
    if (this.visible) {
      this.passwords = {};
    }
  }

  private prompts(): PrivatePrompt[] {
    return this.summary === null ? [] : this.summary.prompts;
  }

  private canConfirm(): boolean {
    if (this.summary === null || this.busy) {
      return false;
    }
    for (const prompt of this.prompts()) {
      const value: string | undefined = this.passwords[prompt.bookId];
      if (value === undefined || value.length === 0) {
        return false;
      }
    }
    return true;
  }

  @Builder
  stat(label: string, value: string) {
    Column({ space: 2 }) {
      Text(value)
        .fontSize(AppFont.subTitle)
        .fontWeight(AppFont.bold)
        .fontColor($r('app.color.ink'))
      Text(label)
        .fontSize(AppFont.caption)
        .fontColor($r('app.color.ink_3'))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    if (this.visible) {
      Stack({ alignContent: Alignment.Bottom }) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.scrim'))
          .onClick(() => {
            this.onClose();
          })

        Scroll() {
          Column({ space: Space.x3 }) {
            Row() {
              Text('恢复预览')
                .fontSize(AppFont.subTitle)
                .fontWeight(AppFont.bold)
                .fontColor($r('app.color.ink'))
                .layoutWeight(1)
              Text('取消')
                .fontSize(AppFont.settings)
                .fontColor($r('app.color.ink_3'))
                .onClick(() => {
                  this.onClose();
                })
            }
            .width('100%')

            Row() {
              this.stat('账本', this.summary === null ? '0' : this.summary.books.toString())
              this.stat('流水', this.summary === null ? '0' : this.summary.txns.toString())
              this.stat('成员', this.summary === null ? '0' : this.summary.members.toString())
              this.stat('预算', this.summary === null ? '0' : this.summary.budgets.toString())
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })
            .borderRadius(Radius.card)
            .backgroundColor($r('app.color.surface_2'))

            Text('恢复会覆盖当前全部数据，且不可撤销。')
              .fontSize(AppFont.caption)
              .fontColor($r('app.color.expense'))
              .width('100%')

            if (this.prompts().length > 0) {
              Text('私密账本需要输入密码')
                .fontSize(AppFont.micro)
                .fontWeight(AppFont.semibold)
                .fontColor($r('app.color.ink_2'))
                .width('100%')
              ForEach(this.prompts(), (prompt: PrivatePrompt) => {
                Column({ space: 4 }) {
                  Text(prompt.name)
                    .fontSize(AppFont.caption)
                    .fontColor($r('app.color.ink_3'))
                    .width('100%')
                  TextInput({ text: this.passwords[prompt.bookId], placeholder: '密码' })
                    .width('100%')
                    .height(44)
                    .type(InputType.Password)
                    .fontSize(AppFont.settings)
                    .fontColor($r('app.color.ink'))
                    .placeholderColor($r('app.color.ink_3'))
                    .backgroundColor($r('app.color.surface_2'))
                    .borderRadius(Radius.input)
                    .maxLength(20)
                    .onChange((value: string) => {
                      this.passwords[prompt.bookId] = value;
                    })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
              }, (prompt: PrivatePrompt) => prompt.bookId)
            }

            PrimaryButton({
              label: this.busy ? '恢复中…' : '确认恢复',
              isEnabled: this.canConfirm(),
              onTap: () => {
                if (this.canConfirm()) {
                  this.onConfirm(this.passwords);
                }
              }
            })
            SecondaryButton({
              label: '取消',
              onTap: () => {
                this.onClose();
              }
            })
          }
          .width('100%')
          .padding({ left: Space.x7, right: Space.x7, top: 22, bottom: Space.x8 + 10 })
        }
        .constraintSize({ maxHeight: '86%' })
        .borderRadius({ topLeft: Radius.sheet, topRight: Radius.sheet })
        .backgroundColor($r('app.color.surface'))
        .shadow(Shadow.sheet(this.ui.isDark))
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
    }
  }
}
