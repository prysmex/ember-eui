import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { eq } from 'ember-truth-helpers';
import style from 'ember-style-modifier/modifiers/style';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiTextColorStyles } from '../utils/eui/styles.generated.ts';

import type { CSSInterpolation } from '@emotion/css/create-instance';
import type { EuiThemeContext } from '../utils/emotion/context.ts';

/** Latest upstream named colors. */
export const TEXT_COLORS = [
  'default',
  'subdued',
  'success',
  'accent',
  'accentSecondary',
  'danger',
  'warning',
  'ghost',
  'inherit'
] as const;

/**
 * A named color, the Ember-only `'primary'`, or any CSS color value
 * (`'#c0ffee'`, `'rgb(…)'`, `'currentColor'`…).
 */
export type EuiTextColorValue =
  | (typeof TEXT_COLORS)[number]
  | 'primary'
  | (string & {});

function isNamedColor(color: string): color is (typeof TEXT_COLORS)[number] {
  return (TEXT_COLORS as readonly string[]).includes(color);
}

/** @private Shared with EuiText, which composes color on its own element. */
export function euiTextColorCss(
  context: EuiThemeContext,
  color: EuiTextColorValue = 'default'
): CSSInterpolation[] {
  const styles = useEuiBorealisStyles(context, euiTextColorStyles);
  if (isNamedColor(color)) return [styles.euiTextColor, styles[color]];
  // Upstream dropped `primary`; keep it working with the native text token.
  if (color === 'primary')
    return [
      styles.euiTextColor,
      { color: context.upstream.euiTheme.colors.textPrimary }
    ];
  // The custom value itself goes inline (`euiTextColorInlineStyle`), as
  // upstream does: a class per color would stay in the style cache for good.
  return [styles.euiTextColor, styles.customColor];
}

/**
 * @private Upstream's inline `style` for a custom (non-named) color, for the
 * `{{style}}` modifier. Empty for named colors.
 */
export function euiTextColorInlineStyle(
  color: EuiTextColorValue | undefined
): Record<string, string> {
  if (!color || isNamedColor(color) || color === 'primary') return {};
  return { color };
}

/** Colors its text content. */
export interface EuiTextColorSignature {
  Element: HTMLSpanElement | HTMLDivElement | HTMLParagraphElement;
  Args: {
    /**
     * `'default'`, `'subdued'`, `'success'`, `'accent'`, `'accentSecondary'`,
     * `'danger'`, `'warning'`, `'ghost'`, `'inherit'`, `'primary'`, or any
     * CSS color value. Defaults to `'default'`.
     */
    color?: EuiTextColorValue;
    /** `'span'` (inline), `'div'` or `'p'`. Defaults to `'span'`. */
    tagName?: 'span' | 'div' | 'p';
  };
  Blocks: {
    /** The content. */
    default: [];
  };
}

export default class EuiTextColor extends Component<EuiTextColorSignature> {
  get inlineStyle(): Record<string, string> {
    return euiTextColorInlineStyle(this.args.color);
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    return euiClass(
      context,
      // React's global reset removes paragraph margins; Ember has no reset.
      this.args.tagName === 'p' ? { margin: 0 } : undefined,
      ...euiTextColorCss(context, this.args.color)
    );
  }

  <template>
    {{#if (eq @tagName "div")}}
      <div class="euiTextColor {{this.classes}}" ...attributes {{style this.inlineStyle}}>
        {{yield}}
      </div>
    {{else if (eq @tagName "p")}}
      <p class="euiTextColor {{this.classes}}" ...attributes {{style this.inlineStyle}}>
        {{yield}}
      </p>
    {{else}}
      <span class="euiTextColor {{this.classes}}" ...attributes {{style this.inlineStyle}}>
        {{yield}}
      </span>
    {{/if}}
  </template>
}
