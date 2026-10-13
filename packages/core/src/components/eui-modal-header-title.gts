import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiTitleStyles } from '../utils/eui/styles.generated.ts';

/**
 * React's global reset makes headings inside the title inherit its font;
 * `:where()` keeps a nested EuiTitle's own styles in charge.
 */
const NESTED_HEADING_RESET = {
  '& :where(h1, h2, h3, h4, h5, h6, p)': {
    margin: 0,
    padding: 0,
    fontFamily: 'inherit',
    fontSize: 'inherit',
    fontWeight: 'inherit',
    lineHeight: 'inherit',
    letterSpacing: 'inherit',
    color: 'inherit'
  }
};

/**
 * The title of an EuiModal, styled like upstream's `EuiTitle size="m"`.
 * EuiModal is labelled by it unless you give the modal an `aria-label` or
 * `aria-labelledby`.
 */
export interface EuiModalHeaderTitleSignature {
  Element: Element;
  Args: {
    /**
     * Upstream's `component`: the tag to render instead of the wrapping
     * `<div>`, e.g. `'h1'` or `'h2'`, so the text goes straight inside and
     * no heading needs nesting. Defaults to `'div'`.
     */
    tagName?: string;
    /** `'xxxs'`, `'xxs'`, `'xs'`, `'s'`, `'m'` or `'l'`. Defaults to `'m'`. */
    size?: 'xxxs' | 'xxs' | 'xs' | 's' | 'm' | 'l';
    /** `'uppercase'` for all caps. */
    textTransform?: 'uppercase';
  };
  Blocks: {
    /**
     * The title text. Wrap it in a heading (e.g. `<h1>`) for the page
     * outline; the heading inherits the title's styles.
     */
    default: [];
  };
}

export default class EuiModalHeaderTitle extends Component<EuiModalHeaderTitleSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTitleStyles);
    return `euiTitle euiModalHeader__title ${euiClass(
      context,
      {
        boxSizing: 'border-box',
        margin: 0,
        padding: 0,
        fontFamily: context.upstream.euiTheme.font.family
      },
      styles.euiTitle,
      this.args.textTransform ? styles[this.args.textTransform] : undefined,
      styles[this.args.size ?? 'm'],
      NESTED_HEADING_RESET
    )}`;
  }

  <template>
    {{#let (element (if @tagName @tagName "div")) as |Tag|}}
      <Tag class={{this.classes}} ...attributes>
        {{yield}}
      </Tag>
    {{/let}}
  </template>
}
