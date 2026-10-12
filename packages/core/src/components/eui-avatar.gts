import Component from '@glimmer/component';
import { warn } from '@ember/debug';

import { hexToRgb } from '../helpers/hex-to-rgb.ts';
import { isColorDark } from '../helpers/is-color-dark.ts';
import { isValidHex } from '../helpers/is-valid-hex.ts';
import { toInitials } from '../helpers/to-initials.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiAvatarStyles } from '../utils/eui/styles.generated.ts';
import EuiIcon from './eui-icon.gts';

import type { CSSObject } from '@emotion/css/create-instance';
import type { SerializedStyles } from '@emotion/serialize';
import type { EuiIconSignature } from './eui-icon';

export const SIZES = ['s', 'm', 'l', 'xl'] as const;
export const TYPES = ['space', 'user'] as const;
export const CASING = ['capitalize', 'uppercase', 'lowercase', 'none'] as const;

export type EuiAvatarSize = (typeof SIZES)[number];
export type EuiAvatarType = (typeof TYPES)[number];
export type EuiAvatarCasing = (typeof CASING)[number];

type AvatarStyles = Record<string, SerializedStyles> & {
  tooltip: Record<string, SerializedStyles>;
};

function oneOf<T extends string>(
  values: readonly T[],
  value: unknown,
  fallback: T
): T {
  return (values as readonly unknown[]).includes(value) ? (value as T) : fallback;
}

export interface EuiAvatarSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Full name of the user or space. Used as the accessible label and the
     * hover title, for the initials and to pick a background color.
     */
    name?: string;
    /**
     * Background color as a hex value (`'#DA8B45'`), `'plain'` (the page's
     * background color), `'subdued'` (a light gray), or `null` (the default
     * gray). Defaults to one of the theme's visualization colors, picked
     * from `@name`; the text color is chosen for contrast.
     */
    color?: string | null;
    /**
     * Color of the `@iconType` icon, any `EuiIcon` color. Defaults to the
     * text color picked for the background; `null` keeps the icon's own
     * colors (for multi-color logos).
     */
    iconColor?: string | null;
    /**
     * Size of the `@iconType` icon. Defaults to `@size`.
     */
    iconSize?: EuiIconSignature['Args']['size'];
    /**
     * Shows an icon instead of initials, e.g. `'logoElastic'` for a space.
     * Anything `EuiIcon`'s `@type` accepts.
     */
    iconType?: EuiIconSignature['Args']['type'];
    /**
     * Image shown as the avatar (as a background image), instead of initials.
     */
    imageUrl?: string;
    /**
     * Custom initials (max 2 characters) instead of the ones computed from
     * `@name`.
     */
    initials?: string;
    /**
     * Greys the avatar out and hides it from assistive technology.
     */
    isDisabled?: boolean;
    /**
     * `'s'` (24px), `'m'` (32px), `'l'` (40px) or `'xl'` (64px). Defaults
     * to `'m'`.
     */
    size?: EuiAvatarSize;
    /**
     * `'user'` renders a circle, `'space'` a rounded square.
     * Defaults to `'user'`.
     */
    type?: EuiAvatarType;
    /**
     * Text transform of the initials: `'capitalize'`, `'uppercase'`,
     * `'lowercase'` or `'none'`. Defaults to `'uppercase'` for users and
     * `'none'` for spaces.
     */
    casing?: EuiAvatarCasing;
    /**
     * Number of initials to compute from `@name`, `1` or `2`. Defaults to
     * the number of words in the name, up to 2.
     */
    initialsLength?: 1 | 2;
    /** Same as `@initialsLength` (the former name). */
    initialLength?: 1 | 2;
  };
}

/** Native Ember avatar using the upstream EUI 123 / Borealis styles. */
export default class EuiAvatar extends Component<EuiAvatarSignature> {
  get context() {
    return getEuiThemeContext(this);
  }

  get type(): EuiAvatarType {
    return oneOf(TYPES, this.args.type, 'user');
  }

  get initials(): string | null {
    const { initials } = this.args;

    if (initials && initials.length > 2) {
      warn(
        'EuiAvatar only accepts a max of 2 characters for the initials as a string. It is displaying only the first 2 characters.',
        { id: 'EuiAvatar-initials-excedeed' }
      );
    }

    return toInitials(
      this.args.name ?? '',
      this.args.initialsLength ?? this.args.initialLength,
      initials
    );
  }

  /**
   * Upstream `avatarStyle`: the image, or a background color (by default a
   * visualization color picked from the name) with a contrasting text color.
   */
  get avatarStyle(): { backgroundImage?: string; backgroundColor?: string; color?: string } | undefined {
    const { color, imageUrl } = this.args;

    if (imageUrl) return { backgroundImage: `url(${imageUrl})` };

    if (color === 'plain' || color === 'subdued' || color === null) {
      return undefined;
    }

    if (color && !isValidHex(color)) {
      warn(
        'EuiAvatar needs to pass a valid color. This can either be a three or six character hex value',
        false,
        { id: 'EuiAvatar-invalid-color' }
      );
    }

    const vis = this.context.upstream.euiTheme.colors.vis as unknown as Record<
      string,
      string
    >;
    const name = this.args.name ?? '';
    const assignedColor =
      color || (vis[`euiColorVis${Math.floor(name.length % 10)}`] as string);
    const textColor = isColorDark(...hexToRgb(assignedColor))
      ? '#FFFFFF'
      : '#000000';

    return { backgroundColor: assignedColor, color: textColor };
  }

  get isForcedColors(): boolean {
    return this.context.upstream.highContrastMode === 'forced';
  }

  get classes(): string {
    const context = this.context;
    const styles = useEuiBorealisStyles(
      context,
      euiAvatarStyles as unknown as (
        ...args: Parameters<typeof euiAvatarStyles>
      ) => AvatarStyles
    );
    const type = this.type;
    const size = oneOf(SIZES, this.args.size, 'm');
    const casing = oneOf(
      CASING,
      this.args.casing,
      type === 'space' ? 'none' : 'uppercase'
    );
    const { color, isDisabled } = this.args;
    // The React global reset makes every element border-box; without it the
    // forced-colors border would grow the avatar.
    const reset: CSSObject = { boxSizing: 'border-box' };
    // Upstream sets these inline; a class keeps the caller's `style` intact.
    const avatarStyle = this.avatarStyle as CSSObject | undefined;
    // Background colors are ignored in Windows forced-colors themes.
    const highContrastBorder: CSSObject | undefined = this.isForcedColors
      ? { border: context.upstream.euiTheme.border.thin }
      : undefined;

    return `euiAvatar ${euiClass(
      context,
      reset,
      styles['euiAvatar'],
      styles[type],
      styles[size],
      styles[casing],
      color === 'plain' && styles['plain'],
      color === 'subdued' && styles['subdued'],
      isDisabled && styles['isDisabled'],
      avatarStyle,
      highContrastBorder
    )}`;
  }

  get iconSize(): EuiIconSignature['Args']['size'] {
    return this.args.iconSize ?? oneOf(SIZES, this.args.size, 'm');
  }

  /** Upstream `iconCustomColor`. */
  get iconColor(): string | undefined {
    if (this.isForcedColors) {
      return this.context.upstream.euiTheme.colors.fullShade;
    }

    const { iconColor } = this.args;

    if (iconColor === null) return undefined;
    if (iconColor) return iconColor;

    return this.avatarStyle?.color;
  }

  <template>
    <div
      class={{this.classes}}
      aria-label={{if @isDisabled undefined @name}}
      title={{@name}}
      role={{if @isDisabled "presentation" "img"}}
      ...attributes
    >
      {{#unless @imageUrl}}
        {{#if @iconType}}
          <EuiIcon
            @iconClasses="euiAvatar__icon"
            @size={{this.iconSize}}
            @type={{@iconType}}
            @color={{this.iconColor}}
            aria-hidden="true"
          />
        {{else}}
          <span aria-hidden="true">{{this.initials}}</span>
        {{/if}}
      {{/unless}}
    </div>
  </template>
}
