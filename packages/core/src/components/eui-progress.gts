import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { service } from '@ember/service';

import { modifier } from 'ember-modifier';
import { or } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiProgressDataStyles,
  euiProgressLabelStyles,
  euiProgressStyles,
  euiProgressValueTextStyles,
  makeHighContrastColor
} from '../utils/eui/styles.generated.ts';
import { euiScreenReaderOnlyClass } from './eui-screen-reader-only.gts';

import type EuiI18n from '../services/eui-i18n.ts';

/** Upstream named colors. */
export const PROGRESS_COLORS = [
  'primary',
  'success',
  'warning',
  'danger',
  'subdued',
  'accent',
  'accentSecondary',
  'vis0',
  'vis1',
  'vis2',
  'vis3',
  'vis4',
  'vis5',
  'vis6',
  'vis7',
  'vis8',
  'vis9'
] as const;

export type EuiProgressNamedColor = (typeof PROGRESS_COLORS)[number];
/** A named color or any CSS color value. */
export type EuiProgressColor = EuiProgressNamedColor | (string & {});

function isNamedColor(color: string): color is EuiProgressNamedColor {
  return (PROGRESS_COLORS as readonly string[]).includes(color);
}

/**
 * Calls `setText` with the element's text now and whenever it changes.
 * Reads are deferred a microtask: the text feeds attributes of the same render.
 */
const observeText = modifier(
  (element: Element, [setText]: [(text: string) => void]) => {
    let active = true;
    const read = () => {
      if (active) setText(element.textContent?.trim() ?? '');
    };
    void Promise.resolve().then(read);
    const observer = new MutationObserver(read);
    observer.observe(element, {
      characterData: true,
      childList: true,
      subtree: true
    });
    return () => {
      active = false;
      observer.disconnect();
    };
  }
);

/** A progress bar: a value out of `@max`, or an indeterminate loading bar. */
export interface EuiProgressSignature {
  Element: HTMLDivElement | HTMLProgressElement;
  Args: {
    /**
     * Maximum value. With it the bar shows `@value`; without it the bar is
     * an indeterminate loading animation.
     */
    max?: number;
    /** Current value, from 0 to `@max`. */
    value?: number;
    /** Thickness: `'xs'`, `'s'`, `'m'` or `'l'`. Defaults to `'m'`. */
    size?: 'xs' | 's' | 'm' | 'l';
    /**
     * `'static'` renders in place; `'fixed'` / `'absolute'` pin it to the
     * top of the window / its positioned parent. Defaults to `'static'`.
     */
    position?: 'static' | 'fixed' | 'absolute';
    /**
     * `'primary'`, `'success'`, `'warning'`, `'danger'`, `'subdued'`,
     * `'accent'`, `'accentSecondary'`, `'vis0'`–`'vis9'`, or any CSS color.
     * Defaults to `'success'`.
     */
    color?: EuiProgressColor;
    /** Classes for the value text. */
    labelClasses?: string;
    /**
     * `true` shows `@value` as a percentage ("70%") above the bar; a
     * string shows that text. For other content use the `<:valueText>` block.
     */
    valueText?: string | boolean;
    /** Label above the bar (with `@max`); or use the `<:label>` block. */
    label?: string;
  };
  Blocks: {
    /** Label above the bar (with `@max`). */
    label?: [];
    /** Value text above the bar, e.g. "70%" (with `@max`). */
    valueText?: [];
  };
}

export default class EuiProgress extends Component<EuiProgressSignature> {
  @service declare euiI18n: EuiI18n;

  /** Text of the rendered label and value text, for the bar's accessible name and value. */
  @tracked labelText = '';
  @tracked valueTextContent = '';

  setLabelText = (text: string) => {
    if (this.labelText !== text) this.labelText = text;
  };
  setValueTextContent = (text: string) => {
    if (this.valueTextContent !== text) this.valueTextContent = text;
  };

  get context() {
    return getEuiThemeContext(this);
  }

  get isDeterminate() {
    return this.args.max !== undefined && this.args.max !== null;
  }

  get color(): EuiProgressColor {
    return this.args.color ?? 'success';
  }

  get percentText(): string | undefined {
    if (this.args.valueText !== true) return undefined;
    const text = this.euiI18n.lookupToken('euiProgress.valueText', '{value}%', {
      value: this.args.value
    }) as string | string[];
    return Array.isArray(text) ? text.join('') : String(text);
  }

  get stringValueText(): string | undefined {
    const { valueText } = this.args;
    return typeof valueText === 'string' && valueText ? valueText : undefined;
  }

  get classes() {
    const context = this.context;
    const styles = euiProgressStyles(
      context.upstream,
      this.isDeterminate
    );
    const color = this.color;
    return `euiProgress ${euiClass(
      context,
      styles.euiProgress,
      this.isDeterminate ? styles.native : styles.indeterminate,
      styles[this.args.size ?? 'm'],
      styles[this.args.position ?? 'static'],
      isNamedColor(color) ? styles[color] : [styles.customColor, { color }]
    )}`;
  }

  get dataClasses() {
    const styles = useEuiBorealisStyles(
      this.context,
      euiProgressDataStyles
    );
    return `euiProgress__data ${euiClass(
      this.context,
      styles.euiProgress__data,
      this.args.size === 'l' ? styles.l : undefined
    )}`;
  }

  get labelClassNames() {
    const styles = euiProgressLabelStyles;
    return `euiProgress__label ${euiClass(this.context, styles.euiProgress__label)}`;
  }

  get valueTextClasses() {
    const context = this.context;
    const styles = useEuiBorealisStyles(
      context,
      euiProgressValueTextStyles
    );
    const color = this.color;
    const custom = isNamedColor(color)
      ? styles[color]
      : [
          (euiProgressStyles(context.upstream, true))
            .customColor,
          {
            color: (
              makeHighContrastColor as (
                color: string
              ) => (theme: unknown) => string
            )(color)(context.upstream.euiTheme)
          }
        ];
    return [
      'euiProgress__valueText',
      this.args.labelClasses,
      euiClass(context, styles.euiProgress__valueText, custom)
    ]
      .filter(Boolean)
      .join(' ');
  }

  get screenReaderClasses() {
    return euiScreenReaderOnlyClass(this.context);
  }

  <template>
    {{#if this.isDeterminate}}
      {{#if
        (or
          (has-block "label")
          @label
          (has-block "valueText")
          this.percentText
          this.stringValueText
        )
      }}
        <div class={{this.dataClasses}}>
          {{#if (or (has-block "label") @label)}}
            <div
              class={{this.labelClassNames}}
              aria-hidden="true"
              {{observeText this.setLabelText}}
            >
              {{~#if (has-block "label")~}}
                {{yield to="label"}}
              {{~else~}}
                {{@label}}
              {{~/if~}}
            </div>
          {{/if}}
          {{#if (or (has-block "valueText") this.percentText this.stringValueText)}}
            <div
              class={{this.valueTextClasses}}
              aria-hidden="true"
              {{observeText this.setValueTextContent}}
            >
              {{~#if this.percentText~}}
                {{this.percentText}}
              {{~else if this.stringValueText~}}
                {{this.stringValueText}}
              {{~else~}}
                {{yield to="valueText"}}
              {{~/if~}}
            </div>
          {{/if}}
        </div>
      {{/if}}
      <div
        class={{this.screenReaderClasses}}
        aria-live="polite"
        aria-atomic="true"
      >
        <span>
          {{~#if this.labelText}}{{this.labelText}} {{/if~}}
          {{~if this.valueTextContent this.valueTextContent @value~}}
        </span>
      </div>
      <progress
        class={{this.classes}}
        max={{@max}}
        value={{@value}}
        aria-valuetext={{if this.valueTextContent this.valueTextContent}}
        aria-label={{if this.labelText this.labelText}}
        ...attributes
      ></progress>
    {{else}}
      <div class={{this.classes}} ...attributes></div>
    {{/if}}
  </template>
}
