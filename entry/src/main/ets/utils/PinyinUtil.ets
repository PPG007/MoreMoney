import { i18n } from '@kit.LocalizationKit';

export function pinyinKey(name: string): string {
  const trimmed: string = name.trim();
  if (trimmed.length === 0) {
    return '';
  }
  try {
    const transliterator: i18n.Transliterator = i18n.Transliterator.getInstance('Han-Latin');
    const raw: string = transliterator.transform(trimmed).toLowerCase();
    const plain: string = raw.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]/g, '');
    if (plain.length > 0) {
      return plain;
    }
  } catch (error) {
    return trimmed.toLowerCase();
  }
  return trimmed.toLowerCase();
}
