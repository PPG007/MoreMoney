export class ChartColors {  slots: string[] = [];
  other: string = '';
}

export class MemberColors {
  self: string = '';
  family: string = '';
  child: string = '';
  c6: string = '';
  c8: string = '';
  c3: string = '';
}

export class ChartPalette {
  static readonly slotCount: number = 5;
  static readonly keys: string[] = ['c1', 'c2', 'c3', 'c4', 'c5'];

  static of(isDark: boolean): ChartColors {
    return chartColors(isDark);
  }

  static slot(index: number, isDark: boolean): string {
    const colors: ChartColors = chartColors(isDark);
    if (index < 0 || index >= colors.slots.length) {
      return colors.other;
    }
    return colors.slots[index];
  }
}

export class MemberPalette {
  static readonly keys: string[] = ['self', 'family', 'child', 'c6', 'c8', 'c3'];

  static of(isDark: boolean): MemberColors {
    return memberColors(isDark);
  }

  static resolve(key: string, isDark: boolean): string {
    const colors: MemberColors = memberColors(isDark);
    if (key === 'family') {
      return colors.family;
    }
    if (key === 'child') {
      return colors.child;
    }
    if (key === 'c6') {
      return colors.c6;
    }
    if (key === 'c8') {
      return colors.c8;
    }
    if (key === 'c3') {
      return colors.c3;
    }
    return colors.self;
  }
}

export function chartColors(isDark: boolean): ChartColors {
  const colors: ChartColors = new ChartColors();
  colors.slots = isDark
    ? ['#3987E5', '#D95926', '#199E70', '#C98500', '#D55181']
    : ['#2A78D6', '#EB6834', '#1BAF7A', '#EDA100', '#E87BA4'];
  colors.other = isDark ? '#7D6C75' : '#B8AAB1';
  return colors;
}

export function memberColors(isDark: boolean): MemberColors {
  const colors: MemberColors = new MemberColors();
  colors.self = isDark ? '#6FB0FF' : '#2A78D6';
  colors.family = isDark ? '#FF9CC1' : '#C94B7B';
  colors.child = isDark ? '#4FD1A0' : '#137A57';
  colors.c6 = isDark ? '#9085E9' : '#6250D6';
  colors.c8 = isDark ? '#E66767' : '#E34948';
  colors.c3 = isDark ? '#199E70' : '#1BAF7A';
  return colors;
}

export class BarColors {
  static readonly statusBarDark: string = '#000000';
  static readonly statusBarLight: string = '#FFFFFF';
}

export class OverlayColors {
  static percentPill(): string {
    return withAlpha('#000000', 0.45);
  }
}

export class CanvasColors {
  static surface(isDark: boolean): string {
    return isDark ? '#1C1925' : '#FFFFFF';
  }

  static line(isDark: boolean): string {
    return isDark ? '#332D40' : '#EEE4E6';
  }

  static ink(isDark: boolean): string {
    return isDark ? '#F4F0FA' : '#272231';
  }

  static ink3(isDark: boolean): string {
    return isDark ? '#9C93A8' : '#756B7B';
  }

  static brand(isDark: boolean): string {
    return isDark ? '#818CF8' : '#6366F1';
  }

  static brandInk(isDark: boolean): string {
    return isDark ? '#A5B4FC' : '#4338CA';
  }

  static brandSoft(isDark: boolean): string {
    return isDark ? '#2E2A5E' : '#E0E7FF';
  }

  static expense(isDark: boolean): string {
    return isDark ? '#FF9A9A' : '#C62F3D';
  }

  static white(): string {
    return '#FFFFFF';
  }

  static brandArea(isDark: boolean): string {
    return isDark ? 'rgba(129,140,248,0.30)' : 'rgba(99,102,241,0.30)';
  }

  static brandAreaEnd(isDark: boolean): string {
    return isDark ? 'rgba(129,140,248,0)' : 'rgba(99,102,241,0)';
  }

  static lineSoft(isDark: boolean): string {
    return isDark ? 'rgba(51,45,64,0.40)' : 'rgba(238,228,230,0.40)';
  }

  static scrimPill(isDark: boolean): string {
    return isDark ? 'rgba(28,25,37,0.94)' : 'rgba(255,255,255,0.94)';
  }
}

export class RingColors {
  static track(isDark: boolean): string {
    return isDark ? '#25212E' : '#F5F0F1';
  }

  static expense(isDark: boolean): string {
    return isDark ? '#FF9A9A' : '#C62F3D';
  }

  static brandStart(isDark: boolean): string {
    return isDark ? '#818CF8' : '#6366F1';
  }

  static brandEnd(isDark: boolean): string {
    return isDark ? '#A5B4FC' : '#4338CA';
  }
}

export class LineColors {
  static cardBorder(isDark: boolean): string {
    return isDark ? withAlpha('#332D40', 0.76) : withAlpha('#EEE4E6', 0.76);
  }
}

export class ToneColors {
  static warnSoft(isDark: boolean): string {
    return withAlpha(isDark ? '#F0B45A' : '#8A5200', 0.12);
  }
}

export class SnackColors {
  static accent(tone: string, isDark: boolean): string {
    if (tone === 'success') {
      return isDark ? '#4FD1A0' : '#137A57';
    }
    if (tone === 'error') {
      return isDark ? '#FF9A9A' : '#C62F3D';
    }
    if (tone === 'warning') {
      return isDark ? '#F0B45A' : '#8A5200';
    }
    return isDark ? '#A5B4FC' : '#4338CA';
  }

  static surface(tone: string, isDark: boolean): string {
    if (tone === 'success') {
      return isDark ? '#18261F' : '#EAF7F1';
    }
    if (tone === 'error') {
      return isDark ? '#2A1A1D' : '#FBECEE';
    }
    if (tone === 'warning') {
      return isDark ? '#2A2218' : '#FCF4E7';
    }
    return isDark ? '#1E1B39' : '#EEF2FF';
  }

  static border(tone: string, isDark: boolean): string {
    return withAlpha(SnackColors.accent(tone, isDark), isDark ? 0.42 : 0.32);
  }

  static iconWash(tone: string, isDark: boolean): string {
    return withAlpha(SnackColors.accent(tone, isDark), isDark ? 0.2 : 0.14);
  }

  static muted(isDark: boolean): string {
    return isDark ? '#B8AEC4' : '#6B6272';
  }

  static closeWash(isDark: boolean): string {
    return isDark ? '#1FFFFFFF' : '#0F272231';
  }

  static text(isDark: boolean): string {
    return isDark ? '#F4F0FA' : '#272231';
  }
}

export class SeedColors {
  static readonly c1: string = '#2A78D6';
  static readonly c2: string = '#EB6834';
  static readonly c3: string = '#1BAF7A';
  static readonly c4: string = '#EDA100';
  static readonly c5: string = '#E87BA4';
  static readonly c6: string = '#6250D6';
  static readonly c7: string = '#008300';
  static readonly c8: string = '#E34948';
  static readonly neutral: string = '#B8AAB1';
  static readonly memberFamily: string = '#C94B7B';
  static readonly memberChild: string = '#137A57';
}

export function memberColorOf(value: string, isDark: boolean): string {
  if (value.startsWith('#')) {
    return value;
  }
  return MemberPalette.resolve(value, isDark);
}

export function withAlpha(hex: string, alpha: number): string {
  const raw: string = hex.startsWith('#') ? hex.substring(1) : hex;
  if (raw.length !== 6) {
    return hex;
  }
  const ratio: number = alpha < 0 ? 0 : (alpha > 1 ? 1 : alpha);
  const aa: string = Math.round(ratio * 255).toString(16).toUpperCase().padStart(2, '0');
  return '#'.concat(aa).concat(raw.toUpperCase());
}
