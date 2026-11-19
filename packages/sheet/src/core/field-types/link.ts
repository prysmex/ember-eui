import type { FieldType, LinkField } from '../types.ts';

/** The schemes the sheet opens. */
export const LINK_PROTOCOLS: readonly string[] = [
  'http:',
  'https:',
  'mailto:',
  'tel:'
];

/** `href` when it parses and its scheme is one the sheet opens, else undefined. */
export function safeLink(href: unknown): string | undefined {
  if (typeof href !== 'string' || href.trim() === '') return undefined;
  try {
    return LINK_PROTOCOLS.includes(new URL(href.trim()).protocol)
      ? href.trim()
      : undefined;
  } catch {
    return undefined;
  }
}

/** A URL with `https://` added when it has no scheme. */
function withScheme(text: string): string {
  return /^[a-z][a-z\d+.-]*:/i.test(text) ? text : `https://${text}`;
}

function webUrl(value: string): string | undefined {
  const href = withScheme(value.trim());
  try {
    const url = new URL(href);
    if (url.protocol !== 'http:' && url.protocol !== 'https:') return undefined;
    // a bare word is not a site: it needs a dot or `localhost`
    if (!url.hostname.includes('.') && url.hostname !== 'localhost') {
      return undefined;
    }
    return href;
  } catch {
    return undefined;
  }
}

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const PHONE = /^\+?[\d\s()-]*\d[\d\s()-]*$/;

function linkType(
  check: (value: string) => boolean,
  message: 'notAUrl' | 'notAnEmail' | 'notAPhone',
  link: (value: string) => string | undefined
): FieldType<string, LinkField> {
  return {
    parse: (text) => ({ value: text.trim() }),
    format: (value) => (value == null ? '' : String(value)),
    validate(value, field, context) {
      const text = String(value);
      const errors: string[] = [];
      if (!check(text)) errors.push(context.messages[message](text));
      if (field.maxLength !== undefined && text.length > field.maxLength) {
        errors.push(context.messages.maxLength(field.maxLength));
      }
      return errors;
    },
    compare: (a, b) => String(a ?? '').localeCompare(String(b ?? '')),
    link(value) {
      if (value == null || String(value).trim() === '') return undefined;
      const text = String(value).trim();
      return check(text) ? safeLink(link(text)) : undefined;
    }
  };
}

/** `url`: text; `validate` reads it as a web address (`https://` is added when it has no scheme). */
export const urlFieldType = linkType(
  (value) => webUrl(value) !== undefined,
  'notAUrl',
  webUrl
);

/** `email`: text; `validate` wants `x@y.z`. Opens `mailto:`. */
export const emailFieldType = linkType(
  (value) => EMAIL.test(value),
  'notAnEmail',
  (value) => `mailto:${value}`
);

/** `phone`: text of digits, spaces and `+ ( ) -`. Opens `tel:`. */
export const phoneFieldType = linkType(
  (value) => PHONE.test(value),
  'notAPhone',
  (value) => `tel:${value.replace(/[^\d+]/g, '')}`
);
