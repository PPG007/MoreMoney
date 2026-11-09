import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';
import { PrimaryButton } from '../../components/base/PrimaryButton';
import { PeriodRange } from '../../models/StatsTypes';
import { PeriodResolver } from '../../service/PeriodResolver';
import { DateUtil } from '../../utils/DateUtil';
import { ErrorUtil } from '../../utils/ErrorUtil';

@ComponentV2
export struct CustomRangeDialog {
  @Param visible: boolean = false;
  @Param defaultStart: string = '';
  @Param defaultEnd: string = '';
  @Event onConfirm: (range: PeriodRange) => void = (range: PeriodRange) => {
  };
  @Event onClose: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();
  @Local startKey: string = '';
  @Local endKey: string = '';
  @Local errorText: string = '';

  @Monitor('visible')
  onVisibleChanged(): void {
    if (this.visible) {
      this.startKey = this.defaultStart.length > 0 ? this.defaultStart : DateUtil.dayKey(new Date());
      this.endKey = this.defaultEnd.length > 0 ? this.defaultEnd : DateUtil.dayKey(new Date());
      this.errorText = '';
    }
  }

  private pickStart(): void {
    const parts: string[] = this.startKey.split('-');
    this.getUIContext().showDatePickerDialog({
      start: new Date(2000, 0, 1),
      end: new Date(),
      selected: new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2])),
      onDateAccept: (value: Date) => {
        this.startKey = DateUtil.dayKey(value);
        this.errorText = '';
      }
    });
  }

  private pickEnd(): void {
    const parts: string[] = this.endKey.split('-');
    this.getUIContext().showDatePickerDialog({
      start: new Date(2000, 0, 1),
      end: new Date(),
      selected: new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2])),
      onDateAccept: (value: Date) => {
        this.endKey = DateUtil.dayKey(value);
        this.errorText = '';
      }
    });
  }

  private confirm(): void {
    try {
      const range: PeriodRange = PeriodResolver.custom(this.startKey, this.endKey);
      this.onConfirm(range);
    } catch (error) {
      this.errorText = ErrorUtil.messageOf(error);
    }
  }

  @Builder
  dateRow(label: string, value: string, onTap: () => void) {
    Row() {
      Text(label)
        .fontSize(AppFont.caption)
        .fontColor($r('app.color.ink_3'))
      Blank()
      Text(PeriodResolver.shortDay(value.length === 0 ? DateUtil.dayKey(new Date()) : value))
        .fontSize(AppFont.settings)
        .fontWeight(AppFont.semibold)
        .fontColor($r('app.color.ink'))
      Image($r('app.media.ic_chevron_right'))
        .width(13)
        .height(13)
        .fillColor($r('app.color.ink_3'))
    }
    .width('100%')
    .height(48)
    .padding({ left: 13, right: 13 })
    .borderRadius(Radius.input)
    .backgroundColor($r('app.color.surface_2'))
    .onClick(() => {
      onTap();
    })
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

        Column({ space: Space.x3 }) {
          Row() {
            Text('自定义范围')
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

          this.dateRow('开始日期', this.startKey, () => {
            this.pickStart();
          })
          this.dateRow('结束日期', this.endKey, () => {
            this.pickEnd();
          })

          if (this.errorText.length > 0) {
            Text(this.errorText)
              .fontSize(AppFont.micro)
              .fontColor($r('app.color.expense'))
              .width('100%')
          }

          PrimaryButton({
            label: '确定',
            onTap: () => {
              this.confirm();
            }
          })
        }
        .width('100%')
        .padding({ left: Space.x7, right: Space.x7, top: 22, bottom: Space.x8 + 10 })
        .borderRadius({ topLeft: Radius.sheet, topRight: Radius.sheet })
        .backgroundColor($r('app.color.surface'))
        .shadow(Shadow.sheet(this.ui.isDark))
      }
      .width('100%')
      .height('100%')
    }
  }
}
