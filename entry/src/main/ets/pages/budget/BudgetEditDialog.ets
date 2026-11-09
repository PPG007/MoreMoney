import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { PrimaryButton } from '../../components/base/PrimaryButton';
import { SecondaryButton } from '../../components/base/SecondaryButton';
import { formatCents, formatYuan, parseYuanToCents } from '../../utils/MoneyUtil';

const MAX_CENTS: number = 9999999999;

@ComponentV2
export struct BudgetEditDialog {
  @Param visible: boolean = false;
  @Param bookName: string = '';
  @Param periodLabel: string = '';
  @Param currentCents: number = 0;
  @Param spentCents: number = 0;
  @Event onSave: (cents: number) => void = (cents: number) => {
  };
  @Event onClose: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local text: string = '';
  @Local errorText: string = '';

  @Monitor('visible')
  onVisibleChanged(): void {
    if (this.visible) {
      this.text = this.currentCents > 0 ? formatYuan(this.currentCents) : '';
      this.errorText = '';
    }
  }

  private addCents(cents: number): void {
    const parsed: number | null = parseYuanToCents(this.text);
    const current: number = parsed === null ? 0 : parsed;
    const next: number = current + cents;
    if (next > MAX_CENTS) {
      this.errorText = '金额超出上限';
      return;
    }
    this.text = formatYuan(next);
    this.errorText = '';
  }

  private submit(): void {
    const raw: string = this.text.trim();
    if (raw.length === 0) {
      this.onSave(0);
      return;
    }
    const cents: number | null = parseYuanToCents(raw);
    if (cents === null) {
      this.errorText = '请输入正确的金额（最多两位小数）';
      return;
    }
    if (cents > MAX_CENTS) {
      this.errorText = '金额超出上限';
      return;
    }
    this.onSave(cents);
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
            Text('设置'.concat(this.periodLabel).concat('预算'))
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

          Text(this.bookName.concat(' · 本月已用 ').concat(formatCents(this.spentCents)))
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.ink_3'))
            .width('100%')

          Row({ space: 7 }) {
            Text('¥')
              .fontSize(AppFont.pageTitle)
              .fontWeight(AppFont.bold)
              .fontColor($r('app.color.ink'))
            TextInput({ text: this.text, placeholder: '0.00' })
              .layoutWeight(1)
              .height(45)
              .type(InputType.Number)
              .fontSize(AppFont.subTitle)
              .fontWeight(AppFont.bold)
              .fontColor($r('app.color.ink'))
              .placeholderColor($r('app.color.ink_3'))
              .backgroundColor($r('app.color.surface_2'))
              .borderRadius(13)
              .padding({ left: 12, right: 12 })
              .onChange((value: string) => {
                this.text = value;
                this.errorText = '';
              })
          }
          .width('100%')

          if (this.errorText.length > 0) {
            Text(this.errorText)
              .fontSize(AppFont.micro)
              .fontColor($r('app.color.expense'))
              .width('100%')
          }

          Row({ space: 8 }) {
            Text('+100')
              .fontSize(AppFont.caption)
              .fontWeight(AppFont.semibold)
              .fontColor($r('app.color.brand_ink'))
              .padding({ left: 12, right: 12, top: 7, bottom: 7 })
              .borderRadius(Radius.pill)
              .backgroundColor($r('app.color.brand_wash'))
              .onClick(() => {
                this.addCents(10000);
              })
            Text('+500')
              .fontSize(AppFont.caption)
              .fontWeight(AppFont.semibold)
              .fontColor($r('app.color.brand_ink'))
              .padding({ left: 12, right: 12, top: 7, bottom: 7 })
              .borderRadius(Radius.pill)
              .backgroundColor($r('app.color.brand_wash'))
              .onClick(() => {
                this.addCents(50000);
              })
            Text('+1000')
              .fontSize(AppFont.caption)
              .fontWeight(AppFont.semibold)
              .fontColor($r('app.color.brand_ink'))
              .padding({ left: 12, right: 12, top: 7, bottom: 7 })
              .borderRadius(Radius.pill)
              .backgroundColor($r('app.color.brand_wash'))
              .onClick(() => {
                this.addCents(100000);
              })
            Blank()
            Text('清空')
              .fontSize(AppFont.caption)
              .fontColor($r('app.color.ink_3'))
              .onClick(() => {
                this.text = '';
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Column({ space: Space.x2 }) {
            PrimaryButton({
              label: '保存',
              onTap: () => {
                this.submit();
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
