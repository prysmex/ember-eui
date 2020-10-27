import { helper } from '@ember/component/helper';
import { euiPaletteColorBlindBehindText } from '../utils/color';
import  { htmlSafe } from '@ember/string';
import { keysOf } from 'ember-eui/components/common';
import chroma from 'chroma-js';
import { isColorDark } from './is-color-dark';
import { hexToRgb } from './hex-to-rgb';

export const VIS_COLORS = euiPaletteColorBlindBehindText();

export const colorToHexMap = {
  default: '#d3dae6',
  primary: VIS_COLORS[1],
  secondary: VIS_COLORS[0],
  accent: VIS_COLORS[2],
  warning: VIS_COLORS[5],
  danger: VIS_COLORS[9]
}

export const COLORS = keysOf(colorToHexMap);

export default helper(function ([color]: [string]) : unknown {

  let textColor = null;
  let colorHex = 'default';
  if (COLORS.indexOf(color) > -1) {
    colorHex = colorToHexMap[color];
    textColor = isColorDark(...hexToRgb(colorHex)) ? '#fff' : '#000';

  } else if (color !== 'hollow') {
    textColor = isColorDark(...hexToRgb(color)) ? '#fff' : '#000';
    colorHex = color;
  }

  return htmlSafe(
    `
      background-color: ${colorHex};
      color: ${textColor};
    `
  );
});