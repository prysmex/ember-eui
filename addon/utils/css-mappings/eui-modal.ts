export const baseClass: string = 'euiModal';
import { typeOf } from '@ember/utils';

export function inlineStyles({ maxWidth }: { maxWidth: string | number }) {
  let value = typeOf(maxWidth) === 'number' ? `${maxWidth}px` : `${maxWidth}`;

  return {
    'max-width': value,
  };
}

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {},
  inlineStyles: inlineStyles,
};

export default mapping;
