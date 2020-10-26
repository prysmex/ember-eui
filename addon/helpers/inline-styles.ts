import { helper } from '@ember/component/helper';
import { euiPaletteColorBlindBehindText } from '../utils';
import { isColorDark } from '../helpers/is-color-dark';
import { hexToRgb } from '../helpers/hex-to-rgb';
import { keysOf } from 'ember-eui/components/common';

export const VIS_COLORS = euiPaletteColorBlindBehindText();
export const colorToHexMap: any = {
  default: '#d3dae6',
  primary: VIS_COLORS[1],
  secondary: VIS_COLORS[0],
  accent: VIS_COLORS[2],
  warning: VIS_COLORS[5],
  danger: VIS_COLORS[9]
}
export const COLORS = keysOf(colorToHexMap);

export function inlineStyles(positional, {...args}) {

  switch(args.componentName) {
    case 'EuiAvatar':
      args.backgroundColor = args.backgroundColor || VIS_COLORS[Math.floor(args.name.length % VIS_COLORS.length)];
      args.color = isColorDark(...hexToRgb(args.backgroundColor)) ? '#FFFFFF' : '#000000';
      if (args.name) delete args.name;
      delete args.componentName
      break;
    case 'EuiBadge':
      if (COLORS.indexOf(args.backgroundColor) > -1) {
        args.backgroundColor = colorToHexMap[args.backgroundColor];
        args.color = isColorDark(...hexToRgb(args.backgroundColor)) ? '#fff' : '#000';

      } else if (args.backgroundColor !== 'hollow') {
        args.color = isColorDark(...hexToRgb(args.backgroundColor)) ? '#fff' : '#000';
      }
      delete args.componentName
      break;
    default:
      delete args.componentName
      break;
  }

  // Array of strings that will contain all style properties
  let styles: string[] = [];

  // Loop through all styles coming in args, dasherize and push to styles[]
  for(let property in args) {
    let style;
    if (property === 'backgroundImage' && args[property] !== 'none') {
      style = `${property}`.replace(/[A-Z]/g, m => "-" + m.toLowerCase()) + `: url(${args[property]})`;
    } else {
      style = `${property}`.replace(/[A-Z]/g, m => "-" + m.toLowerCase()) + `: ${args[property]}`;
    }

    styles.push(style);
  }

  console.log(styles);
  return styles.join('; ');
}

export default helper(inlineStyles);
