import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { PrimaryButton } from '../../components/base/PrimaryButton';

export class GroupDraft {
  id: string = '';
  name: string = '';
}

@ComponentV2
export struct GroupEditSheet {
  @Param visible: boolean = false;
  @Param isEdit: boolean = false;
  @Param initialId: string = '';
  @Param initialName: string = '';
  @Event onSave: (draft: GroupDraft) => void = (draft: GroupDraft) => {
  };
  @Event onClose: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local name: string = '';
  @Local errorText: string = '';

  @Monitor('visible')
  onVisibleChanged(): void {
    if (this.visible) {
      this.name = this.initialName;
      this.errorText = '';
    }
  }

  private submit(): void {
    const trimmed: string = this.name.trim();
    if (trimmed.length === 0) {
      this.errorText = '请输入分组名称';
      return;
    }
    if (trimmed.length > 6) {
      this.errorText = '分组名最多 6 个字';
      return;
    }
    const draft: GroupDraft = new GroupDraft();
    draft.id = this.initialId;
    draft.name = trimmed;
    this.onSave(draft);
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
            Text(this.isEdit ? '重命名分组' : '新建分组')
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

          TextInput({ text: this.name, placeholder: '分组名称' })
            .width('100%')
            .height(44)
            .fontSize(AppFont.row)
            .fontColor($r('app.color.ink'))
            .placeholderColor($r('app.color.ink_3'))
            .backgroundColor($r('app.color.surface_2'))
            .borderRadius(Radius.input)
            .maxLength(6)
            .onChange((value: string) => {
              this.name = value;
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
