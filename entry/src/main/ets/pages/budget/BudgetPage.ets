import { AppFont, Radius, Space } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { BudgetBookView, BudgetOverview, BudgetService } from '../../service/BudgetService';
import { BudgetSummary } from './BudgetSummary';
import { MainBudgetCard } from './MainBudgetCard';
import { UnsetBudgetCard } from './UnsetBudgetCard';
import { BudgetBookRow } from './BudgetBookRow';
import { BudgetEditDialog } from './BudgetEditDialog';
import { EmptyState } from '../../components/base/EmptyState';
import { ErrorRetry } from '../../components/base/ErrorRetry';
import { EyeButton } from '../../components/base/EyeButton';
import { DateUtil } from '../../utils/DateUtil';
import { ErrorUtil } from '../../utils/ErrorUtil';
import { SnackBarService } from '../../service/SnackBarService';
import { SnackBarOptions } from '../../service/SnackBarService';

@ComponentV2
struct PageSectionTitle {
  @Param title: string = '';
  @Param count: number = 0;

  build() {
    Row({ space: Space.x2 }) {
      Text(this.title)
        .fontSize(AppFont.settings)
        .fontWeight(AppFont.bold)
        .fontColor($r('app.color.ink'))
      if (this.count > 0) {
        Text(this.count.toString())
          .fontSize(AppFont.caption)
          .fontColor($r('app.color.ink_3'))
      }
    }
    .width('100%')
  }
}

@ComponentV2
export struct BudgetPage {
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local overview: BudgetOverview = new BudgetOverview();
  @Local monthKey: string = DateUtil.monthKey(new Date());
  @Local loading: boolean = true;
  @Local errorText: string = '';
  @Local showDialog: boolean = false;
  @Local dialogBookId: string = '';
  @Local dialogBookName: string = '';
  @Local dialogCurrent: number = 0;
  @Local dialogSpent: number = 0;

  aboutToAppear(): void {
    this.reload();
  }

  @Monitor('ui.unlockVersion')
  onUnlockChanged(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    try {
      this.errorText = '';
      this.overview = await BudgetService.getOverview(this.monthKey);
    } catch (error) {
      this.errorText = ErrorUtil.messageOf(error);
    } finally {
      this.loading = false;
    }
  }

  private changeMonth(delta: number): void {
    this.monthKey = DateUtil.addMonths(this.monthKey, delta);
    this.reload();
  }

  private defaultTarget(): BudgetBookView | null {
    if (this.overview.unset.length > 0) {
      return this.overview.unset[0];
    }
    return this.overview.mainBook;
  }

  private openEditBook(bookId: string): void {
    let target: BudgetBookView | null = null;
    if (this.overview.mainBook !== null && this.overview.mainBook.bookId === bookId) {
      target = this.overview.mainBook;
    }
    if (target === null) {
      const other: BudgetBookView | undefined = this.overview.others.find(
        (view: BudgetBookView): boolean => view.bookId === bookId
      );
      target = other === undefined ? null : other;
    }
    if (target === null) {
      const unset: BudgetBookView | undefined = this.overview.unset.find(
        (view: BudgetBookView): boolean => view.bookId === bookId
      );
      target = unset === undefined ? null : unset;
    }
    if (target === null) {
      return;
    }
    this.dialogBookId = target.bookId;
    this.dialogBookName = target.name;
    this.dialogCurrent = target.budgetCents;
    this.dialogSpent = target.spentCents;
    this.showDialog = true;
  }

  private async saveBudget(cents: number): Promise<void> {
    try {
      if (cents > 0) {
        await BudgetService.setBudget(this.dialogBookId, this.monthKey, cents);
      } else {
        await BudgetService.removeBudget(this.dialogBookId, this.monthKey);
      }
      this.showDialog = false;
      await this.reload();
      SnackBarService.show(BudgetPage.toast(cents > 0 ? '预算已保存' : '已取消本月预算'));
    } catch (error) {
      SnackBarService.show(BudgetPage.toast('保存失败：'.concat(ErrorUtil.messageOf(error))));
    }
  }

  private static toast(message: string): SnackBarOptions {
    const options: SnackBarOptions = new SnackBarOptions();
    options.message = message;
    return options;
  }

  private emptyOverview(): boolean {
    return this.overview.totalCents === 0 && this.overview.mainBook === null;
  }

  @Builder
  header() {
    Column({ space: Space.x3 }) {
      Row() {
        Text('预算')
          .fontSize(AppFont.pageTitle)
          .fontWeight(AppFont.bold)
          .fontColor($r('app.color.ink'))
          .layoutWeight(1)
        EyeButton()
      }
      .width('100%')

      Row({ space: Space.x4 }) {
        Stack() {
          Image($r('app.media.ic_chevron_left'))
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
          this.changeMonth(-1);
        })

        Text(DateUtil.formatMonthCn(this.monthKey))
          .fontSize(AppFont.month)
          .fontWeight(AppFont.bold)
          .fontColor($r('app.color.ink'))
          .fontFeature(AppFont.tnum)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Stack() {
          Image($r('app.media.ic_chevron_right'))
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
          this.changeMonth(1);
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: Space.page, right: Space.page, top: this.ui.topInset + 10 })
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
      this.header()

      Scroll() {
        Column({ space: Space.x3 }) {
          if (this.errorText.length > 0) {
            ErrorRetry({
              message: this.errorText,
              onRetry: () => {
                this.loading = true;
                this.reload();
              }
            })
          }

          BudgetSummary({
            totalCents: this.overview.totalCents,
            spentCents: this.overview.spentCents,
            remainingCents: this.overview.remainingCents
          })
          .margin({ top: Space.x2 })

          if (this.emptyOverview()) {
            Column() {
              EmptyState({
                icon: $r('app.media.ic_tab_budget'),
                title: '还没有预算',
                description: '先给一个账本设置月度预算',
                actionLabel: '设置预算',
                onAction: () => {
                  const target: BudgetBookView | null = this.defaultTarget();
                  if (target !== null) {
                    this.openEditBook(target.bookId);
                  }
                }
              })
            }
            .width('100%')
            .padding({ left: Space.page, right: Space.page })
            .borderRadius(Radius.cardLg)
            .backgroundColor($r('app.color.surface'))
            .border({ width: 1, color: $r('app.color.line') })
          } else {
            MainBudgetCard({
              view: this.overview.mainBook,
              perDayCents: this.overview.perDayCents
            })
            .margin({ left: Space.page, right: Space.page, top: Space.x1 })
          }

          if (this.overview.unset.length > 0) {
            Column({ space: Space.x2 }) {
              PageSectionTitle({ title: '待设置预算', count: this.overview.unset.length })
              ForEach(this.overview.unset, (view: BudgetBookView) => {
                UnsetBudgetCard({
                  view: view,
                  onSet: (bookId: string) => {
                    this.openEditBook(bookId);
                  }
                })
              }, (view: BudgetBookView) => view.bookId)
            }
            .width('100%')
            .padding({ left: Space.page, right: Space.page, top: Space.x3 })
          }

          if (this.overview.others.length > 0) {
            Column({ space: Space.x2 }) {
              PageSectionTitle({ title: '其他账本', count: 0 })
              ForEach(this.overview.others, (view: BudgetBookView) => {
                BudgetBookRow({
                  view: view,
                  onTap: (bookId: string) => {
                    this.openEditBook(bookId);
                  }
                })
              }, (view: BudgetBookView) => view.bookId)
            }
            .width('100%')
            .padding({ left: Space.page, right: Space.page, top: Space.x3 })
          }

          Text('预算只统计已设置预算且已解锁的账本；未设置预算的账本不计入合计。')
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.ink_3'))
            .width('100%')
            .padding({ left: Space.page, right: Space.page, top: Space.x4, bottom: Space.x8 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.bg'))

      BudgetEditDialog({
        visible: this.showDialog,
        bookName: this.dialogBookName,
        periodLabel: DateUtil.formatMonthCn(this.monthKey),
        currentCents: this.dialogCurrent,
        spentCents: this.dialogSpent,
        onSave: (cents: number) => {
          this.saveBudget(cents);
        },
        onClose: () => {
          this.showDialog = false;
        }
      })
    }
    .width('100%')
    .height('100%')
  }
}
