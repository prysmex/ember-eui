import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import EuiNode from '../-private/eui-node.gts';
import { euiTabsContext } from '../-private/eui-tabs-context.ts';
import { randomId } from '../-private/random-id.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiTabContentStyles,
  euiTabStyles,
  euiTextTruncate
} from '../utils/eui/styles.generated.ts';
import { getSecureRelForTarget, isValidHref } from './eui-link.gts';

import type { CSSObject } from '@emotion/css/create-instance';
import type { EuiNodeValue } from '../-private/eui-node.gts';

// `eui-textTruncate` is a legacy utility class; upstream's mixin replaces it.
const TEXT_TRUNCATE = euiTextTruncate();

export type IEuiTab = {
  /** Id of the tab. Defaults to a random id. */
  id?: string;
  /**
   * Makes the tab a link, e.g. to a route. A `javascript:` URL disables the
   * tab instead (upstream `validateHref`).
   */
  href?: string;
  /** `target` of a link tab. */
  target?: string;
  /** `rel` of a link tab; `noreferrer` is always added (upstream). */
  rel?: string;
  /**
   * Content before the label (text or a component), for when a block is not
   * an option, e.g. in data. Otherwise use `<:prepend>`.
   */
  prepend?: EuiNodeValue;
  /** Content after the label (text or a component). Otherwise use `<:append>`. */
  append?: EuiNodeValue;
  /** Marks the tab as selected (`aria-selected`, tab stop). */
  isSelected?: boolean;
  /** Disables the tab. */
  disabled?: boolean;
};

/**
 * One tab of an EuiTabs. Add `{{on "click" …}}` to select it. Only the
 * selected tab is in the tab order (`tabindex="0"`, others `-1`), as
 * upstream; EuiTabs moves focus between tabs with the arrow keys.
 */
export interface EuiTabSignature {
  Element: HTMLButtonElement | HTMLAnchorElement;
  Args: {
    [K in keyof IEuiTab]: IEuiTab[K];
  };
  Blocks: {
    /** Content before the label, e.g. an icon. */
    prepend: [];
    /** The tab's label. */
    default: [];
    /** Content after the label, e.g. a notification badge. */
    append: [];
  };
}

export default class EuiTab extends Component<EuiTabSignature> {
  fallbackId = randomId();

  get id(): string {
    return this.args.id ?? this.fallbackId;
  }

  get isDisabled(): boolean {
    const { href } = this.args;
    return Boolean(this.args.disabled || (href && !isValidHref(href)));
  }

  // `<a>` cannot be disabled, so a disabled link tab renders a button.
  get isAnchor(): boolean {
    return Boolean(this.args.href) && !this.isDisabled;
  }

  get rel(): string {
    return getSecureRelForTarget(this.args.target, this.args.rel);
  }

  get tabIndex(): string {
    return this.args.isSelected ? '0' : '-1';
  }

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const theme = context.upstream.euiTheme;
    const styles = useEuiBorealisStyles(context, euiTabStyles);
    const { expand } = euiTabsContext(this);
    const { isSelected } = this.args;
    // Scoped stand-in for React's global reset; upstream styles come after.
    const reset: CSSObject = {
      boxSizing: 'border-box',
      margin: 0,
      border: 'none',
      background: 'none',
      fontFamily: theme.font.family,
      fontSize: 'inherit',
      textDecoration: 'none',
      '&:disabled': { cursor: 'not-allowed' }
    };
    return [
      'euiTab',
      isSelected && 'euiTab-isSelected',
      euiClass(
        context,
        reset,
        styles.euiTab,
        expand && styles.expanded,
        this.isDisabled && styles.disabled.disabled,
        isSelected &&
          (this.isDisabled ? styles.disabled.selected : styles.selected)
      )
    ]
      .filter(Boolean)
      .join(' ');
  }

  @cached
  get contentClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTabContentStyles);
    const { size } = euiTabsContext(this);
    // `eui-textTruncate` is a legacy utility class; apply its upstream mixin.
    return `euiTab__content ${euiClass(
      context,
      TEXT_TRUNCATE,
      styles.euiTab__content,
      styles[size]
    )}`;
  }

  <template>
    {{#if this.isAnchor}}
      <a
        id={{this.id}}
        role="tab"
        aria-selected={{if @isSelected "true" "false"}}
        tabindex={{this.tabIndex}}
        class={{this.classes}}
        href={{@href}}
        target={{@target}}
        rel={{this.rel}}
        ...attributes
      >
        {{#if (has-block "prepend")}}
          <span class="euiTab__prepend">
            {{yield to="prepend"}}
          </span>
        {{else if @prepend}}
          <span class="euiTab__prepend">
            <EuiNode @value={{@prepend}} />
          </span>
        {{/if}}

        <span class={{this.contentClasses}}>
          {{yield}}
        </span>

        {{#if (has-block "append")}}
          <span class="euiTab__append">
            {{yield to="append"}}
          </span>
        {{else if @append}}
          <span class="euiTab__append">
            <EuiNode @value={{@append}} />
          </span>
        {{/if}}
      </a>
    {{else}}
      <button
        id={{this.id}}
        role="tab"
        aria-selected={{if @isSelected "true" "false"}}
        tabindex={{this.tabIndex}}
        type="button"
        class={{this.classes}}
        disabled={{this.isDisabled}}
        ...attributes
      >
        {{#if (has-block "prepend")}}
          <span class="euiTab__prepend">
            {{yield to="prepend"}}
          </span>
        {{else if @prepend}}
          <span class="euiTab__prepend">
            <EuiNode @value={{@prepend}} />
          </span>
        {{/if}}

        <span class={{this.contentClasses}}>
          {{yield}}
        </span>

        {{#if (has-block "append")}}
          <span class="euiTab__append">
            {{yield to="append"}}
          </span>
        {{else if @append}}
          <span class="euiTab__append">
            <EuiNode @value={{@append}} />
          </span>
        {{/if}}
      </button>
    {{/if}}
  </template>
}
