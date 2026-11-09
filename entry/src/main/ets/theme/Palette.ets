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

export function withAlpha(hex: string, alpha: number): string {
  const raw: string = hex.startsWith('#') ? hex.substring(1) : hex;
  if (raw.length !== 6) {
    return hex;
  }
  const ratio: number = alpha < 0 ? 0 : (alpha > 1 ? 1 : alpha);
  const aa: string = Math.round(ratio * 255).toString(16).toUpperCase().padStart(2, '0');
  return '#'.concat(aa).concat(raw.toUpperCase());
}
