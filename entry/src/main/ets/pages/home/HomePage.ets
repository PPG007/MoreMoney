import { AppFont, Radius, Space } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { Book, Budget, Category, Member, Txn, TxnFilter } from '../../models/Entities';
import { AddTxnParam } from '../../models/NavParams';
import { BookDao } from '../../data/db/BookDao';
import { BudgetDao } from '../../data/db/BudgetDao';
import { CategoryDao } from '../../data/db/CategoryDao';
import { MemberDao } from '../../data/db/MemberDao';
import { TxnDao } from '../../data/db/TxnDao';
import { DateUtil, DateRange } from '../../utils/DateUtil';
import { ErrorUtil } from '../../utils/ErrorUtil';
import { HomeHero } from './HomeHero';
import { SummaryCard } from './SummaryCard';
import { DayHeader } from './DayHeader';
import { TxnRow } from './TxnRow';
import { EmptyState } from '../../components/base/EmptyState';
import { UnlockSheet } from '../../components/sheet/UnlockSheet';
import { ConfirmSheet } from '../../components/base/ConfirmSheet';
import { ErrorRetry } from '../../components/base/ErrorRetry';
import { DeleteService } from '../../service/DeleteService';
import { SnackBarService } from '../../service/SnackBarService';
import { SnackBarOptions } from '../../service/SnackBarService';

class DayGroup {
  dayKey: string = '';
  cents: number = 0;
  locked: boolean = false;
  txns: Txn[] = [];
}

const MAX_ROWS_PER_DAY: number = 20;

@ComponentV2
export struct HomePage {
  @Param stack: NavPathStack = new NavPathStack();
  @Event onGoBudget: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local books: Book[] = [];
  @Local members: Member[] = [];
  @Local categories: Category[] = [];
  @Local days: DayGroup[] = [];
  @Local selectedBookId: string = '';
  @Local selectedMemberId: string = '';
  @Local monthKey: string = DateUtil.monthKey(new Date());
  @Local spentCents: number = 0;
  @Local budgetCents: number = 0;
  @Local hasBudget: boolean = false;
  @Local perDayCents: number = 0;
  @Local loading: boolean = true;
  @Local refreshing: boolean = false;
  @Local errorText: string = '';
  @Local expandedDayKey: string = '';
  @Local switchOffsetX: number = 0;
  @Local switchOpacity: number = 1;
  private switching: boolean = false;
  @Local showUnlock: boolean = false;
  @Local unlockBookId: string = '';
  @Local unlockBookName: string = '';
  @Local showDeleteSheet: boolean = false;
  @Local deleteTxnId: string = '';
  private initialized: boolean = false;

  aboutToAppear(): void {
    this.reload();
  }

  @Monitor('ui.unlockVersion')
  onUnlockChanged(): void {
    this.reload();
  }

  @Monitor('ui.txnVersion')
  onTxnChanged(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    this.errorText = '';
    try {
      const allBooks: Book[] = await BookDao.list();
      const activeBooks: Book[] = allBooks.filter((book: Book): boolean => !book.archived);
      this.books = activeBooks;
      this.members = (await MemberDao.list()).filter((member: Member): boolean => !member.archived);
      this.categories = await this.loadCategories();

      if (!this.initialized) {
        this.initialized = true;
        const defaultBook: Book | undefined = activeBooks.find((book: Book): boolean => book.isDefault);
        this.selectedBookId = defaultBook === undefined ? '' : defaultBook.id;
      }
      const selectedExists: boolean = this.selectedBookId === '' ||
        activeBooks.some((book: Book): boolean => book.id === this.selectedBookId);
      if (!selectedExists) {
        this.selectedBookId = '';
      }

      const budgets: Budget[] = await BudgetDao.list(this.monthKey);
      const listBookIds: string[] = this.selectedBookId === ''
        ? activeBooks.map((book: Book): string => book.id)
        : [this.selectedBookId];
      const unlockedBookIds: string[] = listBookIds.filter((id: string): boolean => !this.isLockedBook(id));

      const filter: TxnFilter = new TxnFilter();
      filter.bookIds = listBookIds;
      if (this.selectedMemberId !== '') {
        filter.memberIds = [this.selectedMemberId];
      }
      const range: DateRange = DateUtil.rangeOfMonth(this.monthKey);
      filter.startMs = range.startMs;
      filter.endMs = range.endMs;
      const txns: Txn[] = listBookIds.length === 0 ? [] : await TxnDao.listRange(filter);

      if (unlockedBookIds.length > 0) {
        const sumFilter: TxnFilter = new TxnFilter();
        sumFilter.bookIds = unlockedBookIds;
        sumFilter.memberIds = filter.memberIds;
        sumFilter.startMs = range.startMs;
        sumFilter.endMs = range.endMs;
        this.spentCents = await TxnDao.sumRange(sumFilter);
      } else {
        this.spentCents = 0;
      }

      this.applyBudget(budgets, unlockedBookIds);
      this.days = this.buildDays(txns);
    } catch (error) {
      this.errorText = ErrorUtil.messageOf(error);
    } finally {
      this.loading = false;
      this.refreshing = false;
    }
  }

  private applyBudget(budgets: Budget[], unlockedBookIds: string[]): void {
    let total: number = 0;
    let found: boolean = false;
    for (const budget of budgets) {
      if (unlockedBookIds.indexOf(budget.bookId) >= 0 && budget.amountCents > 0) {
        total += budget.amountCents;
        found = true;
      }
    }
    this.hasBudget = found;
    this.budgetCents = found ? total : 0;
    const remaining: number = this.budgetCents - this.spentCents;
    const parts: string[] = this.monthKey.split('-');
    const year: number = Number(parts[0]);
    const month: number = Number(parts[1]);
    const totalDays: number = DateUtil.daysInMonth(year, month);
    const now: Date = new Date();
    let daysLeft: number = totalDays;
    if (now.getFullYear() === year && now.getMonth() + 1 === month) {
      daysLeft = totalDays - now.getDate() + 1;
    }
    if (daysLeft < 1) {
      daysLeft = 1;
    }
    const available: number = remaining > 0 ? remaining : 0;
    this.perDayCents = Math.floor(available / daysLeft);
  }

  private buildDays(txns: Txn[]): DayGroup[] {
    const groups: DayGroup[] = [];
    let current: DayGroup | null = null;
    for (const txn of txns) {
      if (current === null || current.dayKey !== txn.dayKey) {
        current = new DayGroup();
        current.dayKey = txn.dayKey;
        groups.push(current);
      }
      current.txns.push(txn);
      if (!this.isLockedBook(txn.bookId)) {
        current.cents += txn.amountCents;
      }
    }
    for (const group of groups) {
      group.locked = group.txns.length > 0 &&
        group.txns.every((txn: Txn): boolean => this.isLockedBook(txn.bookId));
    }
    return groups;
  }

  private async loadCategories(): Promise<Category[]> {
    const groups = await CategoryDao.listGroups();
    const all: Category[] = [];
    for (const group of groups) {
      const list: Category[] = await CategoryDao.listByGroup(group.id);
      for (const category of list) {
        all.push(category);
      }
    }
    return all;
  }

  private isLockedBook(bookId: string): boolean {
    const book: Book | undefined = this.books.find((item: Book): boolean => item.id === bookId);
    if (book === undefined || !book.isPrivate) {
      return false;
    }
    return !this.ui.isBookUnlocked(bookId);
  }

  private lockedBookIds(): string[] {
    return this.books
      .filter((book: Book): boolean => book.isPrivate && !this.ui.isBookUnlocked(book.id))
      .map((book: Book): string => book.id);
  }

  private categoryOf(id: string): Category | null {
    const found: Category | undefined = this.categories.find((item: Category): boolean => item.id === id);
    return found === undefined ? null : found;
  }

  private memberOf(id: string): Member | null {
    const found: Member | undefined = this.members.find((item: Member): boolean => item.id === id);
    return found === undefined ? null : found;
  }

  private visibleTxns(group: DayGroup): Txn[] {
    if (this.expandedDayKey === group.dayKey) {
      return group.txns;
    }
    return group.txns.slice(0, MAX_ROWS_PER_DAY);
  }

  private hiddenCount(group: DayGroup): number {
    if (this.expandedDayKey === group.dayKey) {
      return 0;
    }
    return group.txns.length - MAX_ROWS_PER_DAY;
  }

  private bookDirection(bookId: string): number {
    const oldIndex: number = this.selectedBookId === ''
      ? -1
      : this.books.findIndex((book: Book): boolean => book.id === this.selectedBookId);
    const newIndex: number = bookId === ''
      ? -1
      : this.books.findIndex((book: Book): boolean => book.id === bookId);
    return newIndex >= oldIndex ? 1 : -1;
  }

  private animateContentSwitch(direction: number, apply: () => void): void {
    if (this.switching) {
      return;
    }
    this.switching = true;
    const exitOffset: number = direction >= 0 ? -36 : 36;
    const enterOffset: number = direction >= 0 ? 36 : -36;
    this.getUIContext().animateTo({
      duration: 120,
      curve: Curve.EaseIn,
      onFinish: () => {
        apply();
        this.switchOffsetX = enterOffset;
        this.switchOpacity = 0;
        this.getUIContext().animateTo({
          duration: 200,
          curve: Curve.EaseOut,
          onFinish: () => {
            this.switching = false;
          }
        }, () => {
          this.switchOffsetX = 0;
          this.switchOpacity = 1;
        });
      }
    }, () => {
      this.switchOffsetX = exitOffset;
      this.switchOpacity = 0;
    });
  }

  private selectBook(bookId: string): void {
    if (bookId === this.selectedBookId) {
      return;
    }
    this.animateContentSwitch(this.bookDirection(bookId), () => {
      this.selectedBookId = bookId;
      this.reload();
    });
  }

  private requestSelectBook(bookId: string): void {
    if (bookId.length > 0 && this.isLockedBook(bookId)) {
      const book: Book | undefined = this.books.find((item: Book): boolean => item.id === bookId);
      this.unlockBookId = bookId;
      this.unlockBookName = book === undefined ? '' : book.name;
      this.showUnlock = true;
      return;
    }
    this.selectBook(bookId);
  }

  private changeMonth(delta: number): void {
    this.animateContentSwitch(delta, () => {
      this.monthKey = DateUtil.addMonths(this.monthKey, delta);
      this.reload();
    });
  }

  private selectMember(memberId: string): void {
    this.selectedMemberId = memberId;
    this.reload();
  }

  private requestDelete(txn: Txn): void {
    if (this.isLockedBook(txn.bookId)) {
      SnackBarService.show(HomePage.toast('请先解锁该账本'));
      return;
    }
    this.deleteTxnId = txn.id;
    this.showDeleteSheet = true;
  }

  private static toast(message: string): SnackBarOptions {
    const options: SnackBarOptions = new SnackBarOptions();
    options.message = message;
    return options;
  }

  private async confirmDelete(): Promise<void> {
    const txnId: string = this.deleteTxnId;
    this.showDeleteSheet = false;
    try {
      await DeleteService.deleteTxn(txnId);
      await this.reload();
      const options: SnackBarOptions = new SnackBarOptions();
      options.message = '已删除 1 笔';
      options.actionLabel = '撤销';
      options.durationMs = 5000;
      options.onAction = () => {
        this.undoDelete(txnId);
      };
      SnackBarService.show(options);
    } catch (error) {
      SnackBarService.show(HomePage.toast('删除失败：'.concat(ErrorUtil.messageOf(error))));
    }
  }

  private async undoDelete(txnId: string): Promise<void> {
    try {
      await DeleteService.undoDelete(txnId);
      await this.reload();
    } catch (error) {
      SnackBarService.show(HomePage.toast('撤销失败：'.concat(ErrorUtil.messageOf(error))));
    }
  }

  private openAdd(): void {
    const param: AddTxnParam = new AddTxnParam();
    param.bookId = this.selectedBookId;
    this.stack.pushPathByName('AddTxn', param, (popInfo: PopInfo) => {
      this.reload();
    });
  }

  @Builder
  emptyTrailing() {
  }

  @Builder
  memberChip(member: Member) {
    Text(member.name)
      .fontSize(AppFont.caption)
      .fontWeight(this.selectedMemberId === member.id ? AppFont.semibold : AppFont.regular)
      .fontColor(this.selectedMemberId === member.id ? $r('app.color.brand_ink') : $r('app.color.ink_2'))
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .borderRadius(Radius.pill)
      .backgroundColor(this.selectedMemberId === member.id
        ? $r('app.color.brand_wash')
        : $r('app.color.surface'))
      .border({
        width: 1,
        color: this.selectedMemberId === member.id ? $r('app.color.brand_soft') : $r('app.color.line')
      })
      .onClick(() => {
        this.selectMember(member.id);
      })
  }

  @Builder
  dayHeader(group: DayGroup) {
    DayHeader({ dayKey: group.dayKey, cents: group.cents, locked: group.locked })
  }

  @Builder
  skeleton() {
    Column({ space: Space.x3 }) {
      Row()
        .width('100%')
        .height(120)
        .borderRadius(Radius.card)
        .backgroundColor($r('app.color.surface_2'))
        .margin({ top: this.ui.topInset + 90 })
      ForEach([0, 1, 2], (item: number) => {
        Row({ space: 11 }) {
          Row()
            .width(42)
            .height(42)
            .borderRadius(Radius.icon)
            .backgroundColor($r('app.color.surface_2'))
          Column({ space: 6 }) {
            Row().width('55%').height(10).borderRadius(4).backgroundColor($r('app.color.surface_2'))
            Row().width('35%').height(8).borderRadius(4).backgroundColor($r('app.color.surface_2'))
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 13, right: 13, top: 11, bottom: 11 })
        .borderRadius(Radius.card)
        .backgroundColor($r('app.color.surface'))
      }, (item: number) => item.toString())
    }
    .width('100%')
    .padding({ left: Space.page, right: Space.page })
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      if (this.loading && this.days.length === 0) {
        Column() {
          this.skeleton()
        }
        .width('100%')
        .height('100%')
      } else if (this.errorText.length > 0) {
        Column() {
          ErrorRetry({
            message: this.errorText,
            onRetry: () => {
              this.loading = true;
              this.reload();
            }
          })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Refresh({ refreshing: !!this.refreshing }) {
          List() {
            ListItem() {
              Column() {
                HomeHero({
                  monthLabel: DateUtil.formatMonthCn(this.monthKey),
                  books: this.books,
                  selectedBookId: this.selectedBookId,
                  lockedBookIds: this.lockedBookIds(),
                  onSelectBook: (bookId: string) => {
                    this.requestSelectBook(bookId);
                  },
                  onSearch: () => {
                    this.stack.pushPathByName('Search', '', (popInfo: PopInfo) => {
                      this.reload();
                    });
                  },
                  onPrevMonth: () => {
                    this.changeMonth(-1);
                  },
                  onNextMonth: () => {
                    this.changeMonth(1);
                  }
                })
                SummaryCard({
                  spentCents: this.spentCents,
                  budgetCents: this.budgetCents,
                  hasBudget: this.hasBudget,
                  perDayCents: this.perDayCents,
                  onGoBudget: () => {
                    this.onGoBudget();
                  }
                })
                .margin({ left: Space.page, right: Space.page, top: -54 })
              }
              .width('100%')
            }

            ListItem() {
              Column({ space: Space.x2 }) {
                Row() {
                  Text('最近记录')
                    .fontSize(AppFont.body)
                    .fontWeight(AppFont.bold)
                    .fontColor($r('app.color.ink'))
                    .layoutWeight(1)
                }
                .width('100%')
                Scroll() {
                  Row({ space: 6 }) {
                    Text('全部成员')
                      .fontSize(AppFont.caption)
                      .fontWeight(this.selectedMemberId === '' ? AppFont.semibold : AppFont.regular)
                      .fontColor(this.selectedMemberId === '' ? $r('app.color.brand_ink') : $r('app.color.ink_2'))
                      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                      .borderRadius(Radius.pill)
                      .backgroundColor(this.selectedMemberId === '' ? $r('app.color.brand_wash') : $r('app.color.surface'))
                      .border({
                        width: 1,
                        color: this.selectedMemberId === '' ? $r('app.color.brand_soft') : $r('app.color.line')
                      })
                      .onClick(() => {
                        this.selectMember('');
                      })
                    ForEach(this.members, (member: Member) => {
                      this.memberChip(member)
                    }, (member: Member) => member.id)
                  }
                }
                .scrollable(ScrollDirection.Horizontal)
                .scrollBar(BarState.Off)
                .width('100%')
              }
              .width('100%')
              .padding({ left: Space.page, right: Space.page, top: Space.x5 })
            }

            if (this.days.length === 0) {
              ListItem() {
                EmptyState({
                  icon: $r('app.media.ic_cat_other'),
                  title: '本月还没有记账',
                  description: '点右下角 + 记一笔'
                })
              }
              .translate({ x: this.switchOffsetX })
              .opacity(this.switchOpacity)
            } else {
              ForEach(this.days, (group: DayGroup) => {
                ListItemGroup({ header: this.dayHeader(group) }) {
                  ForEach(this.visibleTxns(group), (txn: Txn, index: number) => {
                    ListItem() {
                      TxnRow({
                        txn: txn,
                        category: this.categoryOf(txn.categoryId),
                        member: this.memberOf(txn.memberId),
                        locked: this.isLockedBook(txn.bookId),
                        isFirst: index === 0,
                        isLast: index === this.visibleTxns(group).length - 1 && this.hiddenCount(group) <= 0,
                        onLongPress: () => {
                          this.requestDelete(txn);
                        }
                      })
                    }
                  }, (txn: Txn) => txn.id)
                  if (this.hiddenCount(group) > 0) {
                    ListItem() {
                      Row() {
                        Text('其余 ' + this.hiddenCount(group).toString() + ' 笔')
                          .fontSize(AppFont.caption)
                          .fontWeight(AppFont.semibold)
                          .fontColor($r('app.color.brand_ink'))
                      }
                      .width('100%')
                      .height(36)
                      .justifyContent(FlexAlign.Center)
                      .backgroundColor($r('app.color.surface'))
                      .borderRadius({ bottomLeft: Radius.card, bottomRight: Radius.card })
                      .onClick(() => {
                        this.expandedDayKey = group.dayKey;
                      })
                    }
                  }
                }
                .margin({ left: Space.page, right: Space.page, bottom: Space.x3 })
                .translate({ x: this.switchOffsetX })
                .opacity(this.switchOpacity)
              }, (group: DayGroup) => group.dayKey.concat('#')
                .concat(group.txns.length.toString())
                .concat('#')
                .concat(group.cents.toString()))
            }

            ListItem() {
              Row().width('100%').height(150)
            }
          }
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)
          .sticky(StickyStyle.Header)
          .edgeEffect(EdgeEffect.Spring)
        }
        .onRefreshing(() => {
          this.refreshing = true;
          this.reload();
        })
        .width('100%')
        .height('100%')
      }

      if (!this.loading && this.errorText.length === 0) {
        Stack() {
          Image($r('app.media.ic_plus'))
            .width(29)
            .height(29)
            .fillColor($r('app.color.btn_fg'))
        }
        .width(70)
        .height(70)
        .borderRadius(Radius.pill)
        .backgroundColor($r('app.color.btn_bg'))
        .shadow({
          radius: 34,
          offsetX: 0,
          offsetY: 16,
          color: this.ui.isDark ? 'rgba(165,180,252,0.38)' : 'rgba(67,56,202,0.38)'
        })
        .margin({ right: Space.page, bottom: 18 })
        .onClick(() => {
          this.openAdd();
        })
      }

      UnlockSheet({
        visible: this.showUnlock,
        bookId: this.unlockBookId,
        bookName: this.unlockBookName,
        onUnlocked: (bookId: string) => {
          this.showUnlock = false;
          this.selectBook(bookId);
        },
        onClose: () => {
          this.showUnlock = false;
        }
      })

      ConfirmSheet({
        visible: this.showDeleteSheet,
        title: '删除这笔记录？',
        message: '删除后 5 秒内可撤销',
        confirmLabel: '删除',
        danger: true,
        onConfirm: () => {
          this.confirmDelete();
        },
        onCancel: () => {
          this.showDeleteSheet = false;
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg'))
  }
}
