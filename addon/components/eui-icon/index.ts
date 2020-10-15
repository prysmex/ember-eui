import Component from '@glimmer/component';
import { argOrDefaultDecorator as argOrDefault } from 'ember-eui/helpers/arg-or-default';
import { keysOf, CommonArgs } from '../common';
import {
  sizeToClassNameMap,
  colorToClassMap,
  typeToPathMap,
} from 'ember-eui/utils/css-mappings/eui-icon';
import { uniqueId } from 'ember-eui/helpers/unique-id';
import { htmlSafe } from '@ember/template';
import { getOwner } from '@ember/application';

export const TYPES = keysOf(typeToPathMap);

export type EuiIconType = keyof typeof typeToPathMap;

export type IconType = EuiIconType | string;

export const COLORS: NamedColor[] = keysOf(colorToClassMap);

type NamedColor = keyof typeof colorToClassMap;

function isNamedColor(name: string): name is NamedColor {
  return colorToClassMap.hasOwnProperty(name);
}

// We accept arbitrary color strings, which are impossible to type.
type IconColor = string | NamedColor;

export type IconSize = keyof typeof sizeToClassNameMap;

// const SVG_PREI : string | undefined = config['ember-eui'].svgPrefixPath || 'svg/assets';

export type EuiIconArgs = CommonArgs & {
  /**
   * `Enum` is any of the named icons listed in the docs, `string` is usually a URL to an SVG file, and `elementType` is any Ember Icon SVG component
   */
  type: IconType;

  /**
   * One of EUI's color palette or a valid CSS color value https://developer.mozilla.org/en-US/docs/Web/CSS/color_value.
   * Note that coloring only works if your SVG is removed of fill attributes.
   */
  color?: IconColor;
  /**
   * Note that every size other than `original` assumes the provided SVG sits on a square viewbox.
   */
  size?: IconSize;

  /**
   * Descriptive title for naming the icon based on its use
   */
  title?: string;
  /**
   * A unique identifier for the title element
   */
  titleId?: string;

  tabIndex?: unknown;

  /**
   * Its value should be one or more element IDs
   */
  'aria-labelledby'?: string;

  /**
   * Callback when the icon has been loaded & rendered
   */
  onIconLoad?: () => void;
};

function isEuiIconType(x: EuiIconArgs['type']): x is EuiIconType {
  return typeof x === 'string' && typeToPathMap.hasOwnProperty(x);
}

export default class EuiIcon extends Component<EuiIconArgs> {
  @argOrDefault('m') size!: IconSize;
  @argOrDefault('default') color!: IconColor;

  constructor(owner: unknown, args: EuiIconArgs) {
    super(owner, args);

    this.onIconLoad();
  }

  get useImage(): boolean {
    let { type } = this.args;
    return typeof type === 'string' && !isEuiIconType(type);
  }

  get icon(): IconType | void {
    let { type } = this.args;

    if (type === null) {
      return undefined;
    }

    //We should probably find a better way to always 
    if (isEuiIconType(type)) {
      const config = getOwner(this).resolveRegistration('config:environment');
      const svgPath = config?.['ember-eui']?.svgPath || 'svg/assets/';
      let euiIcon = typeToPathMap[type].toLowerCase();
      return `${svgPath}${euiIcon}`;
    }

    return type;
  }

  onIconLoad() {
    const { onIconLoad } = this.args;

    if (onIconLoad) {
      onIconLoad();
    }
  }

  get isAppIcon() {
    const { type } = this.args;
    return (
      type &&
      typeof type === 'string' &&
      (/.+App$/.test(type) || /.+Job$/.test(type) || type === 'dataVisualizer')
    );
  }

  get focusable() {
    const { tabIndex } = this.args;
    return tabIndex == null || tabIndex === -1 ? 'false' : 'true';
  }

  get optionalCustomStyles() {
    let { color } = this;
    if (color) {
      if (!isNamedColor(color)) {
        return htmlSafe(`fill: ${color}`);
      }
    }
    return '';
  }

  get optionalColorClass() {
    let { color } = this;
    if (color) {
      if (isNamedColor(color)) {
        return colorToClassMap[color];
      }
    }
    return '';
  }

  // If it's an empty icon, or if there is no aria-label, aria-labelledby, or title it gets aria-hidden true
  get isAriaHidden(): boolean {
    const { icon } = this;

    return (
      icon === 'empty' || !(this.args['aria-label'], this.args['aria-labelledby'], this.args.title)
    );
  }

  get titleId(): string {
    let { title } = this.args;
    let titleId: any;

    // If no aria-label or aria-labelledby is provided but there's a title, a titleId is generated
    //  The svg aria-labelledby attribute gets this titleId
    //  The svg title element gets this titleId as an id
    if (!this.args['aria-label'] && !this.args['aria-labelledby'] && title) {
      titleId = uniqueId();
    }
    return titleId;
  }
}
