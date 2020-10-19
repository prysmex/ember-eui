import { helper } from '@ember/component/helper';
import { isColorDark } from '../helpers/is-color-dark';
import { hexToRgb } from '../helpers/hex-to-rgb';
import { euiPaletteColorBlindBehindText } from '../utils';
import  { htmlSafe } from '@ember/string';

export const VIS_COLORS = euiPaletteColorBlindBehindText();

export default helper(function ([name, color, imageUrl]: [string, string, string]) : unknown {

  let assignedColor = color || VIS_COLORS[Math.floor(name.length % VIS_COLORS.length)];

  let textColor = isColorDark(...hexToRgb(assignedColor)) ? '#FFFFFF' : '#000000';

  let backgroundImage = imageUrl ? `url(${imageUrl})` : 'none';

  let avatarStyles = htmlSafe(
    `
      background-image: ${backgroundImage};
      background-color: ${assignedColor};
      color: ${textColor}
    `
  );

  return avatarStyles;
});