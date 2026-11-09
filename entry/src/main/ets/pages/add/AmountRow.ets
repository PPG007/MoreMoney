import { AppFont, Radius, Space } from '../../theme/Theme';

@ComponentV2
export struct AmountRow {
  @Param expression: string = '';
  @Param previewText: string = '';
  @Param previewValid: boolean = false;
  @Param note: string = '';
  @Param canSave: boolean = false;
  @Event onNoteTap: () => void = () => {
  };
  @Event onSave: () => void = () => {
  };

  private expressionText(): string {
    return this.expression.length === 0 ? '0' : this.expression;
  }

  private noteText(): string {
    if (this.note.length === 0) {
      return '备注';
    }
    if (this.note.length > 12) {
      return this.note.substring(0, 12).concat('…');
    }
    return this.note;
  }

  build() {
    Row({ space: 8 }) {
      Column({ space: 2 }) {
        Row({ space: 1 }) {
          Text('¥')
            .fontSize(AppFont.amountInput)
            .fontWeight(AppFont.bold)
            .fontColor($r('app.color.ink'))
          Text(this.expressionText())
            .fontSize(AppFont.amountInput)
            .fontWeight(AppFont.bold)
            .fontColor($r('app.color.ink'))
            .fontFeature(AppFont.tnum)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        Text(this.previewText)
          .fontSize(AppFont.caption)
          .fontColor(this.previewValid ? $r('app.color.ink_3') : $r('app.color.expense'))
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Row({ space: 4 }) {
        Image($r('app.media.ic_edit'))
          .width(13)
          .height(13)
          .fillColor($r('app.color.ink_3'))
        Text(this.noteText())
          .fontSize(AppFont.caption)
          .fontColor(this.note.length > 0 ? $r('app.color.ink') : $r('app.color.ink_3'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
      .height(38)
      .constraintSize({ minWidth: 72, maxWidth: 132 })
      .padding({ left: 9, right: 9 })
      .borderRadius(Radius.input)
      .backgroundColor($r('app.color.surface'))
      .border({ width: 1, color: this.note.length > 0 ? $r('app.color.brand_soft') : $r('app.color.line') })
      .onClick(() => {
        this.onNoteTap();
      })

      Row({ space: 3 }) {
        Image($r('app.media.ic_check'))
          .width(14)
          .height(14)
          .fillColor($r('app.color.btn_fg'))
        Text('保存')
          .fontSize(AppFont.settings)
          .fontWeight(AppFont.bold)
          .fontColor($r('app.color.btn_fg'))
      }
      .height(38)
      .padding({ left: 11, right: 11 })
      .borderRadius(11)
      .backgroundColor($r('app.color.btn_bg'))
      .opacity(this.canSave ? 1 : 0.4)
      .enabled(this.canSave)
      .onClick(() => {
        if (this.canSave) {
          this.onSave();
        }
      })
    }
    .width('100%')
    .padding({ left: Space.page, right: Space.page, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
  }
}
