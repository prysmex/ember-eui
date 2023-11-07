import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import { htmlSafe } from '@ember/template';
import { colorToClassMap, typeToPathMap } from '../utils/css-mappings/eui-icon';
import { ensureSafeComponent } from '@embroider/util';

// @ts-expect-error
import svgJar from 'ember-svg-jar/helpers/svg-jar';
import { and, not } from 'ember-truth-helpers';

import { argOrDefaultDecorator } from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import { keysOf } from './common';

import type { CommonArgs } from './common';
import type { sizeToClassNameMap } from '../utils/css-mappings/eui-icon';
import type { ComponentLike } from '@glint/template';

let config = {};

export const TYPES = keysOf(typeToPathMap);

export type EuiIconType = keyof typeof typeToPathMap;

export type IconType = EuiIconType | string | ComponentLike;

export const COLORS: NamedColor[] = keysOf(colorToClassMap);

type NamedColor = keyof typeof colorToClassMap;

function isNamedColor(name: NamedColor | string): name is NamedColor {
  return Object.prototype.hasOwnProperty.call(colorToClassMap, name);
}

// We accept arbitrary color strings, which are impossible to type.
type IconColor = string | NamedColor;

export type IconSize = keyof typeof sizeToClassNameMap;

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

  /**
   * When you want to render a component instead of an SVG
   */
  useComponent?: boolean;

  /**
   * Classes to pass to the icon
   */
  iconClasses?: string;
};

export interface EuiIconSignature {
  Element: HTMLImageElement | Element;
  Args: EuiIconArgs;
}

function isEuiIconType(x: EuiIconArgs['type']): x is EuiIconType {
  return (
    typeof x === 'string' &&
    Object.prototype.hasOwnProperty.call(typeToPathMap, x)
  );
}

export default class EuiIcon extends Component<EuiIconSignature> {
  @argOrDefaultDecorator('m') size!: IconSize;

  get useImage(): boolean {
    const { type } = this.args;

    return typeof type === 'string' && !isEuiIconType(type) && !this.useSvg;
  }

  get useSvg(): boolean {
    return (
      this.args.useSvg ??
      //@ts-expect-error config is not typed
      config?.['@ember-eui/core']?.['euiIcon']?.useSvg ??
      false
    );
  }

  get icon(): IconType | ComponentLike | undefined {
    const { type } = this.args;

    if (type === null) {
      return undefined;
    }

    //We should probably find a better way to always
    if (isEuiIconType(type)) {
      return this.getEuiIconSvgPath(type);
    }

    if(typeof type === 'string' && type.includes('svg')) {
      return type;
    }

    return ensureSafeComponent(type, this);
  }


  get emptyIcon(): string {
    return this.getEuiIconSvgPath('empty');
  }

  getEuiIconSvgPath(type: EuiIconType): string {
    return typeToPathMap[type];
  }

  get isAppIcon(): string | boolean {
    const { type } = this.args;

    return (
      type &&
      typeof type === 'string' &&
      (/.+App$/.test(type) || /.+Job$/.test(type) || type === 'dataVisualizer')
    );
  }

  get appIconHasColor() {
    return this.args.color && this.args.color !== 'default';
  }

  get focusable(): string {
    const { tabIndex } = this.args;

    return tabIndex == null || tabIndex === -1 ? 'false' : 'true';
  }

  get optionalCustomStyles(): ReturnType<typeof htmlSafe> | string {
    const { color } = this.args;

    if (color && typeof color === 'string') {
      if (!isNamedColor(color)) {
        return htmlSafe(`fill: ${color}`);
      }
    }

    return '';
  }

  get optionalColorClass(): NamedColor | string {
    const { color } = this.args;

    if (color && typeof color === 'string') {
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
      titleId = guidFor({});
    }

    return titleId;
  }

  <template>
    {{#if (and @useComponent this.icon)}}
      {{!@glint-expect-error}}
      {{#let (component this.icon) as |IconComponent|}}
        {{!template-lint-disable}}
        <IconComponent
          class={{classNames
            @iconClasses
            this.optionalColorClass
            (if (and this.isAppIcon (not this.appIconHasColor)) "euiIcon--app")
            componentName="EuiIcon"
            size=this.size
          }}
          role="image"
          aria-hidden={{if this.isAriaHidden "true"}}
          aria-label={{if @aria-label @aria-label this.titleId}}
          aria-labelledby={{if @aria-labelledby @aria-labelledby this.titleId}}
          {{! @glint-expect-error }}
          tabindex={{@tabIndex}}
          style={{this.optionalCustomStyles}}
          color={{@color}}
          ...attributes
        />
      {{/let}}
    {{else}}
      {{#if this.useImage}}
        <img
          {{! @glint-expect-error }}
          src={{this.icon}}
          class={{classNames
            @iconClasses
            this.optionalColorClass
            (if (and this.isAppIcon (not this.appIconHasColor)) "euiIcon--app")
            componentName="EuiIcon"
            size=this.size
          }}
          color={{@color}}
          alt={{if @title @title}}
          {{! @glint-expect-error }}
          tabIndex={{@tabIndex}}
          ...attributes
        />
      {{else}}
        {{svgJar
          this.icon
          class=(classNames
            @iconClasses
            this.optionalColorClass
            (if (and this.isAppIcon (not this.appIconHasColor)) "euiIcon--app")
            componentName="EuiIcon"
            size=this.size
          )
          color=@color
          role="image"
          aria-hidden=(if this.isAriaHidden "true")
          aria-label=(if @aria-label @aria-label this.titleId)
          aria-labelledby=(if @aria-labelledby @aria-labelledby this.titleId)
          tabindex=@tabIndex
          style=this.optionalCustomStyles
        }}
      {{/if}}
    {{/if}}
  </template>
}
