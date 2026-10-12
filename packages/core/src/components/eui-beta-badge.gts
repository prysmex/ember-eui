import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';

import { eq } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import { euiBetaBadgeStyles } from '../utils/eui/styles.generated.ts';
import {
  euiBadgeReset,
  secureRel
} from './eui-badge.gts';
import EuiIcon from './eui-icon.gts';
import EuiToolTip from './eui-tool-tip.gts';

import type { EuiIconSignature } from './eui-icon';
import type { EuiToolTipSignature } from './eui-tool-tip';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiBetaBadgeSignature {
  Element: HTMLSpanElement | HTMLAnchorElement | HTMLButtonElement;
  Args: {
    /**
     * The badge's text, e.g. `'Beta'`, or a single letter (rendered as a
     * circle). Also its hover title. The default block replaces it.
     */
    label?: string;
    /**
     * Hover title when there is no `@label` (e.g. with `@iconType`), and the
     * title of the `@tooltipContent` tooltip.
     */
    title?: string;
    /**
     * Renders an icon instead of `@label` (icon-only, circular badge). Give
     * it a `@title` so it has a name.
     */
    iconType?: EuiIconSignature['Args']['type'];
    /**
     * `'hollow'`, `'accent'`, `'subdued'` or `'warning'`. Defaults to
     * `'hollow'`.
     */
    color?: 'hollow' | 'accent' | 'subdued' | 'warning';
    /**
     * `'s'` or `'m'`. Defaults to `'m'`.
     */
    size?: 's' | 'm';
    /**
     * Vertical alignment (`vertical-align`), `'baseline'` or `'middle'`.
     * Defaults to `'baseline'`.
     */
    alignment?: 'baseline' | 'middle';
    /**
     * Where the `@tooltipContent` tooltip appears: `'top'`, `'right'`,
     * `'bottom'` or `'left'`. Defaults to `'top'`.
     */
    tooltipPosition?: EuiToolTipSignature['Args']['position'];
    /**
     * Shows a tooltip with this text on hover, e.g. what "Beta" means here.
     */
    tooltipContent?: string;
    /**
     * Accessible label of the badge when it is a link or button
     * (`@href` / `@onClick`).
     */
    onClickAriaLabel?: string;
    /**
     * Makes the badge a link.
     */
    href?: string;
    /**
     * `target` of the `@href` link, e.g. `'_blank'`.
     */
    target?: string;
    /**
     * `rel` of the `@href` link. `noreferrer` (and `noopener` for
     * `_blank`) is always added.
     */
    rel?: string;
    /**
     * Makes the badge a button calling this function.
     */
    onClick?: (event: MouseEvent) => void;
  };
  Blocks: {
    /** Custom content instead of `@label` / `@iconType`. */
    default: [];
  };
}

/** A small "Beta"/"Lab" badge, optionally with a tooltip explaining it. */
export default class EuiBetaBadge extends Component<EuiBetaBadgeSignature> {
  get context() {
    return getEuiThemeContext(this);
  }

  get size(): 's' | 'm' {
    return this.args.size ?? 'm';
  }

  get kind(): BetaBadgeElementSignature['Args']['kind'] {
    if (this.args.href) return 'a';
    if (this.args.onClick) return 'button';
    return this.args.tooltipContent ? 'focusable' : 'span';
  }

  get title(): string | undefined {
    const { label, title } = this.args;
    // Clickable badges prefer the label, plain ones the title (upstream).
    if (this.kind === 'a' || this.kind === 'button') return label ?? title;
    return this.kind === 'span' ? (title ?? label) : undefined;
  }

  get rel(): string | undefined {
    return this.args.href
      ? secureRel(this.args.target, this.args.rel)
      : undefined;
  }

  @cached
  get classes(): string {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiBetaBadgeStyles);
    const size = this.size;
    const isCircular = Boolean(
      this.args.iconType || this.args.label?.length === 1
    );
    return euiClass(
      context,
      euiBadgeReset(context.upstream),
      this.kind === 'button'
        ? { background: 'none', padding: 0, color: 'inherit' }
        : undefined,
      { padding: 0 },
      styles.euiBetaBadge,
      styles[this.args.color ?? 'hollow'],
      styles[size],
      styles[this.args.alignment ?? 'baseline'],
      isCircular ? styles.badgeSizes.circle[size] : styles.badgeSizes.default[size]
    );
  }

  @cached
  /** Composed into EuiIcon's own class via `@css`. */
  get iconCss(): EuiCss {
    return useEuiBorealisStyles(this.context, euiBetaBadgeStyles)
      .euiBetaBadge__icon;
  }

  <template>
    {{#let
      (component
        BetaBadgeElement
        kind=this.kind
        class=this.classes
        title=this.title
        ariaLabel=@onClickAriaLabel
        href=@href
        target=@target
        rel=this.rel
        onClick=@onClick
      )
      as |Badge|
    }}
      {{#if @tooltipContent}}
        <EuiToolTip
          @position={{if @tooltipPosition @tooltipPosition "top"}}
          @title={{if @title @title @label}}
          @content={{@tooltipContent}}
        >
          <Badge ...attributes>
            {{#if (has-block)}}
              {{yield}}
            {{else if @iconType}}
              <EuiIcon
                @iconClasses="euiBetaBadge__icon"
                @css={{this.iconCss}}
                @type={{@iconType}}
                @size={{this.size}}
                aria-hidden="true"
                @color="inherit"
              />
            {{else}}
              {{@label}}
            {{/if}}
          </Badge>
        </EuiToolTip>
      {{else}}
        <Badge ...attributes>
          {{#if (has-block)}}
            {{yield}}
          {{else if @iconType}}
            <EuiIcon
              @iconClasses="euiBetaBadge__icon"
                @css={{this.iconCss}}
              @type={{@iconType}}
              @size={{this.size}}
              aria-hidden="true"
              @color="inherit"
            />
          {{else}}
            {{@label}}
          {{/if}}
        </Badge>
      {{/if}}
    {{/let}}
  </template>
}

interface BetaBadgeElementSignature {
  Element: HTMLSpanElement | HTMLAnchorElement | HTMLButtonElement;
  Args: {
    kind: 'a' | 'button' | 'span' | 'focusable';
    class: string;
    title?: string;
    ariaLabel?: string;
    href?: string;
    target?: string;
    rel?: string;
    onClick?: (event: MouseEvent) => void;
  };
  Blocks: { default: [] };
}

const BetaBadgeElement: TemplateOnlyComponent<BetaBadgeElementSignature> =
  <template>
    {{#if (eq @kind "a")}}
      <a
        aria-label={{@ariaLabel}}
        title={{@title}}
        class="euiBetaBadge {{@class}}"
        href={{@href}}
        target={{@target}}
        rel={{@rel}}
        ...attributes
        {{on "click" (if @onClick @onClick noop)}}
      >{{yield}}</a>
    {{else if (eq @kind "button")}}
      <button
        type="button"
        aria-label={{@ariaLabel}}
        title={{@title}}
        class="euiBetaBadge {{@class}}"
        ...attributes
        {{on "click" (if @onClick @onClick noop)}}
      >{{yield}}</button>
    {{else if (eq @kind "focusable")}}
      {{! upstream: a focusable tooltip anchor }}
      <span
        tabindex="0"
        role="button"
        class="euiBetaBadge {{@class}}"
        ...attributes
      >{{yield}}</span>
    {{else}}
      <span
        class="euiBetaBadge {{@class}}"
        title={{@title}}
        ...attributes
      >{{yield}}</span>
    {{/if}}
  </template>;

function noop() {}
