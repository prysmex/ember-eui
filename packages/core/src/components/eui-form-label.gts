import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { eq } from 'ember-truth-helpers';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiFormLabelStyles } from '../utils/eui/styles.generated.ts';

import type { CSSObject } from '@emotion/css/create-instance';
import type { EuiBorealisContext } from '../utils/eui/theme.ts';

/**
 * React's global reset zeroes `<label>`/`<legend>` boxes and its global
 * styles set the body font; Ember has neither, so scope them here.
 */
export function euiFormLabelReset({ euiTheme }: EuiBorealisContext): CSSObject {
  return {
    boxSizing: 'border-box',
    margin: 0,
    padding: 0,
    border: 'none',
    fontFamily: euiTheme.font.family
  };
}

/** The label of a control; EuiFormRow renders it from `@label`. */
export interface EuiFormLabelSignature {
  Element: HTMLLabelElement | HTMLLegendElement;
  Args: {
    /**
     * The control has focus. Adds the `euiFormLabel-isFocused` class; the
     * latest theme no longer recolors focused labels.
     */
    isFocused?: boolean;
    /** Invalid styling (danger text color). */
    isInvalid?: boolean;
    /** Disabled: drops the pointer cursor of a `for` label. */
    isDisabled?: boolean;
    /**
     * `'label'` renders a `<label>`, `'legend'` a `<legend>` (for fieldsets).
     * Defaults to `'label'`.
     */
    type?: 'legend' | 'label';
    /** Id of the control it labels. */
    for?: string;
    /** The label text, before the block content. */
    label?: string;
  };
  Blocks: {
    /** The label text. */
    default: [];
  };
}

export default class EuiFormLabel extends Component<EuiFormLabelSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFormLabelStyles);
    const { isDisabled, isFocused, isInvalid } = this.args;
    // Same order as upstream's `cssStyles`.
    const css = euiClass(
      context,
      euiFormLabelReset(context.upstream),
      styles.euiFormLabel,
      isDisabled ? undefined : styles.notDisabled,
      isInvalid ? styles.invalid : undefined
    );
    // Upstream state classes, kept for callers and tests.
    return [
      'euiFormLabel',
      isFocused && 'euiFormLabel-isFocused',
      isInvalid && 'euiFormLabel-isInvalid',
      isDisabled && 'euiFormLabel-isDisabled',
      css
    ]
      .filter(Boolean)
      .join(' ');
  }

  <template>
    {{#if (eq @type "legend")}}
      <legend class={{this.classes}} ...attributes>
        {{@label}}
        {{yield}}
      </legend>
    {{else}}
      <label class={{this.classes}} for={{@for}} ...attributes>
        {{@label}}
        {{yield}}
      </label>
    {{/if}}
  </template>
}
