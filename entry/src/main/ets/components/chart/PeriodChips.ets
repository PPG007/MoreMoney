import { AppFont, Radius } from '../../theme/Theme';
import { PeriodType } from '../../models/StatsTypes';

class PeriodOption {
  type: PeriodType = PeriodType.MONTH;
  label: string = '';
}

@ComponentV2
export struct PeriodChips {
  @Param selected: PeriodType = PeriodType.MONTH;
  @Param customLabel: string = '';
  @Event onSelect: (type: PeriodType) => void = (type: PeriodType) => {
  };

  private options(): PeriodOption[] {
    const types: PeriodType[] = [PeriodType.TODAY, PeriodType.WEEK, PeriodType.MONTH, PeriodType.YEAR,
      PeriodType.ALL, PeriodType.CUSTOM];
    const labels: string[] = ['今日', '本周', '本月', '本年', '全部', '自定义'];
    const list: PeriodOption[] = [];
    for (let i = 0; i < types.length; i++) {
      const option: PeriodOption = new PeriodOption();
      option.type = types[i];
      option.label = labels[i];
      list.push(option);
    }
    return list;
  }

  build() {
    Scroll() {
      Row({ space: 6 }) {
        ForEach(this.options(), (option: PeriodOption) => {
          Text(option.type === PeriodType.CUSTOM && this.customLabel.length > 0 ? this.customLabel : option.label)
            .fontSize(10)
            .fontWeight(this.selected === option.type ? AppFont.semibold : AppFont.regular)
            .fontColor(this.selected === option.type ? $r('app.color.btn_fg') : $r('app.color.ink_2'))
            .padding({ left: 11, right: 11, top: 6, bottom: 6 })
            .borderRadius(Radius.pill)
            .backgroundColor(this.selected === option.type ? $r('app.color.brand_ink') : $r('app.color.surface'))
            .border({
              width: 1,
              color: this.selected === option.type ? $r('app.color.brand_ink') : $r('app.color.line')
            })
            .onClick(() => {
              this.onSelect(option.type);
            })
        }, (option: PeriodOption) => option.type)
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }
}
