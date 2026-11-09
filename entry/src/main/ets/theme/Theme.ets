export class AppFont {
  static readonly micro: number = 10;
  static readonly caption: number = 10;
  static readonly legend: number = 11;
  static readonly settings: number = 12;
  static readonly row: number = 13;
  static readonly body: number = 14;
  static readonly stat: number = 16;
  static readonly subTitle: number = 17;
  static readonly bookTitle: number = 19;
  static readonly donutCenter: number = 23;
  static readonly ringCenter: number = 24;
  static readonly pageTitle: number = 25;
  static readonly amountInput: number = 26;
  static readonly trendMain: number = 27;
  static readonly month: number = 32;
  static readonly heroAmount: number = 42;

  static readonly regular: number = 400;
  static readonly medium: number = 500;
  static readonly semibold: number = 600;
  static readonly bold: number = 700;

  static readonly tnum: string = '"tnum" 1';

  static tabular(text: string): string {
    return text;
  }

  static tabularFeature(): string {
    return AppFont.tnum;
  }
}

export class Space {
  static readonly x1: number = 4;
  static readonly x2: number = 6;
  static readonly x3: number = 8;
  static readonly x4: number = 10;
  static readonly x5: number = 12;
  static readonly x6: number = 16;
  static readonly x7: number = 20;
  static readonly x8: number = 24;
  static readonly x9: number = 32;
  static readonly page: number = 16;
}

export class Radius {
  static readonly hero: number = 30;
  static readonly cardLg: number = 24;
  static readonly card: number = 20;
  static readonly cardSm: number = 18;
  static readonly icon: number = 14;
  static readonly chip: number = 12;
  static readonly input: number = 10;
  static readonly button: number = 14;
  static readonly sheet: number = 28;
  static readonly pill: number = 999;
}

export class Shadow {
  static card(isDark: boolean): ShadowOptions {
    const options: ShadowOptions = {
      radius: 28,
      offsetX: 0,
      offsetY: 10,
      color: isDark ? 'rgba(0,0,0,0.32)' : 'rgba(50,40,110,0.08)'
    };
    return options;
  }

  static nav(isDark: boolean): ShadowOptions {
    const options: ShadowOptions = {
      radius: 24,
      offsetX: 0,
      offsetY: -8,
      color: isDark ? 'rgba(0,0,0,0.26)' : 'rgba(50,40,110,0.06)'
    };
    return options;
  }

  static fab(isDark: boolean): ShadowOptions {
    const options: ShadowOptions = {
      radius: 34,
      offsetX: 0,
      offsetY: 16,
      color: isDark ? 'rgba(165,180,252,0.38)' : 'rgba(67,56,202,0.38)'
    };
    return options;
  }
}

export class Duration {
  static readonly fast: number = 150;
  static readonly normal: number = 220;
  static readonly slow: number = 320;
}
