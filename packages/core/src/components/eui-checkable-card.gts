import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { concat } from '@ember/helper';
import { on } from '@ember/modifier';

import { eq } from 'ember-truth-helpers';

import { randomId } from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiCheckableCardStyles,
  euiPanelStyles
} from '../utils/eui/styles.generated.ts';
import EuiCheckbox from './eui-checkbox.gts';
import EuiRadio from './eui-radio.gts';
import EuiSplitPanelInner from './eui-split-panel/inner.gts';
import EuiSplitPanelOuter from './eui-split-panel/outer.gts';

import type { EuiCss } from '../utils/eui/styles.ts';
import type { EuiCheckboxSignature } from './eui-checkbox';

/**
 * Attributes and modifiers (`name`, `value`, `{{on "change" …}}`) go to the
 * radio or checkbox input.
 */
export interface EuiCheckableCardSignature {
  Element: EuiCheckboxSignature['Element'];
  Args: {
    /** Id of the input, linked to the label. Defaults to a random id. */
    id?: string;
    /** The card's label. Use the `<:label>` block for markup. */
    label?: string;
    /** Whether the card's radio or checkbox is checked. */
    checked?: boolean;
    /** Disables the input and greys the label out. */
    disabled?: boolean;
    /**
     * `'radio'` for picking one card of a group (give them the same `name`),
     * `'checkbox'` for independent cards. Defaults to `'radio'`.
     */
    checkableType?: 'checkbox' | 'radio';
    /** Border around the card (primary while checked). Defaults to `true`. */
    hasBorder?: boolean;
    /** Shadow, only shown without a border. Defaults to `false`. */
    hasShadow?: boolean;
    /** Extra styles composed last into the card's class. */
    css?: EuiCss;
  };
  Blocks: {
    /** Unused, use `<:label>` and `<:content>`. */
    default: [];
    /** The label, instead of `@label`. */
    label: [];
    /**
     * Details below the label, linked to the input with `aria-describedby`.
     * Clicking it toggles the input unless it contains interactive elements.
     */
    content: [];
  };
}

/** Elements that handle their own clicks inside the card's details. */
const INTERACTIVE =
  'a[href], button, input, select, textarea, label, summary, [contenteditable], [tabindex]:not([tabindex="-1"])';

function cardLabel(element: Element): HTMLLabelElement | null {
  return (
    element
      .closest('.euiCheckableCard')
      ?.querySelector<HTMLLabelElement>('label.euiCheckableCard__label') ??
    null
  );
}

/**
 * Upstream `EuiCheckableCard` (EUI 123.1.0): a row `EuiSplitPanel` whose
 * first section holds the radio or checkbox and whose second holds the
 * label. Clicking the control's section, or details without interactive
 * content, clicks the label.
 */
export default class EuiCheckableCard extends Component<EuiCheckableCardSignature> {
  fallbackId = randomId();

  get id(): string {
    return this.args.id ?? this.fallbackId;
  }

  get context() {
    return getEuiThemeContext(this);
  }

  @cached
  get css(): EuiCss {
    const styles = useEuiBorealisStyles(this.context, euiCheckableCardStyles);
    return [
      styles.euiCheckableCard,
      this.args.checked && !this.args.disabled && styles.isChecked,
      this.args.css
    ];
  }

  /** Upstream renders the control's section as a clickable EuiPanel. */
  @cached
  get controlCss(): EuiCss {
    return this.args.disabled
      ? undefined
      : useEuiBorealisStyles(this.context, euiPanelStyles).isClickable;
  }

  @cached
  get labelClass(): string {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiCheckableCardStyles);
    return euiClass(
      context,
      { boxSizing: 'border-box', font: 'inherit' },
      styles.label.euiCheckableCard__label,
      this.args.disabled && styles.label.isDisabled
    );
  }

  @cached
  get childrenClass(): string {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiCheckableCardStyles);
    return euiClass(
      context,
      styles.euiCheckableCard__children,
      // Upstream sets an inline `cursor: pointer` when the details have no
      // tabbable content; `:has()` keeps that in sync with the block.
      !this.args.disabled && {
        cursor: 'pointer',
        [`&:has(${INTERACTIVE})`]: { cursor: 'auto' }
      }
    );
  }

  onControlClick = (event: MouseEvent): void => {
    if (this.args.disabled) return;
    const target = event.target as Element;
    if (target instanceof HTMLInputElement) return;
    cardLabel(event.currentTarget as Element)?.click();
  };

  onChildrenClick = (event: MouseEvent): void => {
    if (this.args.disabled) return;
    const details = event.currentTarget as Element;
    if (details.querySelector(INTERACTIVE)) return;
    cardLabel(details)?.click();
  };

  <template>
    <EuiSplitPanelOuter
      class="euiCheckableCard"
      @direction="row"
      @responsive={{false}}
      @hasShadow={{@hasShadow}}
      @hasBorder={{argOrDefault @hasBorder true}}
      @css={{this.css}}
    >
      <EuiSplitPanelInner
        @color={{if @checked "primary" "subdued"}}
        @grow={{false}}
        @css={{this.controlCss}}
        {{on "click" this.onControlClick}}
      >
        {{#if (eq @checkableType "checkbox")}}
          <EuiCheckbox
            @id={{this.id}}
            @checked={{@checked}}
            @disabled={{@disabled}}
            ...attributes
          />
        {{else}}
          <EuiRadio
            @id={{this.id}}
            @checked={{@checked}}
            @disabled={{@disabled}}
            ...attributes
          />
        {{/if}}
      </EuiSplitPanelInner>
      <EuiSplitPanelInner>
        <label
          class="euiCheckableCard__label {{this.labelClass}}"
          for={{this.id}}
          aria-describedby={{if
            (has-block "content")
            (concat this.id "-details")
          }}
        >
          {{#if (has-block "label")}}
            {{yield to="label"}}
          {{else}}
            {{@label}}
          {{/if}}
        </label>
        {{#if (has-block "content")}}
          {{! template-lint-disable no-invalid-interactive }}
          <div
            id={{concat this.id "-details"}}
            class="euiCheckableCard__children {{this.childrenClass}}"
            {{on "click" this.onChildrenClick}}
          >
            {{yield to="content"}}
          </div>
        {{/if}}
      </EuiSplitPanelInner>
    </EuiSplitPanelOuter>
  </template>
}
