import { AppFont } from '../../theme/Theme';
import { Shadow } from '../../theme/Theme';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

@ComponentV2
export struct NoteEditor {
  @Param note: string = '';
  @Event onNoteChange: (note: string) => void = (note: string) => {
  };
  @Event onDone: () => void = () => {
  };
  @Local ui: GlobalUiStore = UiStore.instance();

  build() {
    Column({ space: 4 }) {
      Row() {
        Text('备注')
          .fontSize(AppFont.micro)
          .fontColor($r('app.color.ink_3'))
          .layoutWeight(1)
        Text(this.note.length.toString().concat('/100'))
          .fontSize(AppFont.micro)
          .fontColor($r('app.color.ink_3'))
        Text('完成')
          .fontSize(AppFont.micro)
          .fontWeight(AppFont.semibold)
          .fontColor($r('app.color.brand_ink'))
          .padding({ left: 10, right: 2, top: 2, bottom: 2 })
          .onClick(() => {
            this.onDone();
          })
      }
      .width('100%')

      TextArea({ text: this.note, placeholder: '记点什么…' })
        .width('100%')
        .height(62)
        .fontSize(AppFont.caption)
        .fontWeight(AppFont.medium)
        .fontColor($r('app.color.ink'))
        .placeholderColor($r('app.color.ink_3'))
        .backgroundColor($r('app.color.surface_2'))
        .borderRadius(9)
        .padding({ left: 9, right: 9, top: 7, bottom: 7 })
        .maxLength(100)
        .onChange((value: string) => {
          this.onNoteChange(value);
        })
    }
    .width('100%')
    .height(108)
    .padding(10)
    .borderRadius(13)
    .backgroundColor($r('app.color.surface'))
    .shadow(Shadow.card(this.ui.isDark))
  }
}
