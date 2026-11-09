import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { SeedColors, withAlpha } from '../../theme/Palette';
import { Category, Member, Txn } from '../../models/Entities';
import { MoneyText, MoneyTone } from '../../components/base/MoneyText';
import { SecondaryButton } from '../../components/base/SecondaryButton';
import { DateUtil } from '../../utils/DateUtil';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
export struct TxnDetailSheet {
  @Param visible: boolean = false;
  @Param txn: Txn | null = null;
  @Param category: Category | null = null;
  @Param member: Member | null = null;
  @Param bookName: string = '';
  @Param locked: boolean = false;
  @Event onClose: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();

  private categoryName(): string {
    return this.category === null ? '未分类' : this.category.name;
  }

  private iconName(): string {
    return this.category === null ? 'ic_cat_other' : this.category.icon;
  }

  private iconColor(): string {
    return this.category === null ? SeedColors.neutral : this.category.color;
  }

  private memberName(): string {
    return this.member === null ? '—' : this.member.name;
  }

  private txnDayKey(): string {
    return this.txn === null ? '' : this.txn.dayKey;
  }

  private txnAmount(): number {
    return this.txn === null ? 0 : this.txn.amountCents;
  }

  private txnNote(): string {
    return this.txn === null ? '' : this.txn.note;
  }

  @Builder
  infoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(AppFont.caption)
        .fontColor($r('app.color.ink_3'))
        .width(64)
      Text(value)
        .fontSize(AppFont.settings)
        .fontColor($r('app.color.ink'))
        .layoutWeight(1)
        .maxLines(2)
    }
    .width('100%')
    .padding({ top: 5, bottom: 5 })
    .alignItems(VerticalAlign.Top)
  }

  build() {
    if (this.visible && this.txn !== null) {
      Stack({ alignContent: Alignment.Bottom }) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.scrim'))
          .onClick(() => {
            this.onClose();
          })

        Column({ space: Space.x3 }) {
          Row({ space: 11 }) {
            Stack() {
              Image($r('app.media.' + this.iconName()))
                .width(21)
                .height(21)
                .fillColor(this.iconColor())
            }
            .width(42)
            .height(42)
            .borderRadius(Radius.icon)
            .backgroundColor(withAlpha(this.iconColor(), 0.13))

            Column({ space: 2 }) {
              Text(this.categoryName())
                .fontSize(AppFont.row)
                .fontWeight(AppFont.bold)
                .fontColor($r('app.color.ink'))
              Text(DateUtil.formatDayCn(this.txnDayKey()))
                .fontSize(AppFont.caption)
                .fontColor($r('app.color.ink_3'))
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            MoneyText({
              cents: this.txnAmount(),
              fontSize: 20,
              weight: AppFont.bold,
              tone: MoneyTone.Expense,
              locked: this.locked
            })
          }
          .width('100%')

          Divider().color($r('app.color.line'))

          this.infoRow('账本', this.bookName.length > 0 ? this.bookName : '—')
          this.infoRow('成员', this.memberName())
          this.infoRow('日期', DateUtil.formatDayCn(this.txnDayKey()))
          this.infoRow('备注', this.txnNote().length > 0 ? this.txnNote() : '无')

          SecondaryButton({
            label: '关闭',
            onTap: () => {
              this.onClose();
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
