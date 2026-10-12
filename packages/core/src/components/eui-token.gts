import Component from '@glimmer/component';

import { hexToRgb } from '../helpers/hex-to-rgb.ts';
import { isColorDark } from '../helpers/is-color-dark.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass } from '../utils/eui/styles.ts';
import { TOKEN_MAP } from '../utils/eui/styles.generated.ts';
import { euiTokenStyles, TOKEN_COLORS } from '../utils/eui/token.ts';
import EuiIcon from './eui-icon.gts';

import type { CSSObject } from '@emotion/css/create-instance';
import type { EuiTokenFill } from '../utils/eui/token.ts';
import type { IconType } from './eui-icon';

export const SIZES = ['xs', 's', 'm', 'l'] as const;
export const SHAPES = ['circle', 'square', 'rectangle'] as const;
export const FILLS = ['light', 'dark', 'none'] as const;
export { TOKEN_COLORS as COLORS };

type TokenSize = (typeof SIZES)[number];
type TokenShape = (typeof SHAPES)[number];

const TOKEN_DEFAULTS = TOKEN_MAP as Record<
  string,
  { shape?: TokenShape; color?: string }
>;

/**
 * Icons this addon still ships under their pre-rename names, mapped to the
 * upstream 123 token they became (so they keep a preset).
 */
const TOKEN_ALIASES: Record<string, string> = {
  tokenDenseVector: 'tokenVectorDense'
};

function oneOf<T extends string>(
  values: readonly T[],
  value: unknown,
  fallback: T
): T {
  return (values as readonly unknown[]).includes(value) ? (value as T) : fallback;
}

/**
 * A small icon in a colored shape that tells the type of a value or code
 * symbol, e.g. a field's type (string, number, date) in a list of fields.
 */
export interface EuiTokenSignature {
  Element: HTMLSpanElement;
  Args: {
    /**
     * The icon: one of EUI's `token*` icons (`'tokenString'`,
     * `'tokenNumber'`, `'tokenDate'`, …), which come with their own shape
     * and color, or any other `EuiIcon` type.
     */
    iconType: IconType;
    /**
     * `'euiColorVis0'` to `'euiColorVis9'`, `'gray'`, or a hex color (which
     * forces `@fill="dark"` unless `@fill="none"`). Defaults to the token
     * icon's color, or `'gray'`.
     */
    color?: string;
    /** `'circle'`, `'square'` or `'rectangle'`. Defaults to the token icon's, or `'circle'`. */
    shape?: TokenShape;
    /**
     * `'light'` (tinted with a border), `'dark'` (solid) or `'none'`.
     * Defaults to `'light'`.
     */
    fill?: EuiTokenFill;
    /** `'xs'` (8px), `'s'` (16px), `'m'` (24px) or `'l'` (32px). Defaults to `'s'`. */
    size?: TokenSize;
    /** Title of the icon, read by screen readers, e.g. "String field". */
    title?: string;
    /** Accessible label of the icon, instead of `@title`. */
    'aria-label'?: string;
    /** Id(s) of the element(s) labelling the icon. */
    'aria-labelledby'?: string;
    /** Id(s) of the element(s) describing the icon. */
    'aria-describedby'?: string;
  };
}

/** Native Ember token using the upstream EUI 123 / Borealis styles. */
export default class EuiToken extends Component<EuiTokenSignature> {
  get size(): TokenSize {
    return oneOf(SIZES, this.args.size, 's');
  }

  /** Icons have no `xs`, and token icons look best one size up at `s`. */
  get iconSize(): 's' | 'm' | 'l' {
    const { iconType } = this.args;
    const size = this.size;

    if (size === 'xs') return 's';
    if (typeof iconType === 'string' && iconType.indexOf('token') === 0 && size === 's') {
      return 'm';
    }

    return size;
  }

  get classes(): string {
    const { iconType } = this.args;
    const context = getEuiThemeContext(this);
    const preset =
      typeof iconType === 'string'
        ? TOKEN_DEFAULTS[TOKEN_ALIASES[iconType] ?? iconType]
        : undefined;
    const color = this.args.color || preset?.color || 'gray';
    const shape = oneOf(SHAPES, this.args.shape || preset?.shape, 'circle');
    const fill = oneOf(FILLS, this.args.fill, 'light');
    // upstream builds the styles for the requested fill, before a custom
    // color switches the token to `dark`
    const styles = euiTokenStyles(context.upstream, fill);
    let custom: CSSObject | undefined;
    let colorStyles = styles[color];

    if (!(TOKEN_COLORS as readonly string[]).includes(color)) {
      colorStyles = styles['customColor'];
      // Upstream sets these inline; a class keeps the caller's `style`.
      custom =
        fill === 'none'
          ? { color }
          : {
              color: isColorDark(...hexToRgb(color)) ? '#FFFFFF' : '#000000',
              backgroundColor: color
            };
    }

    return `euiToken ${euiClass(
      context,
      styles['euiToken'],
      styles[shape],
      styles[fill],
      styles[this.size],
      colorStyles,
      custom
    )}`;
  }

  <template>
    <span class={{this.classes}} ...attributes>
      <EuiIcon
        @type={{@iconType}}
        @size={{this.iconSize}}
        @title={{@title}}
        @aria-label={{@aria-label}}
        @aria-labelledby={{@aria-labelledby}}
        aria-describedby={{@aria-describedby}}
      />
    </span>
  </template>
}
