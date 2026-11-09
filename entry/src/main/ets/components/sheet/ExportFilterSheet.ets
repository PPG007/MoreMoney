import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { Book, Member, TxnFilter } from '../../models/Entities';
import { DateUtil, DateRange } from '../../utils/DateUtil';
import { PeriodResolver } from '../../service/PeriodResolver';
import { PeriodRange, PeriodType } from '../../models/StatsTypes';
import { CsvExportService } from '../../service/CsvExportService';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { PrimaryButton } from '../../components/base/PrimaryButton';
import { ErrorUtil } from '../../utils/ErrorUtil';

@ComponentV2
struct FilterChip {
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
      .onClick(() => {
        this.onTap();
      })
  }
}

@ComponentV2
export struct ExportFilterSheet {
  @Param visible: boolean = false;
  @Param books: Book[] = [];
  @Param members: Member[] = [];
  @Param lockedIds: string[] = [];
  @Event onExport: (bookIds: string[], memberIds: string[], startMs: number, endMs: number) => void =
    (bookIds: string[], memberIds: string[], startMs: number, endMs: number) => {
    };
  @Event onClose: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local rangeIndex: number = 0;
  @Local selectedBookIds: string[] = [];
  @Local selectedMemberIds: string[] = [];
  @Local customStart: string = '';
  @Local customEnd: string = '';
  @Local estimate: number = 0;
  @Local errorText: string = '';

  @Monitor('visible')
  onVisibleChanged(): void {
    if (this.visible) {
      this.rangeIndex = 0;
      this.selectedBookIds = [];
      this.selectedMemberIds = [];
      this.customStart = DateUtil.dayKey(new Date());
      this.customEnd = DateUtil.dayKey(new Date());
      this.errorText = '';
      this.refreshCount();
    }
  }

  private visibleBooks(): Book[] {
    return this.books.filter((book: Book): boolean => !book.archived && this.lockedIds.indexOf(book.id) < 0);
  }

  private range(): DateRange {
    if (this.rangeIndex === 0) {
      return DateUtil.rangeOfMonth(DateUtil.monthKey(new Date()));
    }
    if (this.rangeIndex === 1) {
      const period: PeriodRange = PeriodResolver.resolve(PeriodType.YEAR, new Date(), 1);
      const range: DateRange = new DateRange();
      range.startMs = period.startMs;
      range.endMs = period.endMs;
      return range;
    }
    if (this.rangeIndex === 2) {
      const range: DateRange = new DateRange();
      range.startMs = 0;
      range.endMs = Date.now();
      return range;
    }
    const range: DateRange = new DateRange();
    try {
      const custom: PeriodRange = PeriodResolver.custom(this.customStart, this.customEnd);
      range.startMs = custom.startMs;
      range.endMs = custom.endMs;
    } catch (error) {
      range.startMs = 0;
      range.endMs = Date.now();
    }
    return range;
  }

  private buildFilter(): TxnFilter {
    const range: DateRange = this.range();
    const filter: TxnFilter = new TxnFilter();
    filter.bookIds = this.selectedBookIds;
    filter.memberIds = this.selectedMemberIds;
    filter.startMs = range.startMs;
    filter.endMs = range.endMs;
    return filter;
  }

  private refreshCount(): void {
    CsvExportService.estimate(this.buildFilter(), this.lockedIds).then((count: number) => {
      this.estimate = count;
    }).catch(() => {
      this.estimate = 0;
    });
  }

  private pickStart(): void {
    const parts: string[] = this.customStart.split('-');
    this.getUIContext().showDatePickerDialog({
      start: new Date(2000, 0, 1),
      end: new Date(),
      selected: new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2])),
      onDateAccept: (value: Date) => {
        this.customStart = DateUtil.dayKey(value);
        this.rangeIndex = 3;
        this.refreshCount();
      }
    });
  }

  private pickEnd(): void {
    const parts: string[] = this.customEnd.split('-');
    this.getUIContext().showDatePickerDialog({
      start: new Date(2000, 0, 1),
      end: new Date(),
      selected: new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2])),
      onDateAccept: (value: Date) => {
        this.customEnd = DateUtil.dayKey(value);
        this.rangeIndex = 3;
        this.refreshCount();
      }
    });
  }

  private toggleBook(bookId: string): void {
    this.selectedBookIds = this.toggled(this.selectedBookIds, bookId);
    this.refreshCount();
  }

  private toggleMember(memberId: string): void {
    this.selectedMemberIds = this.toggled(this.selectedMemberIds, memberId);
    this.refreshCount();
  }

  private toggled(list: string[], id: string): string[] {
    if (list.indexOf(id) >= 0) {
      return list.filter((item: string): boolean => item !== id);
    }
    const next: string[] = [];
    for (const item of list) {
      next.push(item);
    }
    next.push(id);
    return next;
  }

  private selected(list: string[], id: string): boolean {
    return list.length === 0 || list.indexOf(id) >= 0;
  }

  private submit(): void {
    this.errorText = '';
    if (this.rangeIndex === 3) {
      if (this.customStart > this.customEnd) {
        this.errorText = '开始日期不能晚于结束日期';
        return;
      }
    }
    const range: DateRange = this.range();
    this.onExport(this.selectedBookIds, this.selectedMemberIds, range.startMs, range.endMs);
  }

  build() {
    if (this.visible) {
      Stack({ alignContent: Alignment.Bottom }) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.scrim'))
          .onClick(() => {
            this.onClose();
          })

        Scroll() {
          Column({ space: Space.x4 }) {
            Row() {
              Text('导出 CSV')
                .fontSize(AppFont.subTitle)
                .fontWeight(AppFont.bold)
                .fontColor($r('app.color.ink'))
                .layoutWeight(1)
              Text('取消')
                .fontSize(AppFont.settings)
                .fontColor($r('app.color.ink_3'))
                .onClick(() => {
                  this.onClose();
                })
            }
            .width('100%')

            Column({ space: 8 }) {
              Text('日期范围')
                .fontSize(AppFont.micro)
                .fontColor($r('app.color.ink_3'))
                .width('100%')
              Row({ space: 8 }) {
                FilterChip({
                  label: '本月',
                  selected: this.rangeIndex === 0,
                  onTap: () => {
                    this.rangeIndex = 0;
                    this.refreshCount();
                  }
                })
                FilterChip({
                  label: '本年',
                  selected: this.rangeIndex === 1,
                  onTap: () => {
                    this.rangeIndex = 1;
                    this.refreshCount();
                  }
                })
                FilterChip({
                  label: '全部',
                  selected: this.rangeIndex === 2,
                  onTap: () => {
                    this.rangeIndex = 2;
                    this.refreshCount();
                  }
                })
                FilterChip({
                  label: '自定义',
                  selected: this.rangeIndex === 3,
                  onTap: () => {
                    this.rangeIndex = 3;
                    this.refreshCount();
                  }
                })
              }
              if (this.rangeIndex === 3) {
                Row({ space: 8 }) {
                  Text('开始 '.concat(this.customStart))
                    .fontSize(AppFont.caption)
                    .fontColor($r('app.color.ink'))
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .borderRadius(Radius.input)
                    .backgroundColor($r('app.color.surface_2'))
                    .onClick(() => {
                      this.pickStart();
                    })
                  Text('结束 '.concat(this.customEnd))
                    .fontSize(AppFont.caption)
                    .fontColor($r('app.color.ink'))
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .borderRadius(Radius.input)
                    .backgroundColor($r('app.color.surface_2'))
                    .onClick(() => {
                      this.pickEnd();
                    })
                }
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

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
                    this.refreshCount();
                  })
              }
              .width('100%')
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.visibleBooks(), (book: Book) => {
                  Row() {
                    FilterChip({
                      label: book.name,
                      selected: this.selected(this.selectedBookIds, book.id),
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
                    this.refreshCount();
                  })
              }
              .width('100%')
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.members, (member: Member) => {
                  Row() {
                    FilterChip({
                      label: member.name,
                      selected: this.selected(this.selectedMemberIds, member.id),
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

            if (this.errorText.length > 0) {
              Text(this.errorText)
                .fontSize(AppFont.micro)
                .fontColor($r('app.color.expense'))
                .width('100%')
            }

            Text('预计导出 '.concat(this.estimate.toString()).concat(' 笔'))
              .fontSize(AppFont.caption)
              .fontColor($r('app.color.ink_3'))
              .width('100%')

            PrimaryButton({
              label: '导出',
              isEnabled: this.estimate > 0,
              onTap: () => {
                this.submit();
              }
            })
          }
          .width('100%')
          .padding({ left: Space.x7, right: Space.x7, top: 22, bottom: Space.x8 + 10 })
        }
        .constraintSize({ maxHeight: '86%' })
        .borderRadius({ topLeft: Radius.sheet, topRight: Radius.sheet })
        .backgroundColor($r('app.color.surface'))
        .shadow(Shadow.sheet(this.ui.isDark))
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
    }
  }
}
