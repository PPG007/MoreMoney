import { AppFont, Radius, Space } from '../../theme/Theme';
import { IconSize } from '../../theme/IconSize';
import { Book, Category, Member, Txn } from '../../models/Entities';
import { NavResult } from '../../models/NavParams';
import { TxnDao } from '../../data/db/TxnDao';
import { BookDao } from '../../data/db/BookDao';
import { CategoryDao } from '../../data/db/CategoryDao';
import { MemberDao } from '../../data/db/MemberDao';
import { PrivateBookService } from '../../service/PrivateBookService';
import { SettingsService } from '../../service/SettingsService';
import { ErrorUtil } from '../../utils/ErrorUtil';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { EyeButton } from '../../components/base/EyeButton';
import { EmptyState } from '../../components/base/EmptyState';
import { TxnRow } from '../home/TxnRow';
import { TxnDetailSheet } from '../../components/sheet/TxnDetailSheet';

const SEARCH_LIMIT: number = 200;
const RECENT_LIMIT: number = 10;
const DEBOUNCE_MS: number = 300;

@Builder
export function SearchBuilder() {
  SearchPage();
}

@ComponentV2
export struct SearchPage {
  stack: NavPathStack = new NavPathStack();
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local keyword: string = '';
  @Local results: Txn[] = [];
  @Local searched: boolean = false;
  @Local recent: string[] = [];
  @Local books: Book[] = [];
  @Local categories: Category[] = [];
  @Local members: Member[] = [];
  @Local lockedIds: string[] = [];
  @Local showDetail: boolean = false;
  @Local detailTxn: Txn | null = null;
  private timerId: number = -1;

  aboutToAppear(): void {
    this.recent = SettingsService.recentSearches();
    this.loadMeta();
  }

  aboutToDisappear(): void {
    this.clearTimer();
  }

  private async loadMeta(): Promise<void> {
    try {
      this.books = await BookDao.list();
      this.members = await MemberDao.list();
      const groups = await CategoryDao.listGroups();
      const categories: Category[] = [];
      for (const group of groups) {
        const list: Category[] = await CategoryDao.listByGroup(group.id);
        for (const category of list) {
          categories.push(category);
        }
      }
      this.categories = categories;
      this.lockedIds = await PrivateBookService.lockedBookIds();
    } catch (error) {
    }
  }

  private clearTimer(): void {
    if (this.timerId !== -1) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
  }

  private onKeywordChange(value: string): void {
    this.keyword = value;
    this.clearTimer();
    if (value.trim().length === 0) {
      this.results = [];
      this.searched = false;
      return;
    }
    this.timerId = setTimeout(() => {
      this.performSearch();
    }, DEBOUNCE_MS);
  }

  private async performSearch(): Promise<void> {
    const keyword: string = this.keyword.trim();
    if (keyword.length === 0) {
      this.results = [];
      this.searched = false;
      return;
    }
    try {
      this.results = await TxnDao.search(keyword, SEARCH_LIMIT, this.lockedIds);
      this.searched = true;
      this.rememberKeyword(keyword);
    } catch (error) {
      this.results = [];
      this.searched = true;
    }
  }

  private async rememberKeyword(keyword: string): Promise<void> {
    const list: string[] = this.recent.filter((item: string): boolean => item !== keyword);
    list.unshift(keyword);
    const trimmed: string[] = list.slice(0, RECENT_LIMIT);
    this.recent = trimmed;
    await SettingsService.setRecentSearches(trimmed);
  }

  private useRecent(keyword: string): void {
    this.keyword = keyword;
    this.performSearch();
  }

  private clearRecent(): void {
    this.recent = [];
    SettingsService.setRecentSearches([]);
  }

  private categoryOf(id: string): Category | null {
    const found: Category | undefined = this.categories.find((item: Category): boolean => item.id === id);
    return found === undefined ? null : found;
  }

  private memberOf(id: string): Member | null {
    const found: Member | undefined = this.members.find((item: Member): boolean => item.id === id);
    return found === undefined ? null : found;
  }

  private bookName(bookId: string): string {
    const found: Book | undefined = this.books.find((item: Book): boolean => item.id === bookId);
    return found === undefined ? '' : found.name;
  }

  private isLocked(bookId: string): boolean {
    return this.lockedIds.indexOf(bookId) >= 0;
  }

  private openDetail(txn: Txn): void {
    this.detailTxn = txn;
    this.showDetail = true;
  }

  private detailCategory(): Category | null {
    return this.detailTxn === null ? null : this.categoryOf(this.detailTxn.categoryId);
  }

  private detailMember(): Member | null {
    return this.detailTxn === null ? null : this.memberOf(this.detailTxn.memberId);
  }

  private detailBookName(): string {
    return this.detailTxn === null ? '' : this.bookName(this.detailTxn.bookId);
  }

  private detailLocked(): boolean {
    return this.detailTxn === null ? false : this.isLocked(this.detailTxn.bookId);
  }

  @Builder
  recentChips() {
    Column({ space: Space.x2 }) {
      Row() {
        Text('最近搜索')
          .fontSize(AppFont.micro)
          .fontWeight(AppFont.semibold)
          .fontColor($r('app.color.ink_2'))
          .layoutWeight(1)
        Text('清空')
          .fontSize(AppFont.micro)
          .fontWeight(AppFont.semibold)
          .fontColor($r('app.color.brand_ink'))
          .onClick(() => {
            this.clearRecent();
          })
      }
      .width('100%')
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.recent, (item: string) => {
          Text(item)
            .fontSize(AppFont.caption)
            .fontWeight(AppFont.medium)
            .fontColor($r('app.color.ink_2'))
            .padding({ left: 9, right: 9, top: 5, bottom: 5 })
            .borderRadius(Radius.pill)
            .backgroundColor($r('app.color.surface_2'))
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.useRecent(item);
            })
        }, (item: string) => item)
      }
      .width('100%')
    }
    .width('100%')
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column({ space: Space.x3 }) {
          Row({ space: Space.x2 }) {
            Stack() {
              Image($r('app.media.ic_back'))
                .width(IconSize.back)
                .height(IconSize.back)
                .fillColor($r('app.color.ink'))
            }
            .width(34)
            .height(34)
            .borderRadius(Radius.pill)
            .backgroundColor($r('app.color.surface'))
            .border({ width: 1, color: $r('app.color.line') })
            .onClick(() => {
              this.stack.pop(new NavResult());
            })

            Row({ space: 7 }) {
              Image($r('app.media.ic_search'))
                .width(15)
                .height(15)
                .fillColor($r('app.color.ink_3'))
              TextInput({ text: this.keyword, placeholder: '搜索备注、分类或成员' })
                .layoutWeight(1)
                .height(36)
                .fontSize(AppFont.legend)
                .fontColor($r('app.color.ink'))
                .placeholderColor($r('app.color.ink_3'))
                .backgroundColor(Color.Transparent)
                .padding({ left: 0, right: 0 })
                .onChange((value: string) => {
                  this.onKeywordChange(value);
                })
                .onSubmit(() => {
                  this.clearTimer();
                  this.performSearch();
                })
            }
            .layoutWeight(1)
            .height(36)
            .padding({ left: 11, right: 11 })
            .borderRadius(Radius.pill)
            .backgroundColor($r('app.color.surface'))
            .border({ width: 1, color: $r('app.color.line') })

            EyeButton()
          }
          .width('100%')
          .height(52 + this.ui.topInset)
          .padding({ top: this.ui.topInset, left: Space.page, right: Space.page })
          .alignItems(VerticalAlign.Center)

          if (this.keyword.trim().length === 0) {
            Column() {
              if (this.recent.length > 0) {
                this.recentChips()
              }
            }
            .width('100%')
            .padding({ left: Space.page, right: Space.page })
          } else {
            Column() {
              if (this.searched) {
                Row() {
                  Text('找到 '.concat(this.results.length.toString()).concat(' 笔'))
                    .fontSize(AppFont.caption)
                    .fontColor($r('app.color.ink_3'))
                    .layoutWeight(1)
                  if (this.results.length >= SEARCH_LIMIT) {
                    Text('结果过多，请细化关键词')
                      .fontSize(AppFont.micro)
                      .fontColor($r('app.color.warn'))
                  }
                }
                .width('100%')
                .padding({ left: Space.page, right: Space.page })
              }
            }
            .width('100%')
          }

          if (this.keyword.trim().length === 0) {
            Row().width('100%').layoutWeight(1)
          } else if (this.searched && this.results.length === 0) {
            Column() {
              EmptyState({
                icon: $r('app.media.ic_search'),
                title: '没有找到相关记录',
                description: '试试备注、分类或成员名'
              })
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else {
            List() {
              ForEach(this.results, (txn: Txn, index: number) => {
                ListItem() {
                  TxnRow({
                    txn: txn,
                    category: this.categoryOf(txn.categoryId),
                    member: this.memberOf(txn.memberId),
                    locked: this.isLocked(txn.bookId),
                    showDate: true,
                    isFirst: index === 0,
                    isLast: index === this.results.length - 1,
                    onTap: () => {
                      this.openDetail(txn);
                    }
                  })
                }
                .margin({ bottom: 6 })
              }, (txn: Txn) => txn.id)
            }
            .width('100%')
            .layoutWeight(1)
            .padding({ left: Space.page, right: Space.page })
            .scrollBar(BarState.Off)
          }
        }
        .width('100%')
        .height('100%')

        TxnDetailSheet({
          visible: this.showDetail,
          txn: this.detailTxn,
          category: this.detailCategory(),
          member: this.detailMember(),
          bookName: this.detailBookName(),
          locked: this.detailLocked(),
          onClose: () => {
            this.showDetail = false;
          }
        })
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg'))
    .onReady((context: NavDestinationContext) => {
      this.stack = context.pathStack;
    })
  }
}
