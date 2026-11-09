import { AppFont, Radius, Space } from '../../theme/Theme';
import { SeedColors, withAlpha } from '../../theme/Palette';
import { Book } from '../../models/Entities';
import { AmountBar, AmountTone } from '../../components/base/AmountBar';
import { AppBadge, BadgeTone } from '../../components/base/Badge';
import { MoneyText, MoneyTone } from '../../components/base/MoneyText';

export class BookViewData {
  book: Book = {
    id: '',
    name: '',
    icon: 'ic_book_daily',
    color: SeedColors.c1,
    isPrivate: false,
    pwdHash: null,
    pwdSalt: null,
    pwdIter: 10000,
    isDefault: false,
    sort: 0,
    archived: false,
    createdAt: 0,
    updatedAt: 0
  };
  count: number = 0;
  budgetCents: number = 0;
  spentCents: number = 0;
  percent: number = 0;
}

@ComponentV2
struct BookMiniButton {
  @Param label: string = '';
  @Event onTap: () => void = () => {
  };

  build() {
    Text(this.label)
      .fontSize(AppFont.caption)
      .fontWeight(AppFont.bold)
      .fontColor($r('app.color.brand_ink'))
      .padding({ left: 9, right: 9, top: 5, bottom: 5 })
      .borderRadius(Radius.pill)
      .backgroundColor($r('app.color.brand_wash'))
      .onClick(() => {
        this.onTap();
      })
  }
}

@ComponentV2
export struct BookCard {
  @Param data: BookViewData = new BookViewData();
  @Param locked: boolean = false;
  @Event onEdit: (bookId: string) => void = (bookId: string) => {
  };
  @Event onMore: (bookId: string) => void = (bookId: string) => {
  };
  @Event onBudget: (bookId: string) => void = (bookId: string) => {
  };
  @Event onUnlock: (bookId: string) => void = (bookId: string) => {
  };

  private hasBudget(): boolean {
    return this.data.budgetCents > 0;
  }

  private metaText(): string {
    const countText: string = '本月 '.concat(this.data.count.toString()).concat(' 笔');
    if (!this.hasBudget()) {
      return countText.concat(' · 未设置预算');
    }
    return countText.concat(' · 预算 ').concat(this.currencyText(this.data.budgetCents));
  }

  private currencyText(cents: number): string {
    const yuan: number = Math.floor(Math.abs(cents) / 100);
    const fraction: number = Math.abs(cents) % 100;
    let grouped: string = '';
    const text: string = yuan.toString();
    for (let i = 0; i < text.length; i++) {
      grouped = grouped.concat(text.substring(i, i + 1));
      const remain: number = text.length - i - 1;
      if (remain > 0 && remain % 3 === 0) {
        grouped = grouped.concat(',');
      }
    }
    return '¥'.concat(grouped).concat('.').concat(fraction.toString().padStart(2, '0'));
  }

  build() {
    Row({ space: 9 }) {
      Stack() {
        Image($r('app.media.' + this.data.book.icon))
          .width(23)
          .height(23)
          .fillColor(this.data.book.color)
      }
      .width(46)
      .height(46)
      .borderRadius(Radius.icon)
      .backgroundColor(withAlpha(this.data.book.color, 0.16))

      Column({ space: 5 }) {
        Row({ space: 6 }) {
          Text(this.data.book.name)
            .fontSize(AppFont.row)
            .fontWeight(AppFont.bold)
            .fontColor($r('app.color.ink'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.data.book.isDefault) {
            AppBadge({ text: '默认' })
          }
          if (this.data.book.isPrivate) {
            AppBadge({ text: '私密', tone: BadgeTone.Warn })
          }
        }
        .width('100%')

        Text(this.metaText())
          .fontSize(AppFont.caption)
          .fontColor($r('app.color.ink_3'))
          .maxLines(1)

        if (this.hasBudget()) {
          AmountBar({
            percent: this.locked ? 0 : this.data.percent,
            barHeight: 5,
            tone: this.data.spentCents > this.data.budgetCents ? AmountTone.Expense : AmountTone.Brand
          })
        } else {
          Row()
            .width('100%')
            .height(5)
            .borderRadius(Radius.pill)
            .border({ width: 1, color: $r('app.color.line'), style: BorderStyle.Dashed })
        }

        if (this.locked) {
          Text('••••••')
            .fontSize(AppFont.caption)
            .fontWeight(AppFont.semibold)
            .fontColor($r('app.color.ink_2'))
        } else if (this.hasBudget()) {
          Row({ space: 3 }) {
            Text('已用')
              .fontSize(AppFont.caption)
              .fontColor($r('app.color.ink_3'))
            MoneyText({
              cents: this.data.spentCents,
              fontSize: AppFont.caption,
              weight: AppFont.regular,
              tone: MoneyTone.Ink
            })
            Text('/ 剩余')
              .fontSize(AppFont.caption)
              .fontColor($r('app.color.ink_3'))
            MoneyText({
              cents: this.data.budgetCents - this.data.spentCents,
              fontSize: AppFont.caption,
              weight: AppFont.regular,
              tone: this.data.spentCents > this.data.budgetCents ? MoneyTone.Expense : MoneyTone.Ink
            })
          }
          .width('100%')
        } else {
          Text('还没有预算')
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.ink_3'))
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column({ space: Space.x2 }) {
        Stack() {
          Image($r('app.media.ic_more'))
            .width(17)
            .height(17)
            .fillColor($r('app.color.ink_3'))
        }
        .width(30)
        .height(30)
        .borderRadius(Radius.pill)
        .onClick(() => {
          this.onMore(this.data.book.id);
        })

        if (this.locked) {
          BookMiniButton({
            label: '解锁',
            onTap: () => {
              this.onUnlock(this.data.book.id);
            }
          })
        } else {
          BookMiniButton({
            label: '设置预算',
            onTap: () => {
              this.onBudget(this.data.book.id);
            }
          })
        }
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(13)
    .borderRadius(Radius.card)
    .backgroundColor($r('app.color.surface'))
    .border({ width: 1, color: $r('app.color.line') })
    .onClick(() => {
      this.onEdit(this.data.book.id);
    })
  }
}
