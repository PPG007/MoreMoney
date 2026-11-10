import { AppFont, Radius, Space } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { AddTxnParam, NavResult } from '../../models/NavParams';
import { Book, Category, Member, Txn } from '../../models/Entities';
import { BookDao } from '../../data/db/BookDao';
import { CategoryDao } from '../../data/db/CategoryDao';
import { MemberDao } from '../../data/db/MemberDao';
import { TxnDao } from '../../data/db/TxnDao';
import { CalcEngine } from '../../utils/ExpressionEngine';
import { CalcPreview, CalcResult, Operator } from '../../utils/CalcTypes';
import { DateUtil } from '../../utils/DateUtil';
import { ErrorUtil } from '../../utils/ErrorUtil';
import { IdUtil } from '../../utils/IdUtil';
import { formatCents } from '../../utils/MoneyUtil';
import { SettingsService } from '../../service/SettingsService';
import { SnackBarService } from '../../service/SnackBarService';
import { SnackBarOptions } from '../../service/SnackBarService';
import { CategoryPicker, CategoryGroupData } from './CategoryPicker';
import { SelectorRow } from './SelectorRow';
import { AmountRow } from './AmountRow';
import { CalcKeypad } from './CalcKeypad';
import { NoteEditor } from './NoteEditor';
import { BookPickerSheet } from '../../components/sheet/BookPickerSheet';
import { MemberPickerSheet } from '../../components/sheet/MemberPickerSheet';
import { UnlockSheet } from '../../components/sheet/UnlockSheet';

const FREQUENT_LIMIT: number = 8;
const FREQUENT_DAYS: number = 30;

@Builder
export function AddTxnBuilder() {
  AddTxnPage();
}

@ComponentV2
export struct AddTxnPage {
  stack: NavPathStack = new NavPathStack();
  @Local param: AddTxnParam = new AddTxnParam();
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local books: Book[] = [];
  @Local members: Member[] = [];
  @Local groups: CategoryGroupData[] = [];
  @Local selectedCategoryId: string = '';
  @Local selectedBookId: string = '';
  @Local selectedMemberId: string = '';
  @Local dayKey: string = DateUtil.dayKey(new Date());
  @Local expression: string = '';
  @Local previewText: string = '请输入金额';
  @Local previewValid: boolean = false;
  @Local note: string = '';
  @Local noteExpanded: boolean = false;
  @Local bookLabel: string = '选择账本';
  @Local memberLabel: string = '选择成员';
  @Local dayLabelText: string = '';
  @Local showBookSheet: boolean = false;
  @Local showMemberSheet: boolean = false;
  @Local showUnlock: boolean = false;
  @Local unlockBookId: string = '';
  @Local unlockBookName: string = '';
  @Local dirty: boolean = false;
  @Local loading: boolean = true;
  private engine: CalcEngine = new CalcEngine();

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    try {
      this.books = (await BookDao.list()).filter((book: Book): boolean => !book.archived);
      this.members = (await MemberDao.list()).filter((member: Member): boolean => !member.archived);
      this.groups = await this.loadCategoryGroups();

      const defaultMember: Member | undefined = this.members.find((member: Member): boolean => member.isDefault);
      if (defaultMember !== undefined) {
        this.selectedMemberId = defaultMember.id;
      } else if (this.members.length > 0) {
        this.selectedMemberId = this.members[0].id;
      }

      this.selectedBookId = this.resolveBookId();
      if (this.param.dayKey.length > 0) {
        this.dayKey = this.param.dayKey;
      }
      this.updateLabels();
    } catch (error) {
      SnackBarService.show(AddTxnPage.errorOptions(ErrorUtil.messageOf(error)));
    } finally {
      this.loading = false;
      this.syncEngine();
    }
  }

  private static errorOptions(message: string): SnackBarOptions {
    const options: SnackBarOptions = new SnackBarOptions();
    options.message = message;
    return options;
  }

  private resolveBookId(): string {
    const byParam: Book | undefined = this.books.find((book: Book): boolean => book.id === this.param.bookId);
    if (byParam !== undefined && !this.isBookLocked(byParam.id)) {
      return byParam.id;
    }
    const bySetting: Book | undefined = this.books.find((book: Book): boolean => book.id === SettingsService.defaultBookId());
    if (bySetting !== undefined && !this.isBookLocked(bySetting.id)) {
      return bySetting.id;
    }
    const byDefault: Book | undefined = this.books.find((book: Book): boolean => book.isDefault);
    if (byDefault !== undefined && !this.isBookLocked(byDefault.id)) {
      return byDefault.id;
    }
    const firstUnlocked: Book | undefined = this.books.find((book: Book): boolean => !this.isBookLocked(book.id));
    if (firstUnlocked !== undefined) {
      return firstUnlocked.id;
    }
    return this.books.length > 0 ? this.books[0].id : '';
  }

  private isBookLocked(bookId: string): boolean {
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

  private async loadCategoryGroups(): Promise<CategoryGroupData[]> {
    const all: Category[] = [];
    const groupList = await CategoryDao.listGroups();
    for (const group of groupList) {
      const categories: Category[] = await CategoryDao.listByGroup(group.id);
      for (const category of categories) {
        if (!category.archived) {
          all.push(category);
        }
      }
    }
    all.sort((a: Category, b: Category): number => a.pinyin.localeCompare(b.pinyin));

    const since: number = Date.now() - FREQUENT_DAYS * 24 * 60 * 60 * 1000;
    const frequent: Category[] = await CategoryDao.listFrequent(FREQUENT_LIMIT, since);
    const usedIds: string[] = frequent.map((category: Category): string => category.id);
    const filled: Category[] = [];
    for (const category of frequent) {
      filled.push(category);
    }
    for (const category of all) {
      if (filled.length >= FREQUENT_LIMIT) {
        break;
      }
      if (usedIds.indexOf(category.id) < 0) {
        filled.push(category);
      }
    }

    const result: CategoryGroupData[] = [];
    const frequentGroup: CategoryGroupData = new CategoryGroupData();
    frequentGroup.groupId = '__frequent__';
    frequentGroup.name = '常用';
    frequentGroup.hint = '按使用频率';
    frequentGroup.categories = filled;
    result.push(frequentGroup);

    for (const group of groupList) {
      const categories: Category[] = await CategoryDao.listByGroup(group.id);
      const active: Category[] = categories.filter((category: Category): boolean => !category.archived);
      if (active.length === 0) {
        continue;
      }
      const data: CategoryGroupData = new CategoryGroupData();
      data.groupId = group.id;
      data.name = group.name;
      data.hint = active.length.toString().concat(' 个分类');
      data.categories = active;
      result.push(data);
    }
    return result;
  }

  private syncEngine(): void {
    this.expression = this.engine.expression;
    const preview: CalcPreview = this.engine.preview();
    this.previewText = preview.text;
    this.previewValid = preview.valid;
  }

  private canSave(): boolean {
    return this.previewValid && this.selectedCategoryId.length > 0 && this.selectedBookId.length > 0;
  }

  private pressDigit(digit: string): void {
    this.engine.appendDigit(digit);
    this.dirty = true;
    this.noteExpanded = false;
    this.syncEngine();
  }

  private pressOperator(op: Operator): void {
    this.engine.appendOperator(op);
    this.dirty = true;
    this.noteExpanded = false;
    this.syncEngine();
  }

  private pressBackspace(): void {
    this.engine.backspace();
    this.dirty = true;
    this.syncEngine();
  }

  private clearExpression(): void {
    this.engine.clear();
    this.dirty = true;
    this.syncEngine();
  }

  private selectCategory(categoryId: string): void {
    this.selectedCategoryId = categoryId;
    this.dirty = true;
    this.noteExpanded = false;
  }

  private selectBook(bookId: string): void {
    if (this.isBookLocked(bookId)) {
      const book: Book | undefined = this.books.find((item: Book): boolean => item.id === bookId);
      this.unlockBookId = bookId;
      this.unlockBookName = book === undefined ? '' : book.name;
      this.showBookSheet = false;
      this.showUnlock = true;
      return;
    }
    this.selectedBookId = bookId;
    this.showBookSheet = false;
    this.dirty = true;
    this.noteExpanded = false;
    this.updateLabels();
  }

  private selectMember(memberId: string): void {
    this.selectedMemberId = memberId;
    this.showMemberSheet = false;
    this.dirty = true;
    this.updateLabels();
  }

  private openMemberManage(): void {
    this.showMemberSheet = false;
    this.stack.pushPathByName('MemberManage', '', (popInfo: PopInfo) => {
      this.reloadMembers();
    });
  }

  private async reloadMembers(): Promise<void> {
    try {
      this.members = (await MemberDao.list()).filter((member: Member): boolean => !member.archived);
      const exists: boolean = this.members.some((member: Member): boolean => member.id === this.selectedMemberId);
      if (!exists) {
        const defaultMember: Member | undefined = this.members.find((member: Member): boolean => member.isDefault);
        this.selectedMemberId = defaultMember === undefined
          ? (this.members.length > 0 ? this.members[0].id : '')
          : defaultMember.id;
      }
      this.updateLabels();
    } catch (error) {
      SnackBarService.show(AddTxnPage.errorOptions(ErrorUtil.messageOf(error)));
    }
  }

  private pickDate(): void {
    const parts: string[] = this.dayKey.split('-');
    const selected: Date = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]), 0, 0, 0, 0);
    const now: Date = new Date();
    const end: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
    this.getUIContext().showDatePickerDialog({
      start: new Date(2000, 0, 1),
      end: end,
      selected: selected,
      onDateAccept: (value: Date) => {
        this.dayKey = DateUtil.dayKey(value);
        this.updateLabels();
        this.dirty = true;
        this.noteExpanded = false;
      }
    });
  }

  private updateLabels(): void {
    const date: Date = DateUtil.parseDayKey(this.dayKey);
    this.dayLabelText = (date.getMonth() + 1).toString().concat('月').concat(date.getDate().toString()).concat('日');
    const book: Book | undefined = this.books.find((item: Book): boolean => item.id === this.selectedBookId);
    this.bookLabel = book === undefined ? '选择账本' : book.name;
    const member: Member | undefined = this.members.find((item: Member): boolean => item.id === this.selectedMemberId);
    this.memberLabel = member === undefined ? '选择成员' : member.name;
  }

  private hasInput(): boolean {
    return this.dirty || this.selectedCategoryId.length > 0 || this.engine.expression.length > 0 ||
      this.note.length > 0;
  }

  private closePage(): void {
    if (this.hasInput()) {
      this.confirmDiscard();
    } else {
      this.stack.pop(new NavResult());
    }
  }

  private confirmDiscard(): void {
    AlertDialog.show({
      title: '放弃这笔记录？',
      message: '当前输入不会保存',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '放弃',
        fontColor: $r('app.color.expense'),
        action: () => {
          this.stack.pop(new NavResult());
        }
      }
    });
  }

  private async save(): Promise<void> {
    const result: CalcResult = this.engine.evaluate();
    if (!result.ok) {
      SnackBarService.show(AddTxnPage.errorOptions(this.previewText));
      return;
    }
    if (this.selectedCategoryId.length === 0) {
      SnackBarService.show(AddTxnPage.errorOptions('请选择分类'));
      return;
    }
    if (this.selectedBookId.length === 0) {
      SnackBarService.show(AddTxnPage.errorOptions('请选择账本'));
      return;
    }
    const now: Date = new Date();
    const day: Date = DateUtil.parseDayKey(this.dayKey);
    const occurredAt: number = new Date(day.getFullYear(), day.getMonth(), day.getDate(),
      now.getHours(), now.getMinutes(), now.getSeconds(), now.getMilliseconds()).getTime();
    const txn: Txn = {
      id: IdUtil.next(),
      bookId: this.selectedBookId,
      categoryId: this.selectedCategoryId,
      memberId: this.selectedMemberId,
      amountCents: result.cents,
      occurredAt: occurredAt,
      dayKey: this.dayKey,
      note: this.note.trim(),
      createdAt: now.getTime(),
      updatedAt: now.getTime(),
      deletedAt: null
    };
    try {
      await TxnDao.insert(txn);
      this.dirty = false;
      this.ui.notifyTxnChanged();
      SnackBarService.show(AddTxnPage.successOptions(result.cents, txn.note));
      this.stack.pop(new NavResult());
    } catch (error) {
      SnackBarService.show(AddTxnPage.errorOptions('保存失败：'.concat(ErrorUtil.messageOf(error))));
    }
  }

  private static successOptions(cents: number, note: string): SnackBarOptions {
    const options: SnackBarOptions = new SnackBarOptions();
    let message: string = '已记一笔 '.concat(formatCents(cents));
    if (note.length > 0) {
      const short: string = note.length > 12 ? note.substring(0, 12).concat('…') : note;
      message = message.concat(' · ').concat(short);
    }
    options.message = message;
    return options;
  }

  @Builder
  topBar() {
    Row() {
      Stack() {
        Image($r('app.media.ic_close'))
          .width(17)
          .height(17)
          .fillColor($r('app.color.ink'))
      }
      .width(34)
      .height(34)
      .borderRadius(Radius.pill)
      .backgroundColor($r('app.color.surface'))
      .border({ width: 1, color: $r('app.color.line') })
      .onClick(() => {
        this.closePage();
      })

      Column({ space: 1 }) {
        Text('记一笔')
          .fontSize(AppFont.row)
          .fontWeight(AppFont.bold)
          .fontColor($r('app.color.ink'))
        Text('仅支出')
          .fontSize(AppFont.micro)
          .fontColor($r('app.color.ink_3'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Row().width(34).height(34)
    }
    .width('100%')
    .height(48 + this.ui.topInset)
    .padding({ top: this.ui.topInset, left: Space.page, right: Space.page })
    .alignItems(VerticalAlign.Center)
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          this.topBar()

          if (this.loading) {
            Column() {
              LoadingProgress()
                .width(28)
                .height(28)
                .color($r('app.color.brand'))
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else {
            Column() {
              CategoryPicker({
                groups: this.groups,
                selectedId: this.selectedCategoryId,
                onSelect: (categoryId: string) => {
                  this.selectCategory(categoryId);
                }
              })
            }
            .layoutWeight(1)
            .width('100%')
          }

          SelectorRow({
            bookName: this.bookLabel,
            memberName: this.memberLabel,
            dayLabel: this.dayLabelText,
            onBook: () => {
              this.showBookSheet = true;
              this.noteExpanded = false;
            },
            onMember: () => {
              this.showMemberSheet = true;
              this.noteExpanded = false;
            },
            onDate: () => {
              this.pickDate();
            }
          })

          AmountRow({
            expression: this.expression,
            previewText: this.previewText,
            previewValid: this.previewValid,
            note: this.note,
            canSave: this.canSave(),
            onNoteTap: () => {
              this.noteExpanded = true;
            },
            onSave: () => {
              this.save();
            }
          })

          if (this.noteExpanded) {
            Column() {
              NoteEditor({
                note: this.note,
                onNoteChange: (value: string) => {
                  this.note = value;
                  this.dirty = true;
                },
                onDone: () => {
                  this.noteExpanded = false;
                }
              })
            }
            .width('100%')
            .padding({ left: Space.page, right: Space.page })
          } else {
            CalcKeypad({
              onDigit: (digit: string) => {
                this.pressDigit(digit);
              },
              onOperator: (op: Operator) => {
                this.pressOperator(op);
              },
              onBackspace: () => {
                this.pressBackspace();
              },
              onClear: () => {
                this.clearExpression();
              }
            })
          }

          Row().width('100%').height(this.ui.bottomInset + 6)
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.bg'))

        BookPickerSheet({
          visible: this.showBookSheet,
          books: this.books,
          selectedId: this.selectedBookId,
          lockedIds: this.lockedBookIds(),
          onSelect: (bookId: string) => {
            this.selectBook(bookId);
          },
          onClose: () => {
            this.showBookSheet = false;
          }
        })

        MemberPickerSheet({
          visible: this.showMemberSheet,
          members: this.members,
          selectedId: this.selectedMemberId,
          onSelect: (memberId: string) => {
            this.selectMember(memberId);
          },
          onManage: () => {
            this.openMemberManage();
          },
          onClose: () => {
            this.showMemberSheet = false;
          }
        })

        UnlockSheet({
          visible: this.showUnlock,
          bookId: this.unlockBookId,
          bookName: this.unlockBookName,
          onUnlocked: (bookId: string) => {
            this.showUnlock = false;
            this.selectedBookId = bookId;
            this.updateLabels();
            this.dirty = true;
          },
          onClose: () => {
            this.showUnlock = false;
          }
        })
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .mode(NavDestinationMode.DIALOG)
    .systemTransition(NavigationSystemTransitionType.SLIDE_BOTTOM)
    .backgroundColor($r('app.color.bg'))
    .onBackPressed(() => {
      if (this.hasInput()) {
        this.confirmDiscard();
        return true;
      }
      return false;
    })
    .onReady((context: NavDestinationContext) => {
      this.stack = context.pathStack;
      if (context.pathInfo.param instanceof AddTxnParam) {
        this.param = context.pathInfo.param;
      }
    })
  }
}
