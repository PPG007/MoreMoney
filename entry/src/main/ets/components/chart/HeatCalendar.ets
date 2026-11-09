import { AppFont, Radius, Space } from '../../theme/Theme';
import { CanvasColors, withAlpha } from '../../theme/Palette';
import { DaySum } from '../../models/StatsTypes';
import { DateUtil } from '../../utils/DateUtil';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

export class CalendarCell {
  day: number = 0;
  dayKey: string = '';
  cents: number = 0;
  level: number = 0;
}

const WEEK_LABELS: string[] = ['一', '二', '三', '四', '五', '六', '日'];

@ComponentV2
export struct HeatCalendar {
  @Param monthKey: string = '';
  @Param weekStart: number = 1;
  @Param daySums: DaySum[] = [];
  @Param selectedDayKey: string = '';
  @Param hidden: boolean = false;
  @Event onSelect: (dayKey: string) => void = (dayKey: string) => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();

  private maxCents(): number {
    let max: number = 0;
    for (const item of this.daySums) {
      if (item.cents > max) {
        max = item.cents;
      }
    }
    return max;
  }

  private rows(): CalendarCell[][] {
    const parts: string[] = this.monthKey.split('-');
    const year: number = Number(parts[0]);
    const month: number = Number(parts[1]);
    const first: Date = new Date(year, month - 1, 1, 0, 0, 0, 0);
    const target: number = this.weekStart % 7;
    const offset: number = (first.getDay() - target + 7) % 7;
    const totalDays: number = DateUtil.daysInMonth(year, month);
    const lookup: Record<string, number> = {};
    for (const item of this.daySums) {
      lookup[item.dayKey] = item.cents;
    }
    const max: number = this.maxCents();
    const cells: CalendarCell[] = [];
    for (let i = 0; i < 42; i++) {
      const cell: CalendarCell = new CalendarCell();
      const day: number = i - offset + 1;
      if (day >= 1 && day <= totalDays) {
        cell.day = day;
        cell.dayKey = DateUtil.dayKey(new Date(year, month - 1, day, 0, 0, 0, 0));
        const value: number | undefined = lookup[cell.dayKey];
        cell.cents = value === undefined ? 0 : value;
        if (max > 0 && cell.cents > 0) {
          const ratio: number = cell.cents / max;
          if (ratio <= 0.25) {
            cell.level = 1;
          } else if (ratio <= 0.5) {
            cell.level = 2;
          } else if (ratio <= 0.75) {
            cell.level = 3;
          } else {
            cell.level = 4;
          }
        }
      }
      cells.push(cell);
    }
    const result: CalendarCell[][] = [];
    for (let r = 0; r < 6; r++) {
      const row: CalendarCell[] = [];
      for (let c = 0; c < 7; c++) {
        row.push(cells[r * 7 + c]);
      }
      result.push(row);
    }
    return result;
  }

  private weekLabels(): string[] {
    const labels: string[] = [];
    for (let i = 0; i < 7; i++) {
      labels.push(WEEK_LABELS[(this.weekStart - 1 + i) % 7]);
    }
    return labels;
  }

  private heatColor(level: number): ResourceColor {
    if (this.hidden || level === 0) {
      return Color.Transparent;
    }
    const brand: string = CanvasColors.brand(this.ui.isDark);
    const alpha: number = level === 1 ? 0.07 : (level === 2 ? 0.13 : (level === 3 ? 0.20 : 0.28));
    return withAlpha(brand, alpha);
  }

  private amountText(cents: number): string {
    const yuan: number = Math.round(cents / 100);
    if (yuan >= 10000) {
      return '¥'.concat((yuan / 10000).toFixed(1)).concat('k');
    }
    return '¥'.concat(yuan.toString());
  }

  build() {
    Column({ space: 4 }) {
      Row() {
        ForEach(this.weekLabels(), (label: string) => {
          Text(label)
            .fontSize(AppFont.caption)
            .fontColor($r('app.color.ink_3'))
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
        }, (label: string) => label)
      }
      .width('100%')
      .padding({ bottom: 2 })

      ForEach(this.rows(), (row: CalendarCell[], rowIndex: number) => {
        Row() {
          ForEach(row, (cell: CalendarCell, colIndex: number) => {
            Stack() {
              if (cell.day > 0) {
                Column({ space: 1 }) {
                  Text(cell.day.toString())
                    .fontSize(AppFont.caption)
                    .fontWeight(cell.dayKey === DateUtil.dayKey(new Date()) ? AppFont.bold : AppFont.medium)
                    .fontColor(cell.dayKey === DateUtil.dayKey(new Date())
                      ? $r('app.color.brand_ink')
                      : $r('app.color.ink'))
                  if (!this.hidden && cell.cents > 0) {
                    Text(this.amountText(cell.cents))
                      .fontSize(7)
                      .fontColor($r('app.color.ink_3'))
                      .maxLines(1)
                  }
                }
                .width('100%')
                .height('100%')
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .borderRadius(10)
                .backgroundColor(this.heatColor(cell.level))
                .border({
                  width: this.selectedDayKey === cell.dayKey ? 1 : 0,
                  color: $r('app.color.brand_ink')
                })
              }
            }
            .layoutWeight(1)
            .aspectRatio(1)
            .padding(2)
            .onClick(() => {
              if (cell.day > 0) {
                this.onSelect(cell.dayKey);
              }
            })
          }, (cell: CalendarCell, colIndex: number) => rowIndex.toString().concat('-').concat(colIndex.toString()))
        }
        .width('100%')
      }, (row: CalendarCell[], rowIndex: number) => rowIndex.toString())
    }
    .width('100%')
    .padding({ left: Space.x2, right: Space.x2, top: Space.x2, bottom: Space.x2 })
    .borderRadius(Radius.cardLg)
  }
}
