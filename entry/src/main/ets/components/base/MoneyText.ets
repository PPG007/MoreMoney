import { AppFont } from '../../theme/Theme';
import { formatCents, MoneyFormatOptions } from '../../utils/MoneyUtil';
import { GlobalUiStore } from '../../state/GlobalUiStore';
import { UiStore } from '../../state/UiStore';

export enum MoneyTone {
  Ink,
  Expense,
  Good,
  OnHero,
  Inherit
}

@ComponentV2
export struct MoneyText {
  @Param cents: number = 0;
  @Param fontSize: number = AppFont.body;
  @Param weight: number = AppFont.bold;
  @Param tone: MoneyTone = MoneyTone.Ink;
  @Param showSymbol: boolean = true;
  @Param signed: boolean = false;
  @Param locked: boolean = false;
  @Param forceVisible: boolean = false;
  @Local ui: GlobalUiStore = UiStore.instance();

  private visibleText(): string {
    const options: MoneyFormatOptions = new MoneyFormatOptions();
    options.symbol = this.showSymbol;
    const text: string = formatCents(this.cents, options);
    if (this.signed && this.cents > 0) {
      return '+'.concat(text);
    }
    return text;
  }

  private finalText(): string {
    if (this.locked || (this.ui.hideAmount && !this.forceVisible)) {
      return this.showSymbol ? '¥••••' : '••••';
    }
    return this.visibleText();
  }

  private colorOf(): ResourceColor {
    if (this.tone === MoneyTone.Expense) {
      return $r('app.color.expense');
    }
    if (this.tone === MoneyTone.Good) {
      return $r('app.color.good');
    }
    if (this.tone === MoneyTone.OnHero) {
      return $r('app.color.on_hero');
    }
    return $r('app.color.ink');
  }

  build() {
    if (this.tone === MoneyTone.Inherit) {
      Text(this.finalText())
        .fontSize(this.fontSize)
        .fontWeight(this.weight)
        .fontFeature(AppFont.tnum)
    } else {
      Text(this.finalText())
        .fontSize(this.fontSize)
        .fontWeight(this.weight)
        .fontColor(this.colorOf())
        .fontFeature(AppFont.tnum)
    }
  }
}
