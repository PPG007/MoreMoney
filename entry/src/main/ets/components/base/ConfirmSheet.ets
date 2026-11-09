import { AppFont, Radius, Shadow, Space } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
export struct ConfirmSheet {
  @Param visible: boolean = false;
  @Param title: string = '';
  @Param message: string = '';
  @Param confirmLabel: string = '确认';
  @Param danger: boolean = false;
  @Event onConfirm: () => void = () => {
  };
  @Event onCancel: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();

  build() {
    if (this.visible) {
      Stack({ alignContent: Alignment.Bottom }) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.scrim'))
          .onClick(() => {
            this.onCancel();
          })

        Column({ space: Space.x3 }) {
          Text(this.title)
            .fontSize(AppFont.subTitle)
            .fontWeight(AppFont.bold)
            .fontColor($r('app.color.ink'))
            .width('100%')
          if (this.message.length > 0) {
            Text(this.message)
              .fontSize(AppFont.caption)
              .fontColor($r('app.color.ink_3'))
              .width('100%')
          }

          Row() {
            Text(this.confirmLabel)
              .fontSize(AppFont.body)
              .fontWeight(AppFont.semibold)
              .fontColor(this.danger ? $r('app.color.expense') : $r('app.color.brand_ink'))
          }
          .width('100%')
          .height(50)
          .justifyContent(FlexAlign.Center)
          .borderRadius(Radius.input)
          .backgroundColor(this.danger ? $r('app.color.surface_2') : $r('app.color.brand_wash'))
          .onClick(() => {
            this.onConfirm();
          })

          Row() {
            Text('取消')
              .fontSize(AppFont.body)
              .fontWeight(AppFont.medium)
              .fontColor($r('app.color.ink_2'))
          }
          .width('100%')
          .height(50)
          .justifyContent(FlexAlign.Center)
          .borderRadius(Radius.input)
          .backgroundColor($r('app.color.surface_2'))
          .onClick(() => {
            this.onCancel();
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
