import { AppFont, Radius, Space } from '../../theme/Theme';
import { Operator } from '../../utils/CalcTypes';

class CalcKey {
  label: string = '';
  value: string = '';
  op: Operator = Operator.PLUS;
  isOperator: boolean = false;
}

@ComponentV2
export struct CalcKeypad {
  @Event onDigit: (digit: string) => void = (digit: string) => {
  };
  @Event onOperator: (operator: Operator) => void = (operator: Operator) => {
  };
  @Event onBackspace: () => void = () => {
  };
  @Event onClear: () => void = () => {
  };

  private digits(): CalcKey[] {
    const keys: CalcKey[] = [];
    const labels: string[] = ['7', '8', '9', '4', '5', '6', '1', '2', '3', '.', '0', '00'];
    for (const label of labels) {
      const key: CalcKey = new CalcKey();
      key.label = label;
      key.value = label;
      keys.push(key);
    }
    return keys;
  }

  private operators(): CalcKey[] {
    const keys: CalcKey[] = [];
    const labels: string[] = ['+', '−', '×', '÷'];
    const values: Operator[] = [Operator.PLUS, Operator.MINUS, Operator.MULTIPLY, Operator.DIVIDE];
    for (let i = 0; i < labels.length; i++) {
      const key: CalcKey = new CalcKey();
      key.label = labels[i];
      key.op = values[i];
      key.isOperator = true;
      keys.push(key);
    }
    return keys;
  }

  @Builder
  digitKey(key: CalcKey) {
    Text(key.label)
      .fontSize(AppFont.subTitle)
      .fontWeight(AppFont.semibold)
      .fontColor($r('app.color.ink'))
      .textAlign(TextAlign.Center)
      .width('100%')
      .height('100%')
      .borderRadius(11)
      .backgroundColor($r('app.color.surface'))
      .border({ width: 1, color: $r('app.color.line') })
      .onClick(() => {
        this.onDigit(key.value);
      })
  }

  @Builder
  operatorKey(key: CalcKey) {
    Text(key.label)
      .fontSize(AppFont.subTitle)
      .fontWeight(AppFont.semibold)
      .fontColor($r('app.color.brand_ink'))
      .textAlign(TextAlign.Center)
      .width('100%')
      .height('100%')
      .borderRadius(11)
      .backgroundColor($r('app.color.brand_wash'))
      .onClick(() => {
        this.onOperator(key.op);
      })
  }

  @Builder
  backspaceKey() {
    Stack() {
      Image($r('app.media.ic_back'))
        .width(17)
        .height(17)
        .fillColor($r('app.color.ink_2'))
    }
    .width('100%')
    .height('100%')
    .borderRadius(11)
    .backgroundColor($r('app.color.surface_2'))
    .onClick(() => {
      this.onBackspace();
    })
    .gesture(LongPressGesture({ repeat: false, duration: 500 }).onAction(() => {
      this.onClear();
    }))
  }

  build() {
    Row({ space: 6 }) {
      Column({ space: 6 }) {
        ForEach(this.operators(), (key: CalcKey) => {
          Column() {
            this.operatorKey(key)
          }
          .layoutWeight(1)
          .width('100%')
        }, (key: CalcKey) => key.label)
        Column() {
          this.backspaceKey()
        }
        .layoutWeight(1)
        .width('100%')
      }
      .width(88)
      .height('100%')

      Grid() {
        ForEach(this.digits(), (key: CalcKey) => {
          GridItem() {
            this.digitKey(key)
          }
        }, (key: CalcKey) => key.label)
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(6)
      .rowsGap(6)
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height(186)
    .padding({ left: Space.page, right: Space.page, top: 6, bottom: 6 })
  }
}
