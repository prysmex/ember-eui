import { typeOf } from '@ember/utils';
export const baseClass = 'euiListGroup';

export const gutterSizeMapping = {
  none: '',
  s: `${baseClass}--gutterSmall`,
  m: `${baseClass}--gutterMedium`
};

export function inlineStyles({
  maxWidth
}: {
  maxWidth: string | number;
}): Styling {
  const value = typeOf(maxWidth) === 'number' ? `${maxWidth}px` : `${maxWidth}`;

  return {
    'max-width': value
  };
}

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    gutterSize: gutterSizeMapping
  },
  inlineStyles: inlineStyles
};

export default mapping;
