import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import style from 'ember-style-modifier/modifiers/style';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import { euiTextStyles } from '../utils/eui/styles.generated.ts';
import { euiTextAlignCss } from './eui-text-align.gts';
import { euiTextColorCss, euiTextColorInlineStyle } from './eui-text-color.gts';

import type { CSSObject } from '@emotion/css/create-instance';
import type { EuiBorealisContext } from '../utils/eui/theme.ts';
import type { EuiTextAlignment } from './eui-text-align.gts';
import type { EuiTextColorValue } from './eui-text-color.gts';

/**
 * The parts of React EUI's global reset that EuiText content relies on,
 * scoped to descendants. `:where()` keeps them below every upstream rule.
 */
export function euiTextReset({ euiTheme }: EuiBorealisContext): CSSObject {
  return {
    boxSizing: 'border-box',
    margin: 0,
    fontFamily: euiTheme.font.family,
    '& :where(*, *::before, *::after)': { boxSizing: 'border-box' },
    '& :where(h1, h2, h3, h4, h5, h6, p, blockquote, pre, dl, dt, dd, ol, ul, li, figure)':
      { margin: 0, padding: 0 },
    '& :where(h1, h2, h3, h4, h5, h6, p)': {
      fontFamily: 'inherit',
      fontWeight: 'inherit',
      fontSize: 'inherit'
    },
    '& :where(code, pre, kbd, samp)': { fontFamily: euiTheme.font.familyCode },
    '& :where(strong)': { fontWeight: euiTheme.font.weight.bold },
    '& :where(em)': { fontStyle: 'italic' },
    '& :where(blockquote, q)': { quotes: 'none' }
  };
}

/** Styles plain HTML content (`<p>`, `<ul>`, `<h3>`, `<code>`…) with EUI's typography. */
export interface EuiTextSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * The element to render: a tag name such as `'span'` or `'p'`
     * (upstream's `component`). Defaults to `'div'`.
     */
    component?: string;
    /**
     * `true` lets text span the container's full width; `false` caps lines
     * at a readable width. Defaults to `true`.
     */
    grow?: boolean;
    /** `'xs'`, `'s'`, `'m'` or `'relative'` (inherits). Defaults to `'s'`. */
    size?: 'xs' | 's' | 'm' | 'relative';
    /** `'left'`, `'center'` or `'right'` (logical, so they flip in RTL). */
    textAlign?: EuiTextAlignment;
    /**
     * Any EuiTextColor value: a named color such as `'subdued'` or
     * `'danger'`, or a CSS color. Inherits when omitted.
     */
    color?: EuiTextColorValue;
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop). Prefer this to an extra class when styling it from a parent.
     */
    css?: EuiCss;
  };
  Blocks: {
    /** HTML content (paragraphs, lists, headings, code…), styled by EuiText. */
    default: [];
  };
}

/**
 * The tag to render. Typed as `'div'` (the default) so that callers keep
 * `HTMLDivElement` attributes; `@component` may name any element.
 */
function tagName(component: string | undefined): 'div' {
  return (component || 'div') as 'div';
}

export default class EuiText extends Component<EuiTextSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTextStyles);
    const { color, textAlign } = this.args;
    // Same order as upstream's cloned element: text, then color, then align.
    return euiClass(
      context,
      euiTextReset(context.upstream),
      styles.euiText,
      this.args.grow === false ? styles.constrainedWidth : undefined,
      styles[this.args.size ?? 's'],
      color ? euiTextColorCss(context, color) : undefined,
      textAlign ? euiTextAlignCss(textAlign) : undefined,
      this.args.css
    );
  }

  <template>
    {{#let (element (tagName @component)) as |Tag|}}
      <Tag class="euiText {{this.classes}}" ...attributes {{style (euiTextColorInlineStyle @color)}}>{{yield}}</Tag>
    {{/let}}
  </template>
}
