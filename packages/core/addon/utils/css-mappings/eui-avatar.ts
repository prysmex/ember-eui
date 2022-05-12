import { isColorDark } from '../../helpers/is-color-dark';
import { hexToRgb } from '../../helpers/hex-to-rgb';
import { euiPaletteColorBlindBehindText } from '../../utils/color/eui_palettes';
import { isValidHex } from '../../helpers/is-valid-hex';
import { assert, warn } from '@ember/debug';

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
  color,
  imageUrl,
  initials
}: {
  name: string;
  color: string;
  iconColor: string;
  imageUrl?: string;
  initials?: string;
}): Styling {
  let assignedColor = color;
  // let iconCustomColor = iconColor;
  let avatarStyle: {
    backgroundColor?: string;
    color?: string;
    backgroundImage?: string;
  } = {};

  checkValidInitials(initials);

  const isNamedColor = color === 'plain' || color === null;

  if (imageUrl) {
    avatarStyle.backgroundImage = `url(${imageUrl})`;
  }

  if (!isNamedColor) {
    checkValidColor(color);

    name = name ? name : '';
    assignedColor =
      color || VIS_COLORS[Math.floor(name.length % VIS_COLORS.length)];

    const textColor = isColorDark(...hexToRgb(assignedColor || 'base'))
      ? '#FFFFFF'
      : '#000000';

    avatarStyle.backgroundColor = assignedColor;
    avatarStyle.color = textColor;
    return avatarStyle;
  }

  return avatarStyle;
}

export const checkValidColor = (color: string | 'plain' | null) => {
  const validHex = (color && isValidHex(color)) || color === 'plain';
  if (color && !validHex) {
    assert(
      'EuiAvatar needs to pass a valid color. This can either be a three or six character hex value',
      true
    );
  }
};

function checkValidInitials(initials?: string) {
  // Must be a string of 1 or 2 characters
  if (initials && initials.length > 2) {
    warn(
      'EuiAvatar only accepts a max of 2 characters for the initials as a string. It is displaying only the first 2 characters.',
      {
        id: 'EuiAvatar-initials-excedeed'
      }
    );
  }
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
