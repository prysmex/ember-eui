import cssStyle from '../-private/css-style.ts';
import { hexToRgb } from '../helpers/hex-to-rgb.ts';
import { isColorDark } from '../helpers/is-color-dark.ts';
import { TOKEN_MAP } from '../utils/token-map.ts';
import EuiIcon from './eui-icon.gts';

import type { CssProperties } from '../-private/css-style.ts';
import type { IconType } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

const SIZES = {
  xs: 'euiToken--xsmall',
  s: 'euiToken--small',
  m: 'euiToken--medium',
  l: 'euiToken--large'
};

const SHAPES = {
  circle: 'euiToken--circle',
  square: 'euiToken--square',
  rectangle: 'euiToken--rectangle'
};

const FILLS = {
  none: null,
  light: 'euiToken--light',
  dark: 'euiToken--dark'
};

const COLORS = [
  'euiColorVis0',
  'euiColorVis1',
  'euiColorVis2',
  'euiColorVis3',
  'euiColorVis4',
  'euiColorVis5',
  'euiColorVis6',
  'euiColorVis7',
  'euiColorVis8',
  'euiColorVis9',
  'gray'
] as const;

type TokenSize = keyof typeof SIZES;

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
    shape?: 'circle' | 'square' | 'rectangle';
    /**
     * `'light'` (tinted with a border), `'dark'` (solid) or `'none'`.
     * Defaults to the token icon's, or `'light'`.
     */
    fill?: 'light' | 'dark' | 'none';
    /** `'xs'`, `'s'`, `'m'` or `'l'`. Defaults to `'s'`. */
    size?: 'xs' | 's' | 'm' | 'l';
    /** Title of the icon, read by screen readers, e.g. "String field". */
    title?: string;
  };
}

interface Display {
  classes: string;
  style: ReturnType<typeof cssStyle>;
  iconSize: 's' | 'm' | 'l';
}

function display(
  iconType: IconType,
  color: string | undefined,
  shape: keyof typeof SHAPES | undefined,
  fill: keyof typeof FILLS | undefined,
  size: TokenSize = 's'
): Display {
  const preset = typeof iconType === 'string' ? TOKEN_MAP[iconType] : undefined;
  const finalColor = color ?? preset?.color ?? 'gray';
  const finalShape = shape ?? preset?.shape ?? 'circle';
  let finalFill = fill ?? preset?.fill ?? 'light';
  const style: CssProperties = {};
  let colorClass: string | undefined;

  if ((COLORS as readonly string[]).includes(finalColor)) {
    colorClass = `euiToken--${finalColor}`;
  } else if (finalFill === 'none') {
    style['color'] = finalColor;
  } else {
    finalFill = 'dark';
    style['backgroundColor'] = finalColor;
    style['color'] = isColorDark(...hexToRgb(finalColor)) ? '#FFFFFF' : '#000000';
  }

  // token icons look best one size up at the small size; icons have no xs
  const isTokenIcon = typeof iconType === 'string' && iconType.startsWith('token');
  const iconSize = size === 'xs' ? 's' : isTokenIcon && size === 's' ? 'm' : size;

  return {
    classes: [
      'euiToken',
      colorClass,
      SHAPES[finalShape],
      FILLS[finalFill],
      SIZES[size]
    ]
      .filter(Boolean)
      .join(' '),
    style: cssStyle(style),
    iconSize
  };
}

const EuiToken: TemplateOnlyComponent<EuiTokenSignature> = <template>
  {{#let (display @iconType @color @shape @fill @size) as |token|}}
    <span class={{token.classes}} style={{token.style}} ...attributes>
      <EuiIcon @type={{@iconType}} @size={{token.iconSize}} @title={{@title}} />
    </span>
  {{/let}}
</template>;

export default EuiToken;
