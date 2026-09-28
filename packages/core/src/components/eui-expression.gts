import { hash } from '@ember/helper';
import { on } from '@ember/modifier';

import { element } from 'ember-element-helper';

import cssStyle from '../-private/css-style.ts';
import EuiIcon from './eui-icon.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

const COLORS = {
  subdued: 'euiExpression--subdued',
  primary: 'euiExpression--primary',
  success: 'euiExpression--success',
  accent: 'euiExpression--accent',
  warning: 'euiExpression--warning',
  danger: 'euiExpression--danger'
};

/**
 * One part of a sentence-like query or rule, e.g. **WHEN** `avg()` or
 * **IS ABOVE** `100`: a description and a value. With `@onClick` it is a
 * button, usually opening a popover to edit the value.
 */
export interface EuiExpressionSignature {
  Element: HTMLButtonElement | HTMLSpanElement;
  Args: {
    /** First part, e.g. "when". Use the `<:description>` block for markup. */
    description?: string;
    /** Second part, e.g. "avg()". Use the `<:value>` block for markup. */
    value?: string;
    /**
     * Color of the description: `'subdued'`, `'primary'`, `'success'`,
     * `'accent'`, `'warning'` or `'danger'`. Defaults to `'success'`.
     */
    color?: 'subdued' | 'primary' | 'success' | 'accent' | 'warning' | 'danger';
    /** Uppercases the description. Defaults to `true`. */
    uppercase?: boolean;
    /** Solid underline, e.g. while its popover is open. */
    isActive?: boolean;
    /** Shows it in danger color with an alert icon. */
    isInvalid?: boolean;
    /** Makes it a `<button>` with a dashed underline. */
    onClick?: (event: MouseEvent) => void;
    /**
     * `'inline'` (in a sentence) or `'columns'` (description and value in
     * two columns, to stack several). Defaults to `'inline'`.
     */
    display?: 'inline' | 'columns';
    /** Width of the description in columns display. Defaults to `'20%'`. */
    descriptionWidth?: number | string;
    /** `'break-word'` or `'truncate'` long values. Defaults to `'break-word'`. */
    textWrap?: 'break-word' | 'truncate';
  };
  Blocks: {
    /** Markup for the description, instead of `@description`. */
    description: [];
    /** Markup for the value, instead of `@value`. */
    value: [];
  };
}

function classes(
  color: keyof typeof COLORS = 'success',
  isInvalid?: boolean,
  isActive?: boolean,
  clickable?: boolean,
  uppercase = true,
  display?: string,
  textWrap?: string
): string {
  return [
    'euiExpression',
    isActive && 'euiExpression-isActive',
    clickable && 'euiExpression-isClickable',
    uppercase && 'euiExpression-isUppercase',
    display === 'columns' && 'euiExpression--columns',
    COLORS[isInvalid ? 'danger' : color],
    textWrap === 'truncate' && 'euiExpression--truncate'
  ]
    .filter(Boolean)
    .join(' ');
}

function noop(): void {}

const EuiExpression: TemplateOnlyComponent<EuiExpressionSignature> = <template>
  {{#let (element (if @onClick "button" "span")) as |Tag|}}
    <Tag
      class={{classes
        @color
        @isInvalid
        @isActive
        (if @onClick true false)
        @uppercase
        @display
        @textWrap
      }}
      type={{if @onClick "button"}}
      {{on "click" (if @onClick @onClick noop)}}
      ...attributes
    >
      <span
        class="euiExpression__description"
        style={{if
          (isColumns @display)
          (cssStyle
            (hash flexBasis=(if @descriptionWidth @descriptionWidth "20%"))
          )
        }}
      >
        {{~#if (has-block "description")~}}
          {{yield to="description"}}
        {{~else~}}
          {{@description}}
        {{~/if~}}
      </span>
      {{#if (has-block "value")}}
        <span class="euiExpression__value">{{yield to="value"}}</span>
      {{else if @value}}
        <span class="euiExpression__value">{{@value}}</span>
      {{/if}}
      {{#if @isInvalid}}
        <EuiIcon class="euiExpression__icon" @type="alert" @color="danger" />
      {{/if}}
    </Tag>
  {{/let}}
</template>;

function isColumns(display?: string): boolean {
  return display === 'columns';
}

export default EuiExpression;
