import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';

import { deprecateRemovedUpstream } from '../-private/removed-upstream.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiSuggestItemStyles,
  SUGGEST_ITEM_TINTS,
  SUGGEST_LABEL_WIDTHS
} from '../utils/eui/suggest.ts';
import EuiIcon from './eui-icon.gts';

import type { EuiSuggestItemTint, EuiSuggestLabelWidth } from '../utils/eui/suggest.ts';
import type { EuiIconSignature } from './eui-icon';
import type Owner from '@ember/owner';

export interface EuiSuggestItemType {
  /** Icon of the suggestion's type, e.g. `'kqlField'` or `'search'`. */
  iconType: EuiIconSignature['Args']['type'];
  /** `'tint0'` to `'tint10'`, the color behind the icon. */
  color?: string;
}

/**
 * One suggestion of an `EuiSuggest`: a colored type icon, a label and an
 * optional description. With `@onClick` it is a button.
 */
export interface EuiSuggestItemSignature {
  Element: HTMLButtonElement | HTMLDivElement;
  Args: {
    /** The suggestion's type: its icon and color. */
    type: EuiSuggestItemType;
    /** The suggestion. */
    label: string;
    /** More about it, after the label. */
    description?: string;
    /**
     * `'fixed'` keeps the label at `@labelWidth`; `'expand'` lets it take
     * the space it needs. Defaults to `'fixed'` (`'expand'` without a
     * description).
     */
    labelDisplay?: 'fixed' | 'expand';
    /** Width of the label in percent, `'20'` to `'90'` by tens. Defaults to `'50'`. */
    labelWidth?: '20' | '30' | '40' | '50' | '60' | '70' | '80' | '90';
    /**
     * `'truncate'` (label and description, with `title`s) or `'wrap'` long
     * text. Defaults to `'truncate'`.
     */
    descriptionDisplay?: 'truncate' | 'wrap';
    /** Makes it a button. */
    onClick?: (event: MouseEvent) => void;
  };
}

// Scoped stand-in for React's global button reset; upstream styles come after.
const BUTTON_RESET = {
  ':where(&)': {
    margin: 0,
    padding: 0,
    border: 0,
    background: 'none',
    font: 'inherit',
    color: 'inherit'
  }
} as const;

// React EUI's global reset makes every element border-box.
const BOX_RESET = {
  boxSizing: 'border-box',
  '& :where(*, *::before, *::after)': { boxSizing: 'border-box' }
} as const;

function noop(): void {}

export default class EuiSuggestItem extends Component<EuiSuggestItemSignature> {
  constructor(owner: Owner, args: EuiSuggestItemSignature['Args']) {
    super(owner, args);
    deprecateRemovedUpstream(
      'eui-suggest-item',
      'EuiSuggestItem',
      'Use EuiSelectable or EuiComboBox instead, as upstream recommends.'
    );
  }

  get context() {
    return getEuiThemeContext(this);
  }

  get tint(): EuiSuggestItemTint | undefined {
    const color = this.args.type?.color;
    return (SUGGEST_ITEM_TINTS as readonly (string | undefined)[]).includes(color)
      ? (color as EuiSuggestItemTint)
      : undefined;
  }

  get labelWidth(): EuiSuggestLabelWidth {
    const width = String(this.args.labelWidth ?? '50');
    return (SUGGEST_LABEL_WIDTHS as readonly string[]).includes(width)
      ? (width as EuiSuggestLabelWidth)
      : '50';
  }

  /** No description: the label expands (upstream docs). */
  get labelDisplay(): 'fixed' | 'expand' {
    return this.args.description ? (this.args.labelDisplay ?? 'fixed') : 'expand';
  }

  get truncate(): boolean {
    return this.args.descriptionDisplay !== 'wrap';
  }

  get isClickable(): boolean {
    return Boolean(this.args.onClick);
  }

  @cached
  get styles() {
    return useEuiBorealisStyles(this.context, euiSuggestItemStyles);
  }

  @cached
  get rootClass(): string {
    const styles = this.styles;
    return [
      'euiSuggestItem',
      this.truncate && 'euiSuggestItem--truncate',
      this.isClickable && 'euiSuggestItem-isClickable',
      euiClass(
        this.context,
        BOX_RESET,
        this.isClickable && BUTTON_RESET,
        { fontFamily: this.context.upstream.euiTheme.font.family },
        styles.euiSuggestItem,
        this.truncate && styles.truncate,
        this.isClickable && styles.isClickable
      )
    ]
      .filter(Boolean)
      .join(' ');
  }

  @cached
  get typeClass(): string {
    const tint = this.tint;
    return [
      'euiSuggestItem__type',
      tint && `euiSuggestItem__type--${tint}`,
      euiClass(
        this.context,
        this.styles.euiSuggestItem__type,
        tint && this.styles.types[tint]
      )
    ]
      .filter(Boolean)
      .join(' ');
  }

  @cached
  get labelClass(): string {
    const display = this.labelDisplay;
    return [
      'euiSuggestItem__label',
      `euiSuggestItem__labelDisplay--${display}`,
      display === 'fixed' && `euiSuggestItem__label--width${this.labelWidth}`,
      euiClass(
        this.context,
        this.styles.euiSuggestItem__label,
        display === 'fixed'
          ? this.styles.labelWidths[this.labelWidth]
          : this.styles.labelExpand
      )
    ]
      .filter(Boolean)
      .join(' ');
  }

  @cached
  get descriptionClass(): string {
    const wrap = !this.truncate;
    return [
      'euiSuggestItem__description',
      `euiSuggestItem__description--${wrap ? 'wrap' : 'truncate'}`,
      euiClass(
        this.context,
        this.styles.euiSuggestItem__description,
        wrap && this.styles.descriptionWrap
      )
    ].join(' ');
  }

  <template>
    {{#let (element (if @onClick "button" "div")) as |Tag|}}
      <Tag
        class={{this.rootClass}}
        type={{if @onClick "button"}}
        {{on "click" (if @onClick @onClick noop)}}
        ...attributes
      >
        <span class={{this.typeClass}}>
          <EuiIcon @type={{@type.iconType}} @color="inherit" />
        </span>
        <span class={{this.labelClass}} title={{@label}}>{{@label}}</span>
        {{#if @description}}
          <span class={{this.descriptionClass}} title={{@description}}>{{@description}}</span>
        {{/if}}
      </Tag>
    {{/let}}
  </template>
}
