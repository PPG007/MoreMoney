import { AppFont, Radius, Space } from '../../theme/Theme';
import { IconSize } from '../../theme/IconSize';
import { SeedColors } from '../../theme/Palette';
import { Book, Budget, TxnFilter } from '../../models/Entities';
import { BookManageParam, NavResult } from '../../models/NavParams';
import { BookDao } from '../../data/db/BookDao';
import { BudgetDao } from '../../data/db/BudgetDao';
import { TxnDao } from '../../data/db/TxnDao';
import { DateUtil, DateRange } from '../../utils/DateUtil';
import { ErrorUtil } from '../../utils/ErrorUtil';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { SnackBarService } from '../../service/SnackBarService';
import { SnackBarOptions } from '../../service/SnackBarService';
import { PrivateBookService } from '../../service/PrivateBookService';
import { SettingsService } from '../../service/SettingsService';
import { BookBudgetState, BudgetService } from '../../service/BudgetService';
import { BudgetPeriod, BudgetPeriodType } from '../../service/BudgetPeriod';
import { BookCard, BookViewData } from './BookCard';
import { BookEditSheet, BookDraft } from './BookEditSheet';
import { BookActions } from './BookActions';
import { BudgetEditDialog } from '../budget/BudgetEditDialog';
import { UnlockSheet } from '../../components/sheet/UnlockSheet';
import { EmptyState } from '../../components/base/EmptyState';
import { EyeButton } from '../../components/base/EyeButton';

@Builder
export function BookManageBuilder() {
  BookManagePage();
}

@ComponentV2
export struct BookManagePage {
  stack: NavPathStack = new NavPathStack();
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local views: BookViewData[] = [];
  @Local monthKey: string = DateUtil.monthKey(new Date());
  @Local filterPrivate: boolean = false;
  @Local showArchived: boolean = false;
  @Local loading: boolean = true;
  @Local showEdit: boolean = false;
  @Local editingBook: Book | null = null;
  @Local showActions: boolean = false;
  @Local actionBook: Book | null = null;
  @Local actionCanDelete: boolean = true;
  @Local showBudgetDialog: boolean = false;
  @Local dialogBookId: string = '';
  @Local dialogBookName: string = '';
  @Local dialogState: BookBudgetState = new BookBudgetState();
  @Local dialogInitialType: BudgetPeriodType = BudgetPeriodType.MONTH;
  @Local showUnlock: boolean = false;
  @Local unlockBookId: string = '';
  @Local unlockBookName: string = '';
  @Local chooseDefaultFor: Book | null = null;
  @Local pendingDraft: BookDraft | null = null;
  @Local pendingDefaultAction: string = '';

  aboutToAppear(): void {
    this.reload();
  }

  @Monitor('ui.unlockVersion')
  onUnlockChanged(): void {
    this.reload();
  }

  @Monitor('ui.budgetVersion')
  onBudgetChanged(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    try {
      const all: Book[] = await BookDao.list();
      const budgets: Budget[] = await BudgetDao.list(BudgetPeriodType.MONTH);
      const range: DateRange = DateUtil.rangeOfMonth(this.monthKey);
      const views: BookViewData[] = [];
      for (const book of all) {
        if (this.filterPrivate && !book.isPrivate) {
          continue;
        }
        if (!this.showArchived && book.archived) {
          continue;
        }
        const view: BookViewData = new BookViewData();
        view.book = book;
        let budgetCents: number = 0;
        const budget: Budget | undefined = budgets.find((item: Budget): boolean => item.bookId === book.id);
        if (budget !== undefined) {
          budgetCents = budget.amountCents;
        }
        const filter: TxnFilter = new TxnFilter();
        filter.bookIds = [book.id];
        filter.startMs = range.startMs;
        filter.endMs = range.endMs;
        view.count = await TxnDao.countRange(filter);
        view.spentCents = await TxnDao.sumRange(filter);
        view.budgetCents = budgetCents;
        view.percent = budgetCents > 0 ? view.spentCents / budgetCents : 0;
        views.push(view);
      }
      this.views = views;
    } catch (error) {
      SnackBarService.show(BookManagePage.toast(ErrorUtil.messageOf(error)));
    } finally {
      this.loading = false;
    }
  }

  private static toast(message: string): SnackBarOptions {
    const options: SnackBarOptions = new SnackBarOptions();
    options.message = message;
    return options;
  }

  private static viewKey(view: BookViewData): string {
    return view.book.id.concat('#')
      .concat(view.book.name)
      .concat('#')
      .concat(view.book.icon)
      .concat('#')
      .concat(view.book.color)
      .concat('#')
      .concat(view.book.isDefault ? '1' : '0')
      .concat('#')
      .concat(view.book.isPrivate ? '1' : '0')
      .concat('#')
      .concat(view.book.archived ? '1' : '0')
      .concat('#')
      .concat(view.count.toString())
      .concat('#')
      .concat(view.budgetCents.toString())
      .concat('#')
      .concat(view.spentCents.toString());
  }

  private isLocked(book: Book): boolean {
    if (!book.isPrivate) {
      return false;
    }
    return !this.ui.isBookUnlocked(book.id);
  }

  private viewOf(bookId: string): BookViewData | undefined {
    return this.views.find((view: BookViewData): boolean => view.book.id === bookId);
  }

  private bookOf(bookId: string): Book | undefined {
    const view: BookViewData | undefined = this.viewOf(bookId);
    return view === undefined ? undefined : view.book;
  }

  private openCreate(): void {
    this.editingBook = null;
    this.showEdit = true;
  }

  private openEdit(bookId: string): void {
    const book: Book | undefined = this.bookOf(bookId);
    if (book === undefined) {
      return;
    }
    this.editingBook = book;
    this.showEdit = true;
  }

  private nextSort(): number {
    let max: number = 0;
    for (const view of this.views) {
      if (view.book.sort > max) {
        max = view.book.sort;
      }
    }
    return max + 1;
  }

  private activeCount(): number {
    return this.views.filter((view: BookViewData): boolean => !view.book.archived).length;
  }

  private async saveDraft(draft: BookDraft): Promise<void> {
    try {
      if (draft.id.length === 0) {
        const allBooks: Book[] = await BookDao.list();
        const active: number = allBooks.filter((item: Book): boolean => !item.archived).length;
        const book: Book = {
          id: 'book_'.concat(Date.now().toString()).concat('_').concat(Math.floor(Math.random() * 1000).toString()),
          name: draft.name,
          icon: draft.icon,
          color: draft.color,
          isPrivate: false,
          pwdHash: null,
          pwdSalt: null,
          pwdIter: 10000,
          isDefault: active === 0,
          sort: this.nextSort(),
          archived: false,
          createdAt: Date.now(),
          updatedAt: Date.now()
        };
        await BookDao.insert(book);
        if (draft.wantPrivate && draft.newPassword.length > 0) {
          await PrivateBookService.setPassword(book.id, draft.newPassword);
        }
      } else {
        const book: Book | undefined = this.bookOf(draft.id);
        if (book === undefined) {
          return;
        }
        if (book.isPrivate && !draft.wantPrivate) {
          this.pendingDraft = draft;
          this.unlockBookId = book.id;
          this.unlockBookName = book.name;
          this.showUnlock = true;
          return;
        }
        await this.updateBook(book, draft);
      }
      this.showEdit = false;
      this.editingBook = null;
      await this.reload();
      SnackBarService.show(BookManagePage.toast('已保存'));
    } catch (error) {
      SnackBarService.show(BookManagePage.toast('保存失败：'.concat(ErrorUtil.messageOf(error))));
    }
  }

  private async updateBook(book: Book, draft: BookDraft): Promise<void> {
    const updated: Book = {
      id: book.id,
      name: draft.name,
      icon: draft.icon,
      color: draft.color,
      isPrivate: book.isPrivate,
      pwdHash: book.pwdHash,
      pwdSalt: book.pwdSalt,
      pwdIter: book.pwdIter,
      isDefault: book.isDefault,
      sort: book.sort,
      archived: book.archived,
      createdAt: book.createdAt,
      updatedAt: Date.now()
    };
    await BookDao.update(updated);
    if (draft.wantPrivate && !book.isPrivate && draft.newPassword.length > 0) {
      await PrivateBookService.setPassword(book.id, draft.newPassword);
    }
  }

  private async onUnlockedForEdit(bookId: string): Promise<void> {
    this.showUnlock = false;
    const draft: BookDraft | null = this.pendingDraft;
    this.pendingDraft = null;
    if (draft === null) {
      await this.reload();
      return;
    }
    try {
      await PrivateBookService.disablePrivate(bookId);
      const book: Book | undefined = this.bookOf(bookId);
      if (book !== undefined) {
        await this.updateBook(book, draft);
      }
      this.showEdit = false;
      this.editingBook = null;
      await this.reload();
      SnackBarService.show(BookManagePage.toast('已保存'));
    } catch (error) {
      SnackBarService.show(BookManagePage.toast('保存失败：'.concat(ErrorUtil.messageOf(error))));
    }
  }

  private async openActions(bookId: string): Promise<void> {
    const book: Book | undefined = this.bookOf(bookId);
    if (book === undefined) {
      return;
    }
    let count: number = 0;
    try {
      count = await TxnDao.countByBook(bookId);
    } catch (error) {
      count = 0;
    }
    this.actionBook = book;
    this.actionCanDelete = count === 0;
    this.showActions = true;
  }

  private async setDefault(bookId: string): Promise<void> {
    try {
      await BookDao.setDefault(bookId);
      await SettingsService.setDefaultBookId(bookId);
      this.showActions = false;
      await this.reload();
      SnackBarService.show(BookManagePage.toast('已设为默认账本'));
    } catch (error) {
      SnackBarService.show(BookManagePage.toast(ErrorUtil.messageOf(error)));
    }
  }

  private otherActiveBooks(bookId: string): Book[] {
    const result: Book[] = [];
    for (const view of this.views) {
      if (!view.book.archived && view.book.id !== bookId) {
        result.push(view.book);
      }
    }
    return result;
  }

  private requestArchive(bookId: string): void {
    const book: Book | undefined = this.bookOf(bookId);
    if (book === undefined) {
      return;
    }
    this.showActions = false;
    if (book.isDefault && this.otherActiveBooks(bookId).length > 0) {
      this.pendingDefaultAction = 'archive';
      this.chooseDefaultFor = book;
      return;
    }
    if (book.isDefault && this.otherActiveBooks(bookId).length === 0) {
      SnackBarService.show(BookManagePage.toast('至少保留一个账本'));
      return;
    }
    AlertDialog.show({
      title: '归档账本',
      message: '归档后不再出现在记账和统计中，历史数据保留。',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '归档',
        action: () => {
          this.performArchive(bookId);
        }
      }
    });
  }

  private async performArchive(bookId: string): Promise<void> {
    try {
      await BookDao.archive(bookId);
      await this.reload();
      SnackBarService.show(BookManagePage.toast('已归档'));
    } catch (error) {
      SnackBarService.show(BookManagePage.toast(ErrorUtil.messageOf(error)));
    }
  }

  private requestDelete(bookId: string): void {
    const book: Book | undefined = this.bookOf(bookId);
    if (book === undefined) {
      return;
    }
    this.showActions = false;
    if (!this.actionCanDelete) {
      SnackBarService.show(BookManagePage.toast('该账本已有流水，请使用归档'));
      return;
    }
    if (book.isDefault && this.otherActiveBooks(bookId).length > 0) {
      this.pendingDefaultAction = 'delete';
      this.chooseDefaultFor = book;
      return;
    }
    if (book.isDefault && this.otherActiveBooks(bookId).length === 0) {
      SnackBarService.show(BookManagePage.toast('至少保留一个账本'));
      return;
    }
    AlertDialog.show({
      title: '删除账本',
      message: '确定删除「'.concat(book.name).concat('」吗？'),
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: $r('app.color.expense'),
        action: () => {
          this.performDelete(bookId);
        }
      }
    });
  }

  private async performDelete(bookId: string): Promise<void> {
    try {
      await BookDao.delete(bookId);
      await this.reload();
      SnackBarService.show(BookManagePage.toast('已删除'));
    } catch (error) {
      SnackBarService.show(BookManagePage.toast(ErrorUtil.messageOf(error)));
    }
  }

  private async openBudget(bookId: string): Promise<void> {
    const view: BookViewData | undefined = this.viewOf(bookId);
    if (view === undefined) {
      return;
    }
    try {
      this.dialogState = await BudgetService.getBookState(bookId);
      this.dialogBookId = bookId;
      this.dialogBookName = view.book.name;
      this.dialogInitialType = BudgetPeriodType.MONTH;
      this.showBudgetDialog = true;
    } catch (error) {
      SnackBarService.show(BookManagePage.toast('读取预算失败：'.concat(ErrorUtil.messageOf(error))));
    }
  }

  private async saveBudget(type: BudgetPeriodType, cents: number): Promise<void> {
    try {
      await BudgetService.setBudget(this.dialogBookId, type, cents);
      this.showBudgetDialog = false;
      await this.reload();
      SnackBarService.show(BookManagePage.toast(
        cents > 0 ? '预算已保存' : '已取消'.concat(BudgetPeriod.noun(type)).concat('预算')
      ));
    } catch (error) {
      SnackBarService.show(BookManagePage.toast('保存失败：'.concat(ErrorUtil.messageOf(error))));
    }
  }

  private openUnlock(bookId: string): void {
    const book: Book | undefined = this.bookOf(bookId);
    if (book === undefined) {
      return;
    }
    this.unlockBookId = bookId;
    this.unlockBookName = book.name;
    this.showUnlock = true;
  }

  private async chooseDefault(bookId: string): Promise<void> {
    const target: Book | null = this.chooseDefaultFor;
    const action: string = this.pendingDefaultAction;
    this.chooseDefaultFor = null;
    this.pendingDefaultAction = '';
    try {
      await BookDao.setDefault(bookId);
      await SettingsService.setDefaultBookId(bookId);
      if (target !== null) {
        if (action === 'delete') {
          await this.performDelete(target.id);
        } else {
          await this.performArchive(target.id);
        }
      }
      await this.reload();
    } catch (error) {
      SnackBarService.show(BookManagePage.toast(ErrorUtil.messageOf(error)));
    }
  }

  private chooseCandidates(): Book[] {
    return this.views
      .filter((view: BookViewData): boolean => !view.book.archived)
      .filter((view: BookViewData): boolean => this.chooseDefaultFor === null || view.book.id !== this.chooseDefaultFor.id)
      .map((view: BookViewData): Book => view.book);
  }

  @Builder
  header() {
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

      Text('账本管理')
        .fontSize(AppFont.subTitle)
        .fontWeight(AppFont.bold)
        .fontColor($r('app.color.ink'))
        .layoutWeight(1)

      EyeButton()

      Stack() {
        Image($r('app.media.ic_plus'))
          .width(17)
          .height(17)
          .fillColor($r('app.color.brand_ink'))
      }
      .width(34)
      .height(34)
      .borderRadius(Radius.pill)
      .backgroundColor($r('app.color.brand_wash'))
      .onClick(() => {
        this.openCreate();
      })
    }
    .width('100%')
    .height(52 + this.ui.topInset)
    .padding({ top: this.ui.topInset, left: Space.page, right: Space.page })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  defaultPicker() {
    if (this.chooseDefaultFor !== null) {
      Stack({ alignContent: Alignment.Bottom }) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.scrim'))
          .onClick(() => {
            this.chooseDefaultFor = null;
          })
        Column({ space: Space.x3 }) {
          Text('请选择新的默认账本')
            .fontSize(AppFont.subTitle)
            .fontWeight(AppFont.bold)
            .fontColor($r('app.color.ink'))
            .width('100%')
          ForEach(this.chooseCandidates(), (book: Book) => {
            Row({ space: 9 }) {
              Image($r('app.media.' + book.icon))
                .width(20)
                .height(20)
                .fillColor(book.color)
              Text(book.name)
                .fontSize(AppFont.row)
                .fontWeight(AppFont.medium)
                .fontColor($r('app.color.ink'))
                .layoutWeight(1)
            }
            .width('100%')
            .height(50)
            .padding({ left: 12, right: 12 })
            .borderRadius(Radius.input)
            .backgroundColor($r('app.color.surface_2'))
            .onClick(() => {
              this.chooseDefault(book.id);
            })
          }, (book: Book) => book.id)
        }
        .width('100%')
        .padding({ left: Space.x7, right: Space.x7, top: 22, bottom: Space.x8 + 10 })
        .borderRadius({ topLeft: Radius.sheet, topRight: Radius.sheet })
        .backgroundColor($r('app.color.surface'))
      }
      .width('100%')
      .height('100%')
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          this.header()

          if (this.views.length === 0) {
            Column() {
              EmptyState({
                icon: $r('app.media.ic_book'),
                title: this.filterPrivate ? '还没有私密账本' : '还没有账本',
                description: this.filterPrivate ? '在账本管理中开启私密' : '点击右上角 + 新建账本',
                actionLabel: this.filterPrivate ? '' : '新建账本',
                onAction: () => {
                  this.openCreate();
                }
              })
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else {
            List() {
              ForEach(this.views, (view: BookViewData) => {
                ListItem() {
                  BookCard({
                    data: view,
                    locked: this.isLocked(view.book),
                    onEdit: (bookId: string) => {
                      this.openEdit(bookId);
                    },
                    onMore: (bookId: string) => {
                      this.openActions(bookId);
                    },
                    onBudget: (bookId: string) => {
                      this.openBudget(bookId);
                    },
                    onUnlock: (bookId: string) => {
                      this.openUnlock(bookId);
                    }
                  })
                }
                .margin({ bottom: 9 })
              }, (view: BookViewData) => BookManagePage.viewKey(view))

              ListItem() {
                Row() {
                  Text(this.showArchived ? '隐藏已归档' : '显示已归档')
                    .fontSize(AppFont.caption)
                    .fontWeight(AppFont.semibold)
                    .fontColor($r('app.color.brand_ink'))
                }
                .width('100%')
                .height(44)
                .justifyContent(FlexAlign.Center)
                .onClick(() => {
                  this.showArchived = !this.showArchived;
                  this.reload();
                })
              }
            }
            .width('100%')
            .layoutWeight(1)
            .padding({ left: Space.page, right: Space.page, top: Space.x2 })
            .scrollBar(BarState.Off)
          }
        }
        .width('100%')
        .height('100%')

        this.defaultPicker()

        BookActions({
          visible: this.showActions,
          book: this.actionBook,
          canDelete: this.actionCanDelete,
          onSetDefault: (bookId: string) => {
            this.setDefault(bookId);
          },
          onArchive: (bookId: string) => {
            this.requestArchive(bookId);
          },
          onDelete: (bookId: string) => {
            this.requestDelete(bookId);
          },
          onClose: () => {
            this.showActions = false;
          }
        })

        UnlockSheet({
          visible: this.showUnlock,
          bookId: this.unlockBookId,
          bookName: this.unlockBookName,
          onUnlocked: (bookId: string) => {
            if (this.pendingDraft !== null) {
              this.onUnlockedForEdit(bookId);
            } else {
              this.showUnlock = false;
              this.reload();
            }
          },
          onClose: () => {
            this.showUnlock = false;
          }
        })

        BookEditSheet({
          visible: this.showEdit,
          isEdit: this.editingBook !== null,
          initialId: this.editingBook === null ? '' : this.editingBook.id,
          initialName: this.editingBook === null ? '' : this.editingBook.name,
          initialIcon: this.editingBook === null ? 'ic_book_daily' : this.editingBook.icon,
          initialColor: this.editingBook === null ? SeedColors.c1 : this.editingBook.color,
          initialPrivate: this.editingBook === null ? false : this.editingBook.isPrivate,
          onSave: (draft: BookDraft) => {
            this.saveDraft(draft);
          },
          onClose: () => {
            this.showEdit = false;
            this.editingBook = null;
          }
        })

        BudgetEditDialog({
          visible: this.showBudgetDialog,
          bookName: this.dialogBookName,
          state: this.dialogState,
          initialType: this.dialogInitialType,
          onSave: (type: BudgetPeriodType, cents: number) => {
            this.saveBudget(type, cents);
          },
          onClose: () => {
            this.showBudgetDialog = false;
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
      if (context.pathInfo.param instanceof BookManageParam) {
        this.filterPrivate = context.pathInfo.param.filterPrivate;
      }
    })
  }
}
