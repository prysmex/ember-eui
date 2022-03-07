import { euiPaletteColorBlindBehindText } from '../color';
import { keysOf } from '../../components/common';
import { isColorDark } from '../../helpers/is-color-dark';
import { hexToRgb } from '../../helpers/hex-to-rgb';

export const VIS_COLORS = euiPaletteColorBlindBehindText();

export const colorToHexMap = {
  default: '#d3dae6',
  primary: VIS_COLORS[1],
  success: VIS_COLORS[0],
  accent: VIS_COLORS[2],
  warning: VIS_COLORS[5],
  danger: VIS_COLORS[9]
};

export const COLORS = keysOf(colorToHexMap);

export type EuiBadgeColorType = keyof typeof colorToHexMap;

export type ColorType = EuiBadgeColorType | string;

export const baseClass = 'euiBadge';

export function inlineStyles({ badgeColor }: { badgeColor: ColorType }): Styling {
  let textColor = null;
  let colorHex = 'default';

  if (COLORS.indexOf(badgeColor as EuiBadgeColorType) > -1) {
    colorHex = colorToHexMap[badgeColor as EuiBadgeColorType];
    textColor = isColorDark(...hexToRgb(colorHex)) ? '#fff' : '#000';
  } else if (badgeColor !== 'hollow') {
    textColor = isColorDark(...hexToRgb(badgeColor)) ? '#fff' : '#000';
    colorHex = badgeColor;
  }

  return {
    'background-color': colorHex,
    color: textColor
  };
}

export const iconSideMapping = {
  left: `${baseClass}--iconLeft`,
  right: `${baseClass}--iconRight`
};

export const colorMapping = {
  hollow: `${baseClass}--hollow`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    iconSide: iconSideMapping,
    color: colorMapping
  },
  inlineStyles: inlineStyles
};

export default mapping;
