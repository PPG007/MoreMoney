import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { PrimaryButton } from '../../components/base/PrimaryButton';
import { SecondaryButton } from '../../components/base/SecondaryButton';
import { SegmentedControl } from '../../components/base/SegmentedControl';
import { formatCents, formatYuan, parseYuanToCents } from '../../utils/MoneyUtil';
import { BookBudgetState } from '../../service/BudgetService';
import { BudgetPeriod, BudgetPeriodType } from '../../service/BudgetPeriod';

const MAX_CENTS: number = 9999999999;

@ComponentV2
export struct BudgetEditDialog {
  @Param visible: boolean = false;
  @Param bookName: string = '';
  @Param state: BookBudgetState = new BookBudgetState();
  @Param initialType: BudgetPeriodType = BudgetPeriodType.MONTH;
  @Event onSave: (type: BudgetPeriodType, cents: number) => void = (type: BudgetPeriodType, cents: number) => {
  };
  @Event onClose: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local selectedType: BudgetPeriodType = BudgetPeriodType.MONTH;
  @Local text: string = '';
  @Local errorText: string = '';

  @Monitor('visible')
  onVisibleChanged(): void {
    if (this.visible) {
      this.selectedType = this.initialType;
      const current: number = this.state.amountOf(this.selectedType);
      this.text = current > 0 ? formatYuan(current) : '';
      this.errorText = '';
    }
  }

  private selectType(index: number): void {
    const type: BudgetPeriodType = BudgetPeriod.at(index);
    if (type === this.selectedType) {
      return;
    }
    this.selectedType = type;
    const current: number = this.state.amountOf(type);
    this.text = current > 0 ? formatYuan(current) : '';
    this.errorText = '';
  }

  private spentText(): string {
    return this.bookName.concat(' · ').concat(BudgetPeriod.noun(this.selectedType)).concat('已用 ')
      .concat(formatCents(this.state.spentOf(this.selectedType)));
  }

  private existingText(): string {
    return '已有 周 '.concat(BudgetEditDialog.amountText(this.state.weekCents))
      .concat(' · 月 ').concat(BudgetEditDialog.amountText(this.state.monthCents))
      .concat(' · 年 ').concat(BudgetEditDialog.amountText(this.state.yearCents));
  }

  private static amountText(cents: number): string {
    return cents > 0 ? formatCents(cents) : '未设置';
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
      this.onSave(this.selectedType, 0);
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
    const next: BookBudgetState = this.state.withAmount(this.selectedType, cents);
    const error: string = BudgetPeriod.validate(next.weekCents, next.monthCents, next.yearCents);
    if (error.length > 0) {
      this.errorText = error;
      return;
    }
    this.onSave(this.selectedType, cents);
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
            Text('设置预算')
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

          SegmentedControl({
            options: ['周预算', '月预算', '年预算'],
            selectedIndex: BudgetPeriod.indexOf(this.selectedType),
            onChange: (index: number) => {
              this.selectType(index);
            }
          })

          Text(this.spentText())
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.ink_3'))
            .width('100%')

          Text(this.existingText())
            .fontSize(AppFont.micro)
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
              .type(InputType.NUMBER_DECIMAL)
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

          Text('同一账本可同时设置周、月、年预算，周 × 4 不超过月，月 × 12 不超过年。')
            .fontSize(AppFont.micro)
            .fontColor($r('app.color.ink_3'))
            .width('100%')

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
                this.errorText = '';
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
