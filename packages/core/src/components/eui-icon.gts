import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { warn } from '@ember/debug';
import { guidFor } from '@ember/object/internals';
import { service } from '@ember/service';

import { modifier } from 'ember-modifier';

import { loadedIcon } from '../-private/icon-loader.ts';
import { emptyIcon, iconDataTypes } from '../-private/icons.ts';

import { typeToPathMap } from '../utils/css-mappings/eui-icon.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import { euiIconStyles } from '../utils/eui/styles.generated.ts';
import { keysOf } from './common.ts';

import type { EuiIconComponent } from '../-private/icons.ts';
import type EuiConfigService from '../services/eui-config';
import type { EuiThemeContext } from '../utils/emotion/context.ts';
import type { CommonArgs } from './common.ts';
import type { SerializedStyles } from '@emotion/serialize';
import type { ComponentLike } from '@glint/template';

export const TYPES = keysOf(typeToPathMap);

export type EuiIconType = keyof typeof typeToPathMap;

export type IconType = EuiIconType | string | ComponentLike;

/** Named icon colors of EUI 123 (Borealis), in upstream's order. */
export const COLORS = [
  'default',
  'primary',
  'neutral',
  'success',
  'accent',
  'accentSecondary',
  'warning',
  'risk',
  'danger',
  'text',
  'subdued',
  'ghost',
  'inherit'
] as const;

export type NamedColor = (typeof COLORS)[number];

export function isNamedColor(name: string): name is NamedColor {
  return (COLORS as readonly string[]).includes(name);
}

// We accept arbitrary color strings, which are impossible to type.
type IconColor = string | NamedColor;

/** Upstream sizes: 12/16/24/32/40px squares, or the svg's own size. */
export const SIZES = ['original', 's', 'm', 'l', 'xl', 'xxl'] as const;

/**
 * The `@size` type. `'original'` also works at runtime but stays out of the
 * type, as before: callers forward this type to components without it.
 */
export type IconSize = Exclude<(typeof SIZES)[number], 'original'>;

type IconStyles = Record<string, SerializedStyles>;

/**
 * EuiIcon renders everywhere, so the upstream factory runs once per resolved
 * theme (contexts cache their `upstream` theme), not once per icon.
 */
function iconStyles(context: EuiThemeContext): IconStyles {
  return useEuiBorealisStyles(context, euiIconStyles) as IconStyles;
}

/**
 * Calls `@onIconLoad` once the rendered icon is final: right away for
 * images and components, after the svg arrived for EUI icons.
 */
const notifyLoaded = modifier(function notifyLoaded(
  _element: Element,
  [isLoading, onIconLoad]: [boolean, (() => void) | undefined]
) {
  if (!isLoading) onIconLoad?.();
});

/**
 * The EUI icon type each instance saw loading. Untracked bookkeeping (like
 * upstream's `neededLoading` state): it only decides whether the icon fades
 * in once it arrives, and never invalidates a render by itself.
 */
const sawLoading = new WeakMap<object, string>();

/** Upstream `getIsAppIcon`: two-toned app and ML job icons. */
function isAppIconType(type: unknown): boolean {
  if (typeof type !== 'string') return false;
  if (type === 'dataVisualizer') return true;
  if (type.indexOf('data:') === 0) return false;

  return type.endsWith('App') || type.endsWith('Job');
}

export type EuiIconArgs = CommonArgs & {
  /**
   * Extra styles composed last into this component's class (like upstream's
   * `css` prop). Prefer this to an extra class when styling it from a parent.
   */
  css?: EuiCss;
  /**
   * `Enum` is any of the named icons listed in the docs, `string` is usually a URL to an SVG file, and `elementType` is any Ember Icon SVG component
   */
  type: IconType;

  /**
   * One of EUI's named colors (`'default'`, `'primary'`, `'neutral'`,
   * `'success'`, `'accent'`, `'accentSecondary'`, `'warning'`, `'risk'`,
   * `'danger'`, `'text'`, `'subdued'`, `'ghost'`, `'inherit'`) or a valid
   * CSS color value https://developer.mozilla.org/en-US/docs/Web/CSS/color_value.
   * Without a color, the icon uses the inherited text color.
   * Note that coloring only works if your SVG is removed of fill attributes.
   */
  color?: IconColor;
  /**
   * `'s'` (12px), `'m'` (16px), `'l'` (24px), `'xl'` (32px), `'xxl'`
   * (40px) or `'original'` (the svg's own width and height). Defaults to
   * `'m'`.
   * Note that every size other than `original` assumes the provided SVG sits on a square viewbox.
   */
  size?: IconSize;

  /**
   * @deprecated No longer has any effect. EUI icons are always inline svgs,
   * icons registered through the `euiIcon.icons` config are rendered as
   * components and any other string is treated as an image URL.
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
   * @deprecated Not needed anymore: a component passed as `@type` is
   * always rendered as a component.
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

/**
 * An icon: one of EUI's named icons, an app icon registered through the
 * `euiIcon.icons` config, an svg component or an image URL. Styled with
 * upstream EUI 123 (Borealis) `euiIconStyles`.
 */
export default class EuiIcon extends Component<EuiIconSignature> {
  @service declare euiConfig: EuiConfigService;

  notifyLoaded = notifyLoaded;


  get context(): EuiThemeContext {
    return getEuiThemeContext(this);
  }

  get size(): (typeof SIZES)[number] {
    const size: string | undefined = this.args.size;

    return size && (SIZES as readonly string[]).includes(size)
      ? (size as (typeof SIZES)[number])
      : 'm';
  }

  /** The icon registered by the app under this name (`euiIcon.icons`). */
  get registeredIcon(): EuiIconComponent | undefined {
    const { type } = this.args;
    const icons = typeof type === 'string' ? this.euiConfig.getConfig('euiIcon.icons') : undefined;

    return icons && Object.prototype.hasOwnProperty.call(icons, type as string)
      ? (icons[type as string] as EuiIconComponent)
      : undefined;
  }

  /**
   * The EUI icon name to render, if `@type` is one. A name the app
   * registered through the `euiIcon.icons` config wins over an EUI icon of
   * the same name, so app icons keep rendering when EUI adds icons (e.g.
   * `rocket` or `copy` in EUI 123).
   */
  get euiIconType(): EuiIconType | undefined {
    const { type } = this.args;

    return isEuiIconType(type) && !this.registeredIcon ? type : undefined;
  }

  /**
   * The component rendering the svg: for EUI icon names, for names
   * registered by the app through the `euiIcon.icons` config, and for
   * components passed directly as `@type` (e.g. `@iconType={{MyLogo}}`).
   * EUI icons load the first time they render (see preloadIcons); the empty
   * icon takes their place meanwhile.
   */
  get iconComponent(): EuiIconComponent | undefined {
    const { type } = this.args;

    if (type && (typeof type === 'object' || typeof type === 'function')) {
      return type as EuiIconComponent;
    }

    if (typeof type !== 'string') return undefined;

    const euiType = this.euiIconType;

    if (euiType) return loadedIcon(euiType) ?? emptyIcon;

    return this.registeredIcon;
  }

  /**
   * Upstream `isLoading`: an EUI icon whose svg has not arrived yet. It
   * shows as a faint rounded square instead of an invisible empty svg.
   */
  get isLoading(): boolean {
    const type = this.euiIconType;

    if (!type || type === 'empty') return false;

    const loading = loadedIcon(type) === undefined;

    if (loading) sawLoading.set(this, type);

    return loading;
  }

  /** Upstream `isLoaded`: fades in an icon that had to load. */
  get isLoaded(): boolean {
    return !this.isLoading && sawLoading.get(this) === this.args.type;
  }

  get dataType(): string | undefined {
    const type = this.euiIconType;

    return type ? iconDataTypes[type] : undefined;
  }

  get iconType(): string | undefined {
    return this.euiIconType;
  }

  get useImage(): boolean {
    const { type } = this.args;

    if (typeof type !== 'string' || this.iconComponent) return false;

    warn(
      `<EuiIcon @type="${type}"> is not an EUI icon nor an icon registered in the \`euiIcon.icons\` config, so it is rendered as an <img> with that URL. ` +
        `If this used to be an ember-svg-jar asset, register it instead, e.g. euiConfig.updateConfig({ 'euiIcon.icons': { '${type}': MyIconComponent } }).`,
      /[/.:]/.test(type),
      { id: 'ember-eui.eui-icon.unknown-type' }
    );

    return true;
  }

  @cached
  get classes(): string {
    const { color, type } = this.args;
    const context = this.context;
    const styles = iconStyles(context);
    const named = typeof color === 'string' && isNamedColor(color);
    const custom = typeof color === 'string' && color !== '' && !named;
    // app icons keep their two tones unless a color other than default is set
    const appIconHasColor = color && color !== 'default';
    const isElasticLogoOutline =
      type === 'logoElastic' && (color === 'ghost' || color === 'text');

    const css = euiClass(
      context,
      styles['euiIcon'],
      styles[this.size],
      named && styles[color as string],
      custom && styles['customColor'],
      // upstream sets this inline; a class keeps the caller's `style` intact
      custom && { color },
      isElasticLogoOutline && styles['logoElasticOutline'],
      isAppIconType(type) && !appIconHasColor && styles['app'],
      this.isLoading && styles['isLoading'],
      this.isLoaded && styles['isLoaded'],
      this.args.css
    );

    return ['euiIcon', this.args.iconClasses, css].filter(Boolean).join(' ');
  }

  get hasLabel(): boolean {
    return Boolean(this.args['aria-label'] || this.args['aria-labelledby']);
  }

  /**
   * Upstream semantics: an icon with a `@title`, `@aria-label` or
   * `@aria-labelledby` is an `img`; any other icon is decorative
   * (`role="presentation"`). A `role` or `aria-hidden` attribute passed by
   * the caller wins.
   */
  get role(): 'img' | 'presentation' {
    return this.args.title || this.hasLabel ? 'img' : 'presentation';
  }

  /**
   * With a `@title` (and no `@aria-label` / `@aria-labelledby`), the svg
   * gets a `<title>` with this id and is labelled by it.
   */
  get titleId(): string | undefined {
    if (!this.args.title || this.hasLabel) return undefined;

    return this.args.titleId ?? `${guidFor(this)}-title`;
  }

  <template>
    {{#if @useComponent}}
      {{!@glint-expect-error}}
      {{#let (component @type) as |IconComponent|}}
        {{!template-lint-disable}}
        <IconComponent
          class={{this.classes}}
          role={{this.role}}
          aria-label={{@aria-label}}
          aria-labelledby={{if @aria-labelledby @aria-labelledby this.titleId}}
          {{! @glint-expect-error }}
          tabindex={{@tabIndex}}
          ...attributes
          {{this.notifyLoaded this.isLoading @onIconLoad}}
        >
          {{#if @title}}
            <title id={{this.titleId}}>{{@title}}</title>
          {{/if}}
        </IconComponent>
      {{/let}}
    {{else}}
      {{#if this.useImage}}
        <img
          {{! @glint-expect-error }}
          src={{@type}}
          class={{this.classes}}
          alt={{if @title @title}}
          role={{this.role}}
          {{! @glint-expect-error }}
          tabIndex={{@tabIndex}}
          ...attributes
          {{this.notifyLoaded false @onIconLoad}}
        />
      {{else if this.iconComponent}}
        <this.iconComponent
          class={{this.classes}}
          data-type={{this.dataType}}
          data-icon-type={{this.iconType}}
          data-is-loading={{if this.isLoading "true"}}
          data-is-loaded={{if this.isLoaded "true"}}
          role={{this.role}}
          aria-label={{@aria-label}}
          aria-labelledby={{if @aria-labelledby @aria-labelledby this.titleId}}
          {{! @glint-expect-error }}
          tabindex={{@tabIndex}}
          ...attributes
          {{this.notifyLoaded this.isLoading @onIconLoad}}
        >
          {{#if @title}}
            <title id={{this.titleId}}>{{@title}}</title>
          {{/if}}
        </this.iconComponent>
      {{/if}}
    {{/if}}
  </template>
}
