import { AppFont, Radius, Space } from '../../theme/Theme';
import { HeatCalendar } from '../../components/chart/HeatCalendar';
import { DayDetailList } from '../../components/chart/DayDetailList';
import { Book, Category, Member, Txn } from '../../models/Entities';
import { DaySum, StatsFilter } from '../../models/StatsTypes';
import { StatsService } from '../../service/StatsService';
import { TxnDao } from '../../data/db/TxnDao';
import { CategoryDao } from '../../data/db/CategoryDao';
import { MemberDao } from '../../data/db/MemberDao';
import { BookDao } from '../../data/db/BookDao';
import { DateUtil, DateRange } from '../../utils/DateUtil';
import { ErrorUtil } from '../../utils/ErrorUtil';
import { EmptyState } from '../../components/base/EmptyState';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
export struct CalendarChartPage {
  @Param bookIds: string[] = [];
  @Param memberIds: string[] = [];
  @Param excludeBookIds: string[] = [];
  @Param weekStart: number = 1;
  @Param filterVersion: number = 0;
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local monthKey: string = DateUtil.monthKey(new Date());
  @Local selectedDayKey: string = '';
  @Local daySums: DaySum[] = [];
  @Local txns: Txn[] = [];
  @Local categories: Category[] = [];
  @Local members: Member[] = [];
  @Local totalCents: number = 0;
  @Local monthTotal: number = 0;
  @Local loading: boolean = true;
  @Local errorText: string = '';

  aboutToAppear(): void {
    this.initMonth();
    this.load();
  }

  @Monitor('filterVersion')
  onFilterChanged(): void {
    this.load();
  }

  private initMonth(): void {
    const today: string = DateUtil.dayKey(new Date());
    this.selectedDayKey = today.startsWith(this.monthKey) ? today : this.monthKey.concat('-01');
  }

  private allLockedIds(): string[] {
    return this.excludeBookIds;
  }

  private async load(): Promise<void> {
    try {
      this.errorText = '';
      const groups = await CategoryDao.listGroups();
      const categories: Category[] = [];
      for (const group of groups) {
        const list: Category[] = await CategoryDao.listByGroup(group.id);
        for (const category of list) {
          categories.push(category);
        }
      }
      this.categories = categories;
      this.members = await MemberDao.list();
      await this.loadMonth();
      await this.loadDay();
    } catch (error) {
      this.errorText = ErrorUtil.messageOf(error);
    } finally {
      this.loading = false;
    }
  }

  private async loadMonth(): Promise<void> {
    const range: DateRange = DateUtil.rangeOfMonth(this.monthKey);
    const filter: StatsFilter = new StatsFilter();
    filter.bookIds = this.bookIds;
    filter.memberIds = this.memberIds;
    filter.excludeBookIds = this.allLockedIds();
    filter.startMs = range.startMs;
    filter.endMs = range.endMs;
    filter.weekStart = this.weekStart;
    this.daySums = await StatsService.byDay(filter);
    this.monthTotal = await StatsService.sum(filter);
  }

  private async loadDay(): Promise<void> {
    const books: string[] = this.bookIds;
    const list: Txn[] = await TxnDao.listByDay(books, this.selectedDayKey);
    const archived: string[] = (await BookDao.list())
      .filter((book: Book): boolean => book.archived)
      .map((book: Book): string => book.id);
    const filtered: Txn[] = [];
    let total: number = 0;
    for (const txn of list) {
      if (this.allLockedIds().indexOf(txn.bookId) >= 0 || archived.indexOf(txn.bookId) >= 0) {
        continue;
      }
      if (this.memberIds.length > 0 && this.memberIds.indexOf(txn.memberId) < 0) {
        continue;
      }
      filtered.push(txn);
      total += txn.amountCents;
    }
    this.txns = filtered;
    this.totalCents = total;
  }

  private changeMonth(delta: number): void {
    const next: string = DateUtil.addMonths(this.monthKey, delta);
    if (delta > 0 && next > DateUtil.monthKey(new Date())) {
      return;
    }
    this.monthKey = next;
    this.initMonth();
    this.load();
  }

  private selectDay(dayKey: string): void {
    this.selectedDayKey = dayKey;
    this.loadDay();
  }

  private canGoNext(): boolean {
    return this.monthKey < DateUtil.monthKey(new Date());
  }

  @Builder
  monthRow() {
    Row({ space: Space.x4 }) {
      Stack() {
        Image($r('app.media.ic_chevron_left'))
          .width(15)
          .height(15)
          .fillColor($r('app.color.ink'))
      }
      .width(30)
      .height(30)
      .borderRadius(Radius.pill)
      .backgroundColor($r('app.color.surface'))
      .border({ width: 1, color: $r('app.color.line') })
      .onClick(() => {
        this.changeMonth(-1);
      })

      Text(this.monthKey.split('-')[0].concat('年').concat(DateUtil.formatMonthCn(this.monthKey)))
        .fontSize(AppFont.subTitle)
        .fontWeight(AppFont.bold)
        .fontColor($r('app.color.ink'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Stack() {
        Image($r('app.media.ic_chevron_right'))
          .width(15)
          .height(15)
          .fillColor(this.canGoNext() ? $r('app.color.ink') : $r('app.color.ink_3'))
      }
      .width(30)
      .height(30)
      .borderRadius(Radius.pill)
      .backgroundColor($r('app.color.surface'))
      .border({ width: 1, color: $r('app.color.line') })
      .opacity(this.canGoNext() ? 1 : 0.4)
      .onClick(() => {
        this.changeMonth(1);
      })
    }
    .width('100%')
    .padding({ left: Space.page, right: Space.page })
  }

  build() {
    Scroll() {
      Column({ space: Space.x3 }) {
        this.monthRow()

        if (this.errorText.length > 0) {
          Text(this.errorText)
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.expense'))
            .padding({ left: Space.page, right: Space.page })
        }

        if (this.monthTotal === 0 && !this.loading) {
          Column() {
            EmptyState({
              icon: $r('app.media.ic_calendar'),
              title: '这个月还没有支出',
              description: '换个周期试试'
            })
          }
          .width('100%')
          .borderRadius(Radius.cardLg)
          .backgroundColor($r('app.color.chart_surface'))
          .margin({ left: Space.page, right: Space.page })
        } else {
          Column() {
            HeatCalendar({
              monthKey: this.monthKey,
              weekStart: this.weekStart,
              daySums: this.daySums,
              selectedDayKey: this.selectedDayKey,
              hidden: this.ui.hideAmount,
              onSelect: (dayKey: string) => {
                this.selectDay(dayKey);
              }
            })
          }
          .width('100%')
          .padding(15)
          .borderRadius(Radius.cardLg)
          .backgroundColor($r('app.color.chart_surface'))
          .border({ width: 1, color: $r('app.color.line') })
          .margin({ left: Space.page, right: Space.page })
        }

        Column() {
          DayDetailList({
            dayKey: this.selectedDayKey,
            txns: this.txns,
            categories: this.categories,
            members: this.members,
            lockedBookIds: this.allLockedIds(),
            totalCents: this.totalCents
          })
        }
        .width('100%')
        .padding({ left: Space.page, right: Space.page, top: Space.x2 })

        Row().width('100%').height(Space.x8)
      }
      .width('100%')
      .padding({ top: Space.x3 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
  }
}
