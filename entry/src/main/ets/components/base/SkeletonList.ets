import { Radius, Space } from '../../theme/Theme';

@ComponentV2
export struct SkeletonList {
  @Param rows: number = 3;
  @Param topSpacing: number = 0;

  private indices(): number[] {
    const list: number[] = [];
    for (let i = 0; i < this.rows; i++) {
      list.push(i);
    }
    return list;
  }

  build() {
    Column({ space: Space.x3 }) {
      ForEach(this.indices(), (item: number) => {
        Row({ space: 11 }) {
          Row()
            .width(42)
            .height(42)
            .borderRadius(Radius.icon)
            .backgroundColor($r('app.color.surface_2'))
          Column({ space: 6 }) {
            Row()
              .width('55%')
              .height(10)
              .borderRadius(4)
              .backgroundColor($r('app.color.surface_2'))
            Row()
              .width('35%')
              .height(8)
              .borderRadius(4)
              .backgroundColor($r('app.color.surface_2'))
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 13, right: 13, top: 11, bottom: 11 })
        .borderRadius(Radius.card)
        .backgroundColor($r('app.color.surface'))
      }, (item: number) => item.toString())
    }
    .width('100%')
    .margin({ top: this.topSpacing })
  }
}
