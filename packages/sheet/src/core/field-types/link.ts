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

/** Four decimal parts of 0-255: an IPv4 address as people write one. */
const DOTTED_QUAD =
  /^(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}$/;
/** A label of a host name: letters, digits and `-` (any script; `_` for the odd real host). */
const LABEL =
  /^[\p{L}\p{N}\p{M}_](?:[\p{L}\p{N}\p{M}_-]*[\p{L}\p{N}\p{M}_])?$/u;

/**
 * The host as the text writes it (READINESS.md item 5): the part after
 * `//` up to the path, without a `user@` and a `:port`. The URL parser's
 * `hostname` is not used for the rule: it reads `19/11/2026` as the host
 * `19`, and `19` as the IPv4 address 0.0.0.19.
 */
function writtenHost(href: string): string | undefined {
  const match = /^[a-z][a-z\d+.-]*:\/\/([^/?#\\]*)/i.exec(href);
  if (!match) return undefined;
  let host = match[1]!;
  host = host.slice(host.lastIndexOf('@') + 1);
  if (host.startsWith('[')) {
    const end = host.indexOf(']');
    return end < 0 ? undefined : host.slice(0, end + 1);
  }
  return host.replace(/:\d*$/, '');
}

/**
 * Whether a written host names a site: `localhost`, a bracketed IPv6
 * address, a dotted quad (`192.168.0.1`), or a name of two or more
 * dot-separated labels whose last label (the top-level domain) has a
 * letter (`example.com`, `acme.mx.`, `ñandú.mx`). So `19`, `12`, `1.2.3`
 * and `0x7f.1` are not sites, though the URL parser reads them as IPv4.
 */
function isSiteHost(host: string): boolean {
  const name = host.toLowerCase().replace(/\.$/, '');
  if (name === 'localhost') return true;
  if (name.startsWith('[') && name.endsWith(']')) return true;
  if (DOTTED_QUAD.test(name)) return true;
  const labels = name.split('.');
  return (
    labels.length >= 2 &&
    labels.every((label) => LABEL.test(label)) &&
    /\p{L}/u.test(labels[labels.length - 1]!)
  );
}

function webUrl(value: string): string | undefined {
  const href = withScheme(value.trim());
  try {
    const url = new URL(href);
    if (url.protocol !== 'http:' && url.protocol !== 'https:') return undefined;
    const host = writtenHost(href);
    if (host === undefined || !isSiteHost(host)) return undefined;
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
