import { typeOf } from '@ember/utils';
export const baseClass = 'euiModal';

export function inlineStyles({
  maxWidth
}: {
  maxWidth: string | number;
}): Styling {
  let value = typeOf(maxWidth) === 'number' ? `${maxWidth}px` : `${maxWidth}`;

  return {
    'max-width': value
  };
}

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {},
  inlineStyles: inlineStyles
};

export default mapping;
