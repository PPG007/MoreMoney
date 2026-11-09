import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { ChartPalette, SeedColors } from '../../theme/Palette';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { PrimaryButton } from '../../components/base/PrimaryButton';
import { ToggleRow } from '../../components/base/ToggleRow';
import { PasswordSetupSheet } from '../../components/sheet/PasswordSetupSheet';
import { formatYuan, parseYuanToCents } from '../../utils/MoneyUtil';

const MAX_BUDGET_CENTS: number = 9999999999;

export class BookDraft {
  id: string = '';
  name: string = '';
  icon: string = 'ic_book_daily';
  color: string = SeedColors.c1;
  wantPrivate: boolean = false;
  newPassword: string = '';
  clearBudget: boolean = false;
  budgetCents: number = 0;
}

class BookIconOption {
  name: string = '';
}

class BookColorOption {
  value: string = '';
}

@ComponentV2
export struct BookEditSheet {
  @Param visible: boolean = false;
  @Param isEdit: boolean = false;
  @Param initialId: string = '';
  @Param initialName: string = '';
  @Param initialIcon: string = 'ic_book_daily';
  @Param initialColor: string = SeedColors.c1;
  @Param initialPrivate: boolean = false;
  @Param initialBudgetCents: number = 0;
  @Event onSave: (draft: BookDraft) => void = (draft: BookDraft) => {
  };
  @Event onClose: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local name: string = '';
  @Local icon: string = 'ic_book_daily';
  @Local color: string = SeedColors.c1;
  @Local privateOn: boolean = false;
  @Local budgetText: string = '';
  @Local showPwd: boolean = false;
  @Local errorText: string = '';

  @Monitor('visible')
  onVisibleChanged(): void {
    if (this.visible) {
      this.name = this.initialName;
      this.icon = this.initialIcon;
      this.color = this.initialColor;
      this.privateOn = this.initialPrivate;
      this.budgetText = this.initialBudgetCents > 0 ? formatYuan(this.initialBudgetCents) : '';
      this.pendingPassword = '';
      this.showPwd = false;
      this.errorText = '';
    }
  }

  private icons(): BookIconOption[] {
    const names: string[] = ['ic_book_daily', 'ic_book_travel', 'ic_book_family', 'ic_book_study',
      'ic_book_work', 'ic_book_repair'];
    const list: BookIconOption[] = [];
    for (const name of names) {
      const option: BookIconOption = new BookIconOption();
      option.name = name;
      list.push(option);
    }
    return list;
  }

  private colors(): BookColorOption[] {
    const values: string[] = [];
    for (let i = 0; i < ChartPalette.slotCount; i++) {
      values.push(ChartPalette.slot(i, this.ui.isDark));
    }
    values.push(SeedColors.c6);
    values.push(SeedColors.c7);
    values.push(SeedColors.c8);
    const list: BookColorOption[] = [];
    for (const value of values) {
      const option: BookColorOption = new BookColorOption();
      option.value = value;
      list.push(option);
    }
    return list;
  }

  private submit(): void {
    const trimmed: string = this.name.trim();
    if (trimmed.length === 0) {
      this.errorText = '请输入账本名称';
      return;
    }
    if (trimmed.length > 12) {
      this.errorText = '名称最多 12 个字';
      return;
    }
    const draft: BookDraft = new BookDraft();
    draft.id = this.initialId;
    draft.name = trimmed;
    draft.icon = this.icon;
    draft.color = this.color;
    draft.wantPrivate = this.privateOn;
    draft.newPassword = this.pendingPassword;
    const raw: string = this.budgetText.trim();
    if (raw.length === 0) {
      draft.clearBudget = true;
      draft.budgetCents = 0;
    } else {
      const cents: number | null = parseYuanToCents(raw);
      if (cents === null) {
        this.errorText = '预算金额格式不正确（最多两位小数）';
        return;
      }
      if (cents > MAX_BUDGET_CENTS) {
        this.errorText = '预算金额超出上限';
        return;
      }
      draft.clearBudget = false;
      draft.budgetCents = cents;
    }
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

        Scroll() {
          Column({ space: Space.x4 }) {
            Row() {
              Text(this.isEdit ? '编辑账本' : '新建账本')
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
              Stack() {
                Image($r('app.media.' + this.icon))
                  .width(23)
                  .height(23)
                  .fillColor(this.color)
              }
              .width(46)
              .height(46)
              .borderRadius(Radius.icon)
              .backgroundColor($r('app.color.surface_2'))
              TextInput({ text: this.name, placeholder: '账本名称' })
                .layoutWeight(1)
                .height(44)
                .fontSize(AppFont.row)
                .fontColor($r('app.color.ink'))
                .placeholderColor($r('app.color.ink_3'))
                .backgroundColor($r('app.color.surface_2'))
                .borderRadius(Radius.input)
                .maxLength(12)
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
              Text('图标')
                .fontSize(AppFont.micro)
                .fontColor($r('app.color.ink_3'))
                .width('100%')
              Row({ space: 9 }) {
                ForEach(this.icons(), (option: BookIconOption) => {
                  Stack() {
                    Image($r('app.media.' + option.name))
                      .width(23)
                      .height(23)
                      .fillColor(this.icon === option.name ? this.color : $r('app.color.ink_2'))
                  }
                  .width(44)
                  .height(44)
                  .borderRadius(Radius.icon)
                  .backgroundColor($r('app.color.surface_2'))
                  .border({
                    width: 2,
                    color: this.icon === option.name ? $r('app.color.brand_ink') : Color.Transparent
                  })
                  .onClick(() => {
                    this.icon = option.name;
                  })
                }, (option: BookIconOption) => option.name)
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            Column({ space: 8 }) {
              Text('颜色')
                .fontSize(AppFont.micro)
                .fontColor($r('app.color.ink_3'))
                .width('100%')
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.colors(), (option: BookColorOption) => {
                  Stack() {
                    if (this.color === option.value) {
                      Image($r('app.media.ic_check'))
                        .width(15)
                        .height(15)
                        .fillColor($r('app.color.surface'))
                    }
                  }
                  .width(34)
                  .height(34)
                  .borderRadius(17)
                  .backgroundColor(option.value)
                  .border({
                    width: 2,
                    color: this.color === option.value ? $r('app.color.ink') : Color.Transparent
                  })
                  .margin({ right: 10, bottom: 8 })
                  .onClick(() => {
                    this.color = option.value;
                  })
                }, (option: BookColorOption) => option.value)
              }
              .width('100%')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            ToggleRow({
              title: '私密账本',
              subtitle: '开启后需要密码才能查看金额',
              isOn: this.privateOn,
              onChange: (isOn: boolean) => {
                if (isOn) {
                  this.privateOn = true;
                  this.showPwd = true;
                } else {
                  this.privateOn = false;
                }
              }
            })

            Column({ space: 6 }) {
              Text('本月预算（可选）')
                .fontSize(AppFont.micro)
                .fontColor($r('app.color.ink_3'))
                .width('100%')
              Row({ space: 6 }) {
                Text('¥')
                  .fontSize(AppFont.subTitle)
                  .fontWeight(AppFont.bold)
                  .fontColor($r('app.color.ink'))
                TextInput({ text: this.budgetText, placeholder: '不设置预算' })
                  .layoutWeight(1)
                  .height(44)
                  .type(InputType.Number)
                  .fontSize(AppFont.settings)
                  .fontColor($r('app.color.ink'))
                  .placeholderColor($r('app.color.ink_3'))
                  .backgroundColor($r('app.color.surface_2'))
                  .borderRadius(Radius.input)
                  .onChange((value: string) => {
                    this.budgetText = value;
                    this.errorText = '';
                  })
              }
              .width('100%')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            PrimaryButton({
              label: '保存',
              onTap: () => {
                this.submit();
              }
            })
          }
          .width('100%')
          .padding({ left: Space.x7, right: Space.x7, top: 22, bottom: Space.x8 + 10 })
        }
        .width('100%')
        .constraintSize({ maxHeight: '84%' })
        .borderRadius({ topLeft: Radius.sheet, topRight: Radius.sheet })
        .backgroundColor($r('app.color.surface'))
        .shadow(Shadow.sheet(this.ui.isDark))
        .scrollBar(BarState.Off)

        PasswordSetupSheet({
          visible: this.showPwd,
          isChange: false,
          onSave: (oldPassword: string, pwd: string) => {
            this.pendingPassword = pwd;
            this.showPwd = false;
          },
          onClose: () => {
            this.showPwd = false;
            if (!this.initialPrivate) {
              this.privateOn = false;
            }
          }
        })
      }
      .width('100%')
      .height('100%')
    }
  }

  private pendingPassword: string = '';
}
