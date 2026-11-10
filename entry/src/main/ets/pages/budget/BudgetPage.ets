import { AppFont, Radius, Space } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { BookBudgetState, BudgetBookView, BudgetOverview, BudgetService } from '../../service/BudgetService';
import { BudgetPeriod, BudgetPeriodType } from '../../service/BudgetPeriod';
import { BudgetSummary } from './BudgetSummary';
import { MainBudgetCard } from './MainBudgetCard';
import { UnsetBudgetCard } from './UnsetBudgetCard';
import { BudgetBookRow } from './BudgetBookRow';
import { BudgetEditDialog } from './BudgetEditDialog';
import { EmptyState } from '../../components/base/EmptyState';
import { ErrorRetry } from '../../components/base/ErrorRetry';
import { EyeButton } from '../../components/base/EyeButton';
import { ErrorUtil } from '../../utils/ErrorUtil';
import { SnackBarService } from '../../service/SnackBarService';
import { SnackBarOptions } from '../../service/SnackBarService';

class BudgetSectionView {
  type: BudgetPeriodType = BudgetPeriodType.MONTH;
  title: string = '';
  overview: BudgetOverview = new BudgetOverview();
}

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
  @Local sections: BudgetSectionView[] = [];
  @Local unset: BudgetBookView[] = [];
  @Local loading: boolean = true;
  @Local errorText: string = '';
  @Local showDialog: boolean = false;
  @Local dialogBookId: string = '';
  @Local dialogBookName: string = '';
  @Local dialogInitialType: BudgetPeriodType = BudgetPeriodType.MONTH;
  @Local dialogState: BookBudgetState = new BookBudgetState();

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

  private static titleOf(type: BudgetPeriodType): string {
    if (type === BudgetPeriodType.WEEK) {
      return '周预算';
    }
    return type === BudgetPeriodType.YEAR ? '年预算' : '月预算';
  }

  private async reload(): Promise<void> {
    try {
      this.errorText = '';
      const types: BudgetPeriodType[] = [BudgetPeriodType.WEEK, BudgetPeriodType.MONTH, BudgetPeriodType.YEAR];
      const sections: BudgetSectionView[] = [];
      for (const type of types) {
        const section: BudgetSectionView = new BudgetSectionView();
        section.type = type;
        section.title = BudgetPage.titleOf(type);
        section.overview = await BudgetService.getOverview(type);
        sections.push(section);
      }
      this.sections = sections;
      this.unset = await BudgetService.getUnsetBooks();
    } catch (error) {
      this.errorText = ErrorUtil.messageOf(error);
    } finally {
      this.loading = false;
    }
  }

  private visibleSections(): BudgetSectionView[] {
    return this.sections.filter((section: BudgetSectionView): boolean =>
      section.overview.totalCents > 0 && section.overview.mainBook !== null);
  }

  private emptyOverview(): boolean {
    return this.visibleSections().length === 0;
  }

  private defaultTarget(): BudgetBookView | null {
    if (this.unset.length > 0) {
      return this.unset[0];
    }
    return null;
  }

  private unsetOf(bookId: string): BudgetBookView | null {
    const found: BudgetBookView | undefined = this.unset.find(
      (view: BudgetBookView): boolean => view.bookId === bookId
    );
    return found === undefined ? null : found;
  }

  private async openEditBook(view: BudgetBookView, type: BudgetPeriodType): Promise<void> {
    try {
      this.dialogState = await BudgetService.getBookState(view.bookId);
      this.dialogBookId = view.bookId;
      this.dialogBookName = view.name;
      this.dialogInitialType = type;
      this.showDialog = true;
    } catch (error) {
      SnackBarService.show(BudgetPage.toast('读取预算失败：'.concat(ErrorUtil.messageOf(error))));
    }
  }

  private async saveBudget(type: BudgetPeriodType, cents: number): Promise<void> {
    try {
      await BudgetService.setBudget(this.dialogBookId, type, cents);
      this.showDialog = false;
      await this.reload();
      SnackBarService.show(BudgetPage.toast(
        cents > 0 ? '预算已保存' : '已取消'.concat(BudgetPeriod.noun(type)).concat('预算')
      ));
    } catch (error) {
      SnackBarService.show(BudgetPage.toast('保存失败：'.concat(ErrorUtil.messageOf(error))));
    }
  }

  private static toast(message: string): SnackBarOptions {
    const options: SnackBarOptions = new SnackBarOptions();
    options.message = message;
    return options;
  }

  private static rowKey(section: BudgetSectionView, view: BudgetBookView): string {
    return section.type.concat('#')
      .concat(view.bookId)
      .concat('#')
      .concat(view.budgetCents.toString())
      .concat('#')
      .concat(view.spentCents.toString())
      .concat('#')
      .concat(view.name);
  }

  @Builder
  header() {
    Row() {
      Text('预算')
        .fontSize(AppFont.pageTitle)
        .fontWeight(AppFont.bold)
        .fontColor($r('app.color.ink'))
        .layoutWeight(1)
      EyeButton()
    }
    .width('100%')
    .padding({ left: Space.page, right: Space.page, top: this.ui.topInset + 10 })
  }

  @Builder
  section(section: BudgetSectionView) {
    Column({ space: Space.x2 }) {
      Row({ space: Space.x2 }) {
        Text(section.title)
          .fontSize(AppFont.settings)
          .fontWeight(AppFont.bold)
          .fontColor($r('app.color.ink'))
        Text(BudgetPeriod.noun(section.type))
          .fontSize(AppFont.caption)
          .fontColor($r('app.color.ink_3'))
      }
      .width('100%')

      BudgetSummary({
        totalCents: section.overview.totalCents,
        spentCents: section.overview.spentCents,
        remainingCents: section.overview.remainingCents
      })

      if (section.overview.mainBook !== null) {
        MainBudgetCard({
          view: section.overview.mainBook,
          perDayCents: section.overview.perDayCents,
          onTap: () => {
            const main: BudgetBookView | null = section.overview.mainBook;
            if (main !== null) {
              this.openEditBook(main, section.type);
            }
          }
        })
      }

      ForEach(section.overview.others, (view: BudgetBookView) => {
        BudgetBookRow({
          view: view,
          onTap: (bookId: string) => {
            this.openEditBook(view, section.type);
          }
        })
      }, (view: BudgetBookView) => BudgetPage.rowKey(section, view))
    }
    .width('100%')
    .padding({ top: Space.x3 })
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

            if (this.emptyOverview()) {
              Column() {
                EmptyState({
                  icon: $r('app.media.ic_tab_budget'),
                  title: '还没有预算',
                  description: '为账本设置周、月或年预算',
                  actionLabel: '设置预算',
                  onAction: () => {
                    const target: BudgetBookView | null = this.defaultTarget();
                    if (target !== null) {
                      this.openEditBook(target, BudgetPeriodType.MONTH);
                    }
                  }
                })
              }
              .width('100%')
              .borderRadius(Radius.cardLg)
              .backgroundColor($r('app.color.surface'))
              .border({ width: 1, color: $r('app.color.line') })
            } else {
              ForEach(this.visibleSections(), (section: BudgetSectionView) => {
                this.section(section)
              }, (section: BudgetSectionView) => BudgetPeriod.indexOf(section.type).toString())
            }

            if (this.unset.length > 0) {
              Column({ space: Space.x2 }) {
                PageSectionTitle({ title: '待设置预算', count: this.unset.length })
                ForEach(this.unset, (view: BudgetBookView) => {
                  UnsetBudgetCard({
                    view: view,
                    onSet: (bookId: string) => {
                      const target: BudgetBookView | null = this.unsetOf(bookId);
                      if (target !== null) {
                        this.openEditBook(target, BudgetPeriodType.MONTH);
                      }
                    }
                  })
                }, (view: BudgetBookView) => view.bookId.concat('#').concat(view.name))
              }
              .width('100%')
              .padding({ top: Space.x3 })
            }

            Text('预算跟随账本，设置后长期生效；周、月、年预算分别统计本周、本月、本年支出。')
              .fontSize(AppFont.caption)
              .fontColor($r('app.color.ink_3'))
              .width('100%')
              .padding({ top: Space.x4, bottom: Space.x8 })
          }
          .width('100%')
          .padding({ left: Space.page, right: Space.page, top: Space.x3 })
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
        state: this.dialogState,
        initialType: this.dialogInitialType,
        onSave: (type: BudgetPeriodType, cents: number) => {
          this.saveBudget(type, cents);
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
