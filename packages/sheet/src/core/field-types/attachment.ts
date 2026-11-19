import type { AttachmentField, FieldType, SheetAttachment } from '../types.ts';

type Value = SheetAttachment[];

function list(value: unknown): Value {
  return Array.isArray(value) ? (value as Value) : [];
}

/**
 * A URL the sheet may put in `src` or `href`: `http:`, `https:`, `blob:`, or
 * a `data:image/` URL. Anything else (`javascript:`, other data) is not used.
 */
export function safeFileUrl(url: unknown): string | undefined {
  if (typeof url !== 'string') return undefined;
  const trimmed = url.trim();
  if (/^data:image\//i.test(trimmed)) return trimmed;
  try {
    const protocol = new URL(trimmed).protocol;
    return protocol === 'http:' || protocol === 'https:' || protocol === 'blob:'
      ? trimmed
      : undefined;
  } catch {
    return undefined;
  }
}

/**
 * `attachment`: an array of `{ id, name, url, type?, size?, thumbnailUrl? }`
 * (`[]` when empty). Text cannot become a file: only `''` (a clear) parses.
 * Files are added by `field.upload` (the editor, a drop, files pasted from
 * the clipboard). Copies the URLs, so this is the one type where
 * `parse(copyText(v))` does not give `v`.
 */
export const attachmentFieldType: FieldType<Value, AttachmentField> = {
  parse(text, _field, { messages }) {
    if (text.trim() === '') return { value: [] };
    return { error: messages.notAnAttachment() };
  },
  format: (value) =>
    list(value)
      .map((file) => file.name)
      .join(', '),
  copyText: (value) =>
    list(value)
      .map((file) => file.url)
      .join(', '),
  isEmpty: (value) => value == null || list(value).length === 0,
  equals(a, b) {
    const x = list(a);
    const y = list(b);
    return x.length === y.length && x.every((file, i) => file.id === y[i]!.id);
  },
  compare: (a, b) => list(a).length - list(b).length
};
