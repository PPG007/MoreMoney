import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { Book, Member } from '../../models/Entities';
import { BookDao } from '../../data/db/BookDao';
import { MemberDao } from '../../data/db/MemberDao';
import { SettingsService } from '../../service/SettingsService';
import { PrivateBookService } from '../../service/PrivateBookService';
import { SegmentedControl } from '../../components/base/SegmentedControl';
import { EyeButton } from '../../components/base/EyeButton';
import { CategoryChartPage } from './CategoryChartPage';
import { TrendChartPage } from './TrendChartPage';
import { CalendarChartPage } from './CalendarChartPage';

@ComponentV2
struct ChartFilterChip {
  @Param label: string = '';
  @Param selected: boolean = false;
  @Event onTap: () => void = () => {
  };

  build() {
    Text(this.label)
      .fontSize(AppFont.caption)
      .fontWeight(this.selected ? AppFont.semibold : AppFont.regular)
      .fontColor(this.selected ? $r('app.color.brand_ink') : $r('app.color.ink_2'))
      .padding({ left: 11, right: 11, top: 6, bottom: 6 })
      .borderRadius(Radius.pill)
      .backgroundColor(this.selected ? $r('app.color.brand_wash') : $r('app.color.surface_2'))
      .border({ width: 1, color: this.selected ? $r('app.color.brand_soft') : $r('app.color.line') })
      .onClick(() => {
        this.onTap();
      })
  }
}

@ComponentV2
export struct ChartsPage {
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local selectedTab: number = 0;
  @Local books: Book[] = [];
  @Local members: Member[] = [];
  @Local selectedBookIds: string[] = [];
  @Local selectedMemberIds: string[] = [];
  @Local excludeBookIds: string[] = [];
  @Local weekStart: number = 1;
  @Local filterVersion: number = 0;
  @Local showFilter: boolean = false;
  @Local loading: boolean = true;

  aboutToAppear(): void {
    this.loadMeta();
  }

  @Monitor('ui.unlockVersion')
  onUnlockChanged(): void {
    this.loadMeta();
  }

  private async loadMeta(): Promise<void> {
    try {
      const allBooks: Book[] = await BookDao.list();
      this.books = allBooks.filter((book: Book): boolean => !book.archived);
      this.members = (await MemberDao.list()).filter((member: Member): boolean => !member.archived);
      this.excludeBookIds = await PrivateBookService.lockedBookIds();
      this.weekStart = SettingsService.weekStart();
      this.selectedBookIds = this.selectedBookIds.filter(
        (id: string): boolean => this.books.some((book: Book): boolean => book.id === id)
      );
      this.selectedMemberIds = this.selectedMemberIds.filter(
        (id: string): boolean => this.members.some((member: Member): boolean => member.id === id)
      );
      this.filterVersion += 1;
    } catch (error) {
    } finally {
      this.loading = false;
    }
  }

  private visibleBooks(): Book[] {
    return this.books.filter((book: Book): boolean => this.excludeBookIds.indexOf(book.id) < 0);
  }

  private bookSelected(bookId: string): boolean {
    if (this.selectedBookIds.length === 0) {
      return true;
    }
    return this.selectedBookIds.indexOf(bookId) >= 0;
  }

  private memberSelected(memberId: string): boolean {
    if (this.selectedMemberIds.length === 0) {
      return true;
    }
    return this.selectedMemberIds.indexOf(memberId) >= 0;
  }

  private toggleBook(bookId: string): void {
    const visible: Book[] = this.visibleBooks();
    const current: string[] = this.selectedBookIds.length === 0
      ? visible.map((book: Book): string => book.id)
      : this.selectedBookIds;
    const next: string[] = current.filter((id: string): boolean => id !== bookId);
    if (next.length === current.length) {
      next.push(bookId);
    }
    if (next.length === 0) {
      this.selectedBookIds = [];
    } else if (next.length === visible.length) {
      this.selectedBookIds = [];
    } else {
      this.selectedBookIds = next;
    }
  }

  private toggleMember(memberId: string): void {
    const current: string[] = this.selectedMemberIds.length === 0
      ? this.members.map((member: Member): string => member.id)
      : this.selectedMemberIds;
    const next: string[] = current.filter((id: string): boolean => id !== memberId);
    if (next.length === current.length) {
      next.push(memberId);
    }
    if (next.length === 0) {
      this.selectedMemberIds = [];
    } else if (next.length === this.members.length) {
      this.selectedMemberIds = [];
    } else {
      this.selectedMemberIds = next;
    }
  }

  @Builder
  filterSheet() {
    if (this.showFilter) {
      Stack({ alignContent: Alignment.Bottom }) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.scrim'))
          .onClick(() => {
            this.showFilter = false;
          })

        Scroll() {
          Column({ space: Space.x4 }) {
            Row() {
              Text('筛选')
                .fontSize(AppFont.subTitle)
                .fontWeight(AppFont.bold)
                .fontColor($r('app.color.ink'))
                .layoutWeight(1)
              Text('完成')
                .fontSize(AppFont.settings)
                .fontWeight(AppFont.semibold)
                .fontColor($r('app.color.brand_ink'))
                .onClick(() => {
                  this.showFilter = false;
                  this.filterVersion += 1;
                })
            }
            .width('100%')

            Column({ space: 8 }) {
              Row() {
                Text('账本')
                  .fontSize(AppFont.micro)
                  .fontColor($r('app.color.ink_3'))
                  .layoutWeight(1)
                Text('全部')
                  .fontSize(AppFont.micro)
                  .fontColor($r('app.color.brand_ink'))
                  .onClick(() => {
                    this.selectedBookIds = [];
                  })
              }
              .width('100%')
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.visibleBooks(), (book: Book) => {
                  Row() {
                    ChartFilterChip({
                      label: book.name,
                      selected: this.bookSelected(book.id),
                      onTap: () => {
                        this.toggleBook(book.id);
                      }
                    })
                  }
                  .margin({ right: 8, bottom: 8 })
                }, (book: Book) => book.id)
              }
              .width('100%')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            Column({ space: 8 }) {
              Row() {
                Text('成员')
                  .fontSize(AppFont.micro)
                  .fontColor($r('app.color.ink_3'))
                  .layoutWeight(1)
                Text('全部')
                  .fontSize(AppFont.micro)
                  .fontColor($r('app.color.brand_ink'))
                  .onClick(() => {
                    this.selectedMemberIds = [];
                  })
              }
              .width('100%')
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.members, (member: Member) => {
                  Row() {
                    ChartFilterChip({
                      label: member.name,
                      selected: this.memberSelected(member.id),
                      onTap: () => {
                        this.toggleMember(member.id);
                      }
                    })
                  }
                  .margin({ right: 8, bottom: 8 })
                }, (member: Member) => member.id)
              }
              .width('100%')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            Text('私密账本锁定期间不参与统计')
              .fontSize(AppFont.caption)
              .fontColor($r('app.color.ink_3'))
              .width('100%')
          }
          .width('100%')
          .padding({ left: Space.x7, right: Space.x7, top: 22, bottom: Space.x8 + 10 })
        }
        .constraintSize({ maxHeight: '80%' })
        .borderRadius({ topLeft: Radius.sheet, topRight: Radius.sheet })
        .backgroundColor($r('app.color.surface'))
        .shadow(Shadow.sheet(this.ui.isDark))
      }
      .width('100%')
      .height('100%')
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column({ space: Space.x3 }) {
        Row({ space: Space.x2 }) {
          Text('图表')
            .fontSize(AppFont.pageTitle)
            .fontWeight(AppFont.bold)
            .fontColor($r('app.color.ink'))
            .layoutWeight(1)
          Text('筛选')
            .fontSize(AppFont.caption)
            .fontWeight(AppFont.semibold)
            .fontColor($r('app.color.brand_ink'))
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .borderRadius(Radius.pill)
            .backgroundColor($r('app.color.brand_wash'))
            .onClick(() => {
              this.showFilter = true;
            })
          EyeButton()
        }
        .width('100%')
        .padding({ left: Space.page, right: Space.page, top: this.ui.topInset + 10 })

        SegmentedControl({
          options: ['分类', '趋势', '日历'],
          selectedIndex: this.selectedTab,
          onChange: (index: number) => {
            this.selectedTab = index;
          }
        })
        .padding({ left: Space.page, right: Space.page })

        Column() {
          if (this.selectedTab === 0) {
            CategoryChartPage({
              bookIds: this.selectedBookIds,
              memberIds: this.selectedMemberIds,
              excludeBookIds: this.excludeBookIds,
              weekStart: this.weekStart,
              filterVersion: this.filterVersion
            })
          } else if (this.selectedTab === 1) {
            TrendChartPage({
              bookIds: this.selectedBookIds,
              memberIds: this.selectedMemberIds,
              excludeBookIds: this.excludeBookIds,
              weekStart: this.weekStart,
              filterVersion: this.filterVersion
            })
          } else {
            CalendarChartPage({
              bookIds: this.selectedBookIds,
              memberIds: this.selectedMemberIds,
              excludeBookIds: this.excludeBookIds,
              weekStart: this.weekStart,
              filterVersion: this.filterVersion
            })
          }
        }
        .layoutWeight(1)
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.bg'))

      this.filterSheet()
    }
    .width('100%')
    .height('100%')
  }
}
