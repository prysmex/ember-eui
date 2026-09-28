import { htmlSafe } from '@ember/template';

import type { SafeString } from '@ember/template';

export type CssProperties = Record<string, string | number | null | undefined>;

// CSS properties whose unitless numbers are not pixels
const UNITLESS = new Set([
  'flex',
  'flexGrow',
  'flexShrink',
  'fontWeight',
  'lineHeight',
  'opacity',
  'order',
  'zIndex'
]);

/**
 * Builds a `style` attribute from an object of CSS properties
 * (`{ maxWidth: 300, backgroundColor: '#fff' }`). Empty values are skipped,
 * numbers get `px` (except unitless properties like `opacity`), and
 * characters that could end the declaration are dropped, so values from
 * arguments cannot inject other properties.
 */
export default function cssStyle(properties: CssProperties): SafeString | undefined {
  const declarations = Object.entries(properties).flatMap(([key, value]) => {
    if (value === null || value === undefined || value === '') return [];

    const property = key.startsWith('--')
      ? key
      : key.replace(/[A-Z]/g, (char) => `-${char.toLowerCase()}`);
    const text =
      typeof value === 'number' && !UNITLESS.has(key) && !key.startsWith('--')
        ? `${value}px`
        : String(value);

    return [`${property}: ${text.replace(/[;{}<>"]/g, '')}`];
  });

  return declarations.length ? htmlSafe(declarations.join('; ')) : undefined;
}
