import { AppFont, Radius, Space } from '../../theme/Theme';
import { Category, Member, Txn } from '../../models/Entities';
import { TxnRow } from '../../pages/home/TxnRow';
import { MoneyText, MoneyTone } from '../../components/base/MoneyText';
import { EmptyState } from '../../components/base/EmptyState';
import { DateUtil } from '../../utils/DateUtil';

@ComponentV2
export struct DayDetailList {
  @Param dayKey: string = '';
  @Param txns: Txn[] = [];
  @Param categories: Category[] = [];
  @Param members: Member[] = [];
  @Param lockedBookIds: string[] = [];
  @Param totalCents: number = 0;

  private categoryOf(id: string): Category | null {
    const found: Category | undefined = this.categories.find((item: Category): boolean => item.id === id);
    return found === undefined ? null : found;
  }

  private memberOf(id: string): Member | null {
    const found: Member | undefined = this.members.find((item: Member): boolean => item.id === id);
    return found === undefined ? null : found;
  }

  private isLocked(bookId: string): boolean {
    return this.lockedBookIds.indexOf(bookId) >= 0;
  }

  build() {
    Column({ space: Space.x2 }) {
      Row() {
        Text(this.dayKey.length > 0 ? DateUtil.formatDayCn(this.dayKey) : '')
          .fontSize(AppFont.micro)
          .fontWeight(AppFont.semibold)
          .fontColor($r('app.color.ink_2'))
          .layoutWeight(1)
        MoneyText({
          cents: this.totalCents,
          fontSize: AppFont.micro,
          weight: AppFont.semibold,
          tone: MoneyTone.Ink
        })
      }
      .width('100%')
      .padding({ left: 2, right: 2 })

      if (this.txns.length === 0) {
        EmptyState({
          icon: $r('app.media.ic_file'),
          title: '这天没有记账',
          description: ''
        })
      } else {
        Column() {
          ForEach(this.txns, (txn: Txn, index: number) => {
            TxnRow({
              txn: txn,
              category: this.categoryOf(txn.categoryId),
              member: this.memberOf(txn.memberId),
              locked: this.isLocked(txn.bookId),
              isFirst: index === 0,
              isLast: index === this.txns.length - 1
            })
          }, (txn: Txn) => txn.id)
        }
        .width('100%')
        .borderRadius(Radius.card)
        .clip(true)
      }
    }
    .width('100%')
  }
}
