import { Radius } from '../../theme/Theme';

export enum AmountTone {
  Brand,
  Expense,
  Good
}

@ComponentV2
export struct AmountBar {
  @Param percent: number = 0;
  @Param barHeight: number = 5;
  @Param tone: AmountTone = AmountTone.Brand;

  private ratio(): number {
    if (this.percent < 0) {
      return 0;
    }
    return this.percent > 1 ? 1 : this.percent;
  }

  private fillColor(): ResourceColor {
    if (this.tone === AmountTone.Expense) {
      return $r('app.color.expense');
    }
    if (this.tone === AmountTone.Good) {
      return $r('app.color.good');
    }
    return $r('app.color.brand');
  }

  build() {
    Stack({ alignContent: Alignment.Start }) {
      Row()
        .width('100%')
        .height(this.barHeight)
        .borderRadius(Radius.pill)
        .backgroundColor($r('app.color.surface_2'))
      Row()
        .width((this.ratio() * 100).toString() + '%')
        .height(this.barHeight)
        .borderRadius(Radius.pill)
        .backgroundColor(this.fillColor())
    }
    .width('100%')
    .height(this.barHeight)
  }
}
