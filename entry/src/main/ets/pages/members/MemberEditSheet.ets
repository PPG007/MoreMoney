import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { memberColorOf, withAlpha } from '../../theme/Palette';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { PrimaryButton } from '../../components/base/PrimaryButton';
import { ToggleRow } from '../../components/base/ToggleRow';

export class MemberDraft {
  id: string = '';
  name: string = '';
  initial: string = '';
  colorKey: string = 'self';
  isDefault: boolean = false;
}

class MemberColorOption {
  key: string = '';
  label: string = '';
}

@ComponentV2
export struct MemberEditSheet {
  @Param visible: boolean = false;
  @Param isEdit: boolean = false;
  @Param initialId: string = '';
  @Param initialName: string = '';
  @Param initialColorKey: string = 'self';
  @Param initialDefault: boolean = false;
  @Event onSave: (draft: MemberDraft) => void = (draft: MemberDraft) => {
  };
  @Event onClose: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local name: string = '';
  @Local colorKey: string = 'self';
  @Local isDefault: boolean = false;
  @Local errorText: string = '';

  @Monitor('visible')
  onVisibleChanged(): void {
    if (this.visible) {
      this.name = this.initialName;
      this.colorKey = this.initialColorKey;
      this.isDefault = this.initialDefault;
      this.errorText = '';
    }
  }

  private options(): MemberColorOption[] {
    const keys: string[] = ['self', 'family', 'child', 'c6', 'c8', 'c3'];
    const labels: string[] = ['自己', '家人', '孩子', '紫色', '红色', '绿色'];
    const list: MemberColorOption[] = [];
    for (let i = 0; i < keys.length; i++) {
      const option: MemberColorOption = new MemberColorOption();
      option.key = keys[i];
      option.label = labels[i];
      list.push(option);
    }
    return list;
  }

  private initialOf(name: string): string {
    const trimmed: string = name.trim();
    return trimmed.length === 0 ? '' : trimmed.substring(0, 1);
  }

  private colorOf(key: string): string {
    return memberColorOf(key, this.ui.isDark);
  }

  private submit(): void {
    const trimmed: string = this.name.trim();
    if (trimmed.length === 0) {
      this.errorText = '请输入成员名称';
      return;
    }
    if (trimmed.length > 8) {
      this.errorText = '名称最多 8 个字';
      return;
    }
    const draft: MemberDraft = new MemberDraft();
    draft.id = this.initialId;
    draft.name = trimmed;
    draft.initial = this.initialOf(trimmed);
    draft.colorKey = this.colorKey;
    draft.isDefault = this.isDefault;
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
            Text(this.isEdit ? '编辑成员' : '新建成员')
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

          Row({ space: 11 }) {
            Text(this.initialOf(this.name))
              .fontSize(AppFont.body)
              .fontWeight(AppFont.bold)
              .fontColor(this.colorOf(this.colorKey))
              .textAlign(TextAlign.Center)
              .width(44)
              .height(44)
              .borderRadius(22)
              .backgroundColor(withAlpha(this.colorOf(this.colorKey), 0.15))
            TextInput({ text: this.name, placeholder: '成员名称' })
              .layoutWeight(1)
              .height(44)
              .fontSize(AppFont.row)
              .fontColor($r('app.color.ink'))
              .placeholderColor($r('app.color.ink_3'))
              .backgroundColor($r('app.color.surface_2'))
              .borderRadius(Radius.input)
              .maxLength(8)
              .onChange((value: string) => {
                this.name = value;
                this.errorText = '';
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          if (this.errorText.length > 0) {
            Text(this.errorText)
              .fontSize(AppFont.micro)
              .fontColor($r('app.color.expense'))
              .width('100%')
          }

          Column({ space: 8 }) {
            Text('颜色')
              .fontSize(AppFont.micro)
              .fontColor($r('app.color.ink_3'))
              .width('100%')
            Row({ space: 10 }) {
              ForEach(this.options(), (option: MemberColorOption) => {
                Stack() {
                  if (this.colorKey === option.key) {
                    Image($r('app.media.ic_check'))
                      .width(15)
                      .height(15)
                      .fillColor($r('app.color.surface'))
                  }
                }
                .width(34)
                .height(34)
                .borderRadius(17)
                .backgroundColor(this.colorOf(option.key))
                .border({
                  width: 2,
                  color: this.colorKey === option.key ? $r('app.color.ink') : Color.Transparent
                })
                .onClick(() => {
                  this.colorKey = option.key;
                })
              }, (option: MemberColorOption) => option.key)
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          ToggleRow({
            title: '设为默认',
            subtitle: '记一笔时默认选中该成员',
            isOn: this.isDefault,
            onChange: (isOn: boolean) => {
              this.isDefault = isOn;
            }
          })

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
