import { CanvasColors, ChartPalette } from '../../theme/Palette';

export class ChartColors {
  static slot(index: number, isDark: boolean): string {
    return ChartPalette.slot(index, isDark);
  }

  static other(isDark: boolean): string {
    return ChartPalette.of(isDark).other;
  }

  static surface(isDark: boolean): string {
    return CanvasColors.surface(isDark);
  }

  static line(isDark: boolean): string {
    return CanvasColors.line(isDark);
  }

  static ink(isDark: boolean): string {
    return CanvasColors.ink(isDark);
  }

  static ink3(isDark: boolean): string {
    return CanvasColors.ink3(isDark);
  }

  static brand(isDark: boolean): string {
    return CanvasColors.brand(isDark);
  }

  static brandInk(isDark: boolean): string {
    return CanvasColors.brandInk(isDark);
  }

  static brandSoft(isDark: boolean): string {
    return CanvasColors.brandSoft(isDark);
  }

  static expense(isDark: boolean): string {
    return CanvasColors.expense(isDark);
  }

  static white(): string {
    return CanvasColors.white();
  }

  static brandArea(isDark: boolean): string {
    return CanvasColors.brandArea(isDark);
  }

  static brandAreaEnd(isDark: boolean): string {
    return CanvasColors.brandAreaEnd(isDark);
  }

  static lineSoft(isDark: boolean): string {
    return CanvasColors.lineSoft(isDark);
  }

  static scrimPill(isDark: boolean): string {
    return CanvasColors.scrimPill(isDark);
  }
}
