import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';

import cssStyle from '../-private/css-style.ts';
import spreadAttributes from '../-private/eui-spread-attributes.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiExpressionDescriptionStyles,
  euiExpressionIconStyles,
  euiExpressionStyles,
  euiExpressionValueStyles
} from '../utils/eui/styles.generated.ts';
import EuiIcon from './eui-icon.gts';

import type { CssProperties } from '../-private/css-style.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import type { CSSInterpolation } from '@emotion/css/create-instance';

/**
 * Upstream `descriptionProps` / `valueProps`: props of the description or
 * value `<span>`.
 */
export interface EuiExpressionPartProps {
  /** Extra class of the span. */
  className?: string;
  /** Styles composed last into the span's class (upstream `css`). */
  css?: EuiCss;
  /** Inline styles, as an object (`{ fontStyle: 'italic' }`). */
  style?: CssProperties;
  /** Other keys (`id`, `aria-*`, `data-*`, …) become attributes of the span. */
  [attribute: string]: unknown;
}

/** Keys of a part's props that are not attributes. */
const PART_ARGS = ['style'] as const;

export const EXPRESSION_COLORS = [
  'subdued',
  'primary',
  'success',
  'accent',
  'warning',
  'danger'
] as const;

export type EuiExpressionColor = (typeof EXPRESSION_COLORS)[number];

/** Scoped button reset (no React global reset); upstream rules follow. */
const BUTTON_RESET = {
  boxSizing: 'border-box',
  margin: 0,
  border: 'none',
  background: 'none',
  fontSize: 'inherit'
} as const;

const SPAN_RESET = { boxSizing: 'border-box' } as const;

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
    /**
     * Props of the description `<span>` (upstream `descriptionProps`):
     * `className`, `css`, `style` (an object) and any attribute.
     */
    descriptionProps?: EuiExpressionPartProps;
    /** Props of the value `<span>` (upstream `valueProps`), see `@descriptionProps`. */
    valueProps?: EuiExpressionPartProps;
  };
  Blocks: {
    /** Markup for the description, instead of `@description`. */
    description: [];
    /** Markup for the value, instead of `@value`. */
    value: [];
  };
}

function noop(): void {}

export default class EuiExpression extends Component<EuiExpressionSignature> {
  get color(): EuiExpressionColor {
    const color = this.args.color;

    return color && (EXPRESSION_COLORS as readonly string[]).includes(color)
      ? color
      : 'success';
  }

  get isColumns(): boolean {
    return this.args.display === 'columns';
  }

  get isTruncate(): boolean {
    return this.args.textWrap === 'truncate';
  }

  /** Upstream root: `button` when clickable, else `span`. */
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiExpressionStyles);
    const color = this.color;
    const clickable = Boolean(this.args.onClick);
    const parts: CSSInterpolation[] = [
      clickable ? BUTTON_RESET : SPAN_RESET,
      styles.euiExpression,
      clickable && styles.isClickable,
      styles[color],
      this.args.isActive && styles.isActive.base,
      this.args.isActive && styles.isActive[color],
      this.isColumns && styles.columns,
      this.isTruncate && styles.truncate
    ];

    return `euiExpression ${euiClass(context, ...parts)}`;
  }

  @cached
  get descriptionClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiExpressionDescriptionStyles);

    const props = this.args.descriptionProps;

    return `euiExpression__description${
      props?.className ? ` ${props.className}` : ''
    } ${euiClass(
      context,
      styles.euiExpression__description,
      this.args.isInvalid ? styles.danger : styles[this.color],
      (this.args.uppercase ?? true) && styles.isUppercase,
      this.isTruncate && styles.truncate,
      this.isColumns && styles.columns,
      props?.css
    )}`;
  }

  @cached
  get valueClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = euiExpressionValueStyles;

    const props = this.args.valueProps;

    return `euiExpression__value${
      props?.className ? ` ${props.className}` : ''
    } ${euiClass(
      context,
      styles.euiExpression__value,
      this.isTruncate && styles.truncate,
      this.isColumns && styles.columns,
      props?.css
    )}`;
  }

  /** Composed into EuiIcon's own class through `@css`. */
  @cached
  get iconCss(): CSSInterpolation {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiExpressionIconStyles);

    return [styles.euiExpression__icon, this.isColumns && styles.columns];
  }

  /** Upstream: the columns width, then `descriptionProps.style`. */
  get descriptionStyle() {
    const custom = this.args.descriptionProps?.style;
    if (!this.isColumns && !custom) return undefined;
    return cssStyle({
      ...(this.isColumns
        ? { flexBasis: this.args.descriptionWidth ?? '20%' }
        : {}),
      ...custom
    });
  }

  get valueStyle() {
    const custom = this.args.valueProps?.style;
    return custom ? cssStyle(custom) : undefined;
  }

  <template>
    {{#let (element (if @onClick "button" "span")) as |Tag|}}
      <Tag
        class={{this.classes}}
        type={{if @onClick "button"}}
        {{on "click" (if @onClick @onClick noop)}}
        ...attributes
      >
        <span
          class={{this.descriptionClasses}}
          style={{this.descriptionStyle}}
          {{spreadAttributes @descriptionProps PART_ARGS}}
        >
          {{~#if (has-block "description")~}}
            {{yield to="description"}}
          {{~else~}}
            {{@description}}
          {{~/if~}}
        </span>
        {{#if (has-block "value")}}
          <span
            class={{this.valueClasses}}
            style={{this.valueStyle}}
            {{spreadAttributes @valueProps PART_ARGS}}
          >{{yield to="value"}}</span>
        {{else if @value}}
          <span
            class={{this.valueClasses}}
            style={{this.valueStyle}}
            {{spreadAttributes @valueProps PART_ARGS}}
          >{{@value}}</span>
        {{/if}}
        {{#if @isInvalid}}
          <EuiIcon
            class="euiExpression__icon"
            @type="warning"
            @color="danger"
            @css={{this.iconCss}}
          />
        {{/if}}
      </Tag>
    {{/let}}
  </template>
}
