import { AppFont, Radius, Space } from '../../theme/Theme';
import { memberColorOf, SeedColors, withAlpha } from '../../theme/Palette';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { Category, Member, Txn } from '../../models/Entities';
import { MoneyText, MoneyTone } from '../../components/base/MoneyText';
import { DateUtil } from '../../utils/DateUtil';

@ComponentV2
export struct TxnRow {
  @Param txn: Txn | null = null;
  @Param category: Category | null = null;
  @Param member: Member | null = null;
  @Param locked: boolean = false;
  @Param isFirst: boolean = false;
  @Param isLast: boolean = false;
  @Param showDate: boolean = false;
  @Param bookName: string = '';
  @Event onLongPress: () => void = () => {
  };
  @Event onTap: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();

  private iconName(): string {
    return this.category === null ? 'ic_cat_other' : this.category.icon;
  }

  private categoryName(): string {
    return this.category === null ? '未分类' : this.category.name;
  }

  private iconColor(): string {
    return this.category === null ? SeedColors.neutral : this.category.color;
  }

  private title(): string {
    if (this.txn === null) {
      return '';
    }
    if (this.txn.note.length > 0) {
      return this.txn.note;
    }
    return this.categoryName();
  }

  private subtitle(): string {
    if (this.txn === null) {
      return '';
    }
    if (this.showDate) {
      return DateUtil.formatDayCn(this.txn.dayKey).concat(' · ').concat(this.categoryName());
    }
    return this.categoryName();
  }

  private radiusValue(): BorderRadiuses {
    const first: number = this.isFirst ? Radius.card : 0;
    const last: number = this.isLast ? Radius.card : 0;
    return {
      topLeft: first,
      topRight: first,
      bottomLeft: last,
      bottomRight: last
    };
  }

  build() {
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

      Column({ space: 3 }) {
        Text(this.title())
          .fontSize(AppFont.row)
          .fontWeight(AppFont.semibold)
          .fontColor($r('app.color.ink'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 5 }) {
          if (this.member !== null) {
            Text(this.member.initial)
              .fontSize(8)
              .fontWeight(AppFont.bold)
              .fontColor(memberColorOf(this.member.color, this.ui.isDark))
              .textAlign(TextAlign.Center)
              .width(15)
              .height(15)
              .borderRadius(8)
              .backgroundColor(withAlpha(memberColorOf(this.member.color, this.ui.isDark), 0.15))
          }
          Text(this.subtitle())
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.ink_3'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      MoneyText({
        cents: this.txn === null ? 0 : this.txn.amountCents,
        fontSize: AppFont.body,
        weight: AppFont.bold,
        tone: MoneyTone.Expense,
        locked: this.locked,
        showSymbol: true
      })
    }
    .width('100%')
    .padding({ left: 13, right: 13, top: 11, bottom: 11 })
    .backgroundColor($r('app.color.surface'))
    .borderRadius(this.radiusValue())
    .border({
      width: { bottom: this.isLast ? 0 : 1 },
      color: $r('app.color.line')
    })
    .onClick(() => {
      this.onTap();
    })
    .gesture(LongPressGesture({ repeat: false, duration: 400 }).onAction(() => {
      this.onLongPress();
    }))
  }
}
