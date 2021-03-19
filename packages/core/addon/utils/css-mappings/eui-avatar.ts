import { isColorDark } from '../../helpers/is-color-dark';
import { hexToRgb } from '../../helpers/hex-to-rgb';
import { euiPaletteColorBlindBehindText } from '../../utils/color/eui_palettes';

export const baseClass = 'euiAvatar';
export const VIS_COLORS = euiPaletteColorBlindBehindText();

export const sizeMapping = {
  s: `${baseClass}--s`,
  m: `${baseClass}--m`,
  l: `${baseClass}--l`,
  xl: `${baseClass}--xl`
};

export const typeMapping = {
  space: `${baseClass}--space`,
  user: `${baseClass}--user`
};

export function inlineStyles({
  name,
  avatarColor
}: {
  name: string;
  avatarColor: string;
}): Styling {
  let assignedColor = avatarColor;
  if (name && !assignedColor) {
    assignedColor = VIS_COLORS[Math.floor(name.length % VIS_COLORS.length)];
  }
  const textColor = isColorDark(...hexToRgb(assignedColor || 'base'))
    ? '#FFFFFF'
    : '#000000';

  return {
    'background-color': assignedColor,
    color: textColor
  };
}

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    size: sizeMapping,
    type: typeMapping
  },
  inlineStyles: inlineStyles
};

export default mapping;
