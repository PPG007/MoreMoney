import { AppFont, Radius } from '../../theme/Theme';

@ComponentV2
export struct DataStatsCard {
  @Param books: number = 0;
  @Param txns: number = 0;
  @Param sizeText: string = '—';

  build() {
    Row() {
      Text((this.books.toString()).concat(' 个账本').concat(' · ').concat(this.txns.toString()).concat(' 笔')
        .concat(' · ').concat(this.sizeText))
        .fontSize(AppFont.settings)
        .fontColor($r('app.color.ink'))
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 13, right: 13, top: 14, bottom: 14 })
    .borderRadius(Radius.card)
    .backgroundColor($r('app.color.surface'))
    .border({ width: 1, color: $r('app.color.line') })
  }
}
