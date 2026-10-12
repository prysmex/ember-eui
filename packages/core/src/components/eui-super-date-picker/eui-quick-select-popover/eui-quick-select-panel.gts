import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../../../utils/emotion/consume.ts';
import { fieldsetReset, legendReset } from '../../../utils/eui/date-pickers.ts';
import {
  euiQuickSelectPanelStyles,
  euiTitleStyles
} from '../../../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../../../utils/eui/styles.ts';

import type { EuiCss } from '../../../utils/eui/styles.ts';

/**
 * @private A section of the quick select popover (upstream
 * `EuiQuickSelectPanel`): a top border and spacing between panels, an
 * optional `xxxs` title (a `<legend>` when rendered as a fieldset) and a
 * scrollable section for the content.
 */
export interface EuiQuickSelectPanelSignature {
  // A `<fieldset>` (or a `<div>` with `@tagName="div"`, which no caller
  // passes attributes to).
  Element: HTMLFieldSetElement;
  Args: {
    /** `'div'` (default) or `'fieldset'`. */
    tagName?: 'div' | 'fieldset';
    /** Panel title; the content then goes in a scrollable section. */
    title?: string;
    /** Id of the title, e.g. for `aria-labelledby`. */
    titleId?: string;
    /** Extra styles composed last onto the panel's class. */
    css?: EuiCss;
  };
  Blocks: {
    default: [];
  };
}

export default class EuiQuickSelectPanel extends Component<EuiQuickSelectPanelSignature> {
  get context() {
    return getEuiThemeContext(this);
  }

  get tagName() {
    return this.args.tagName ?? 'div';
  }

  get isFieldset() {
    return this.tagName === 'fieldset';
  }

  get hasTitle() {
    return this.args.title !== undefined && this.args.title !== '';
  }

  @cached
  get styles() {
    return useEuiBorealisStyles(this.context, euiQuickSelectPanelStyles);
  }

  @cached
  get classes() {
    return `euiQuickSelectPanel ${euiClass(
      this.context,
      this.isFieldset && fieldsetReset,
      { boxSizing: 'border-box' },
      this.styles.euiQuickSelectPanel,
      this.args.css
    )}`;
  }

  /**
   * Upstream clones the title element into `EuiTitle size="xxxs"`, so the
   * title styles, the heading reset and the panel title styles share one
   * class here.
   */
  @cached
  get titleClasses() {
    const context = this.context;
    const title = useEuiBorealisStyles(context, euiTitleStyles);
    return `euiTitle euiQuickSelectPanel__title ${euiClass(
      context,
      legendReset,
      { fontFamily: context.upstream.euiTheme.font.family },
      title.euiTitle,
      title.xxxs,
      this.styles.euiQuickSelectPanel__title
    )}`;
  }

  @cached
  get sectionClasses() {
    return `euiQuickSelectPanel__section ${euiClass(
      this.context,
      { boxSizing: 'border-box' },
      this.styles.euiQuickSelectPanel__section
    )}`;
  }

  <template>
    {{#let (element this.tagName) as |Tag|}}
      {{! @glint-expect-error: the dynamic tag is a div or a fieldset }}
      <Tag class={{this.classes}} ...attributes>
        {{#if this.hasTitle}}
          {{#if this.isFieldset}}
            <legend id={{@titleId}} class={{this.titleClasses}}>{{@title}}</legend>
          {{else}}
            <span id={{@titleId}} class={{this.titleClasses}}>{{@title}}</span>
          {{/if}}
          <div class={{this.sectionClasses}}>
            {{yield}}
          </div>
        {{else}}
          {{yield}}
        {{/if}}
      </Tag>
    {{/let}}
  </template>
}
