import Component from '@glimmer/component';
import { colorMapping } from '../../utils/css-mappings/eui-stat';
import { sizeMapping } from '../../utils/css-mappings/eui-title';
import { keysOf } from '../common';

type EuiTitleSize = keyof typeof sizeMapping;

export const COLORS = keysOf(colorMapping);

export const isColorClass = (
  input: string
): input is keyof typeof colorMapping => {
  return colorMapping.hasOwnProperty(input);
};

type StatArgs = {
  /**
   * The color of the title text
   */
  titleColor?: keyof typeof colorMapping | string;

  /**
   * Size of the title. See EuiTitle for options ('s', 'm', 'l'... etc)
   */
  titleSize?: EuiTitleSize;

  title?: string | Component;
  description?: string | Component;
};

export default class EuiStart extends Component<StatArgs> {
  get isColorClass() {
    if (this.args.titleColor) {
      return isColorClass(this.args.titleColor);
    }
    return false;
  }

  get useScreenReader() {
    return (
      typeof this.args.title === 'string' &&
      typeof this.args.description === 'string'
    );
  }
}
