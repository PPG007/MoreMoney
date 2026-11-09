import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { PrimaryButton } from '../../components/base/PrimaryButton';

@ComponentV2
export struct PasswordSetupSheet {
  @Param visible: boolean = false;
  @Param isChange: boolean = false;
  @Event onSave: (oldPassword: string, newPassword: string) => void =
    (oldPassword: string, newPassword: string) => {
    };
  @Event onClose: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local oldPassword: string = '';
  @Local newPassword: string = '';
  @Local confirmPassword: string = '';
  @Local errorText: string = '';

  @Monitor('visible')
  onVisibleChanged(): void {
    if (this.visible) {
      this.oldPassword = '';
      this.newPassword = '';
      this.confirmPassword = '';
      this.errorText = '';
    }
  }

  private submit(): void {
    if (this.isChange && this.oldPassword.length === 0) {
      this.errorText = '请输入旧密码';
      return;
    }
    if (this.newPassword.length < 4 || this.newPassword.length > 20) {
      this.errorText = '密码需为 4–20 位';
      return;
    }
    if (this.newPassword !== this.confirmPassword) {
      this.errorText = '两次输入的密码不一致';
      return;
    }
    this.onSave(this.oldPassword, this.newPassword);
  }

  @Builder
  passwordField(label: string, placeholder: string, text: string, onChange: (value: string) => void) {
    Column({ space: 5 }) {
      Text(label)
        .fontSize(AppFont.micro)
        .fontColor($r('app.color.ink_3'))
        .width('100%')
      TextInput({ text: text, placeholder: placeholder })
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
          onChange(value);
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
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

        Column({ space: Space.x4 }) {
          Row() {
            Text(this.isChange ? '修改密码' : '设置密码')
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

          if (this.isChange) {
            this.passwordField('旧密码', '请输入旧密码', this.oldPassword, (value: string) => {
              this.oldPassword = value;
              this.errorText = '';
            })
          }
          this.passwordField('新密码', '4–20 位字母、数字或符号', this.newPassword, (value: string) => {
            this.newPassword = value;
            this.errorText = '';
          })
          this.passwordField('确认密码', '再次输入新密码', this.confirmPassword, (value: string) => {
            this.confirmPassword = value;
            this.errorText = '';
          })

          if (this.errorText.length > 0) {
            Text(this.errorText)
              .fontSize(AppFont.micro)
              .fontColor($r('app.color.expense'))
              .width('100%')
          }

          PrimaryButton({
            label: '保存',
            onTap: () => {
              this.submit();
            }
          })
        }
        .width('100%')
        .padding({ left: Space.x7, right: Space.x7, top: 22, bottom: Space.x8 + 10 })
        .borderRadius({ topLeft: Radius.sheet, topRight: Radius.sheet })
        .backgroundColor($r('app.color.surface'))
        .shadow(Shadow.sheet(this.ui.isDark))
      }
      .width('100%')
      .height('100%')
    }
  }
}
