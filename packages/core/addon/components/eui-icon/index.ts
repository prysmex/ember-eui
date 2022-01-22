import Component from '@glimmer/component';
import { argOrDefaultDecorator as argOrDefault } from '../../helpers/arg-or-default';
import { keysOf, CommonArgs } from '../common';
import {
  sizeToClassNameMap,
  colorToClassMap,
  typeToPathMap
} from '../../utils/css-mappings/eui-icon';
import { uniqueId } from '../../helpers/unique-id';
import { htmlSafe } from '@ember/template';
import { getOwner } from '@ember/application';

export const TYPES = keysOf(typeToPathMap);

export type EuiIconType = keyof typeof typeToPathMap;

export type IconType = EuiIconType | string;

export const COLORS: NamedColor[] = keysOf(colorToClassMap);

type NamedColor = keyof typeof colorToClassMap;

function isNamedColor(name: NamedColor | string): name is NamedColor {
  return Object.prototype.hasOwnProperty.call(colorToClassMap, name);
}

// We accept arbitrary color strings, which are impossible to type.
type IconColor = string | NamedColor;

export type IconSize = keyof typeof sizeToClassNameMap;

// const SVG_PREI : string | undefined = config['ember-eui'].svgPath || 'svg/assets';

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
   * If the type is not a named eui icon, render as Svg, not as img.
   */
  useSvg?: boolean;

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
  return (
    typeof x === 'string' &&
    Object.prototype.hasOwnProperty.call(typeToPathMap, x)
  );
}

export default class EuiIcon extends Component<EuiIconArgs> {
  @argOrDefault('m') size!: IconSize;

  get useImage(): boolean {
    const { type } = this.args;
    return typeof type === 'string' && !isEuiIconType(type) && !this.useSvg;
  }

  get useSvg(): boolean {
    const config = getOwner(this).resolveRegistration('config:environment');
    return (
      this.args.useSvg ??
      config?.['@ember-eui/core']?.['eui-icon']?.useSvg ??
      false
    );
  }

  get icon(): IconType | void {
    const { type } = this.args;

    if (type === null) {
      return undefined;
    }

    //We should probably find a better way to always
    if (isEuiIconType(type)) {
      return this.getEuiIconSvgPath(type);
    }

    return type;
  }

  get emptyIcon(): string {
    return this.getEuiIconSvgPath('empty');
  }

  getEuiIconSvgPath(type: EuiIconType): string {
    const config = getOwner(this).resolveRegistration('config:environment');
    const svgPath = config?.['@ember-eui/core']?.svgPath || 'svg/assets/';
    const euiIcon = typeToPathMap[type].replace(/_/g, '-').toLowerCase();
    return `${svgPath}${euiIcon}`;
  }

  get isAppIcon(): string | boolean {
    const { type } = this.args;
    return (
      type &&
      typeof type === 'string' &&
      (/.+App$/.test(type) || /.+Job$/.test(type) || type === 'dataVisualizer')
    );
  }

  get focusable(): string {
    const { tabIndex } = this.args;
    return tabIndex == null || tabIndex === -1 ? 'false' : 'true';
  }

  get optionalCustomStyles(): ReturnType<typeof htmlSafe> | string {
    const { color } = this.args;
    if (color) {
      if (!isNamedColor(color)) {
        return htmlSafe(`fill: ${color}`);
      }
    }
    return '';
  }

  get optionalColorClass(): NamedColor | string {
    const { color } = this.args;
    if (color) {
      if (isNamedColor(color)) {
        return colorToClassMap[color];
      } else {
        return 'euiIcon--customColor';
      }
    }
    return '';
  }

  // If it's an empty icon, or if there is no aria-label, aria-labelledby, or title it gets aria-hidden true
  get isAriaHidden(): boolean {
    const { icon } = this;

    return (
      icon === 'empty' ||
      !(this.args['aria-label'], this.args['aria-labelledby'], this.args.title)
    );
  }

  get titleId(): string | undefined {
    const { title } = this.args;
    let titleId;

    // If no aria-label or aria-labelledby is provided but there's a title, a titleId is generated
    //  The svg aria-labelledby attribute gets this titleId
    //  The svg title element gets this titleId as an id
    if (!this.args['aria-label'] && !this.args['aria-labelledby'] && title) {
      titleId = uniqueId();
    }
    return titleId;
  }
}
