import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { throttle } from '@ember/runloop';
import { service } from '@ember/service';
import type Owner from '@ember/owner';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';

import onWindowResize from '../-private/window-resize.ts';
import useState from '../helpers/use-state.ts';
import { getBreakpoint } from '../utils/breakpoint.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiBreadcrumbContentStyles,
  euiBreadcrumbPopoverStyles,
  euiBreadcrumbsListStyles,
  euiBreadcrumbStyles
} from '../utils/eui/styles.generated.ts';
import EuiIcon from './eui-icon.gts';
import EuiInnerText from './eui-inner-text.gts';
import EuiLink from './eui-link.gts';
import EuiPopover from './eui-popover.gts';

import type EuiI18nService from '../services/eui-i18n.ts';
import type { EuiBreakpointSize } from '../utils/breakpoint.ts';
import type { CSSInterpolation } from '@emotion/css/create-instance';

export type EuiBreadcrumbResponsiveMaxCount = {
  /**
   * Any of the following keys are allowed: `'xs' | 's' | 'm' | 'l' | 'xl'`
   * Omitting a key will display all breadcrumbs at that breakpoint
   */
  [key in EuiBreakpointSize]?: number;
};

const responsiveDefault: EuiBreadcrumbResponsiveMaxCount = {
  xs: 1,
  s: 2,
  m: 4
};

export type EuiBreadcrumb = {
  /**
   * Visible label of the breadcrumb
   */
  text: string;
  /**
   * Makes the breadcrumb a link.
   */
  href?: string;
  /** `rel` of a link breadcrumb (`noreferrer` is always added). */
  rel?: string;
  /**
   * Makes the breadcrumb clickable, e.g. to transition with the router.
   */
  onClick?: (e: MouseEvent) => void;

  /**
   * Class for the breadcrumb's text element.
   */
  className?: string;
  /**
   * Overrides `@truncate` for this breadcrumb: `true` limits its text to
   * 160px with an ellipsis, `false` never truncates it.
   */
  truncate?: boolean;

  /**
   * `EuiLink` color of a clickable breadcrumb. Defaults to `'subdued'`
   * (upstream; it used to be `'text'` for the last one).
   */
  color?: string;

  /** @deprecated Ignored. It used to mark the internal "…" item. */
  ellipsis?: boolean;

  /**
   * @deprecated Ignored. The last breadcrumb gets `aria-current="page"`;
   * see `@lastBreadcrumbIsCurrentPage`.
   */
  'aria-current'?: string;
};

export type EuiBreadcrumbsType = 'page' | 'application';

type Item = {
  breadcrumb?: EuiBreadcrumb;
  overflow?: EuiBreadcrumb[];
  isFirst: boolean;
  isLast: boolean;
  isOnly: boolean;
};

const LIST_RESET = {
  boxSizing: 'border-box',
  margin: 0,
  padding: 0,
  listStyle: 'none'
} as const;
const ITEM_RESET = { boxSizing: 'border-box', margin: 0, padding: 0 } as const;

/**
 * Upstream `limitBreadcrumbs`: keeps `max` breadcrumbs (biased to the end)
 * and collapses the rest into one item.
 */
function limitBreadcrumbs(breadcrumbs: EuiBreadcrumb[], max: number) {
  const atStart: EuiBreadcrumb[] = [];
  const atEnd: EuiBreadcrumb[] = [];
  const limit = Math.min(max, breadcrumbs.length);
  const start = Math.floor(limit / 2);
  const overflow = breadcrumbs.slice(start, start + breadcrumbs.length - limit);

  for (let i = 0; i < limit; i++) {
    const isEven = i % 2 === 0;
    const normalizedIndex = Math.floor(i * 0.5);
    const index = isEven
      ? breadcrumbs.length - 1 - normalizedIndex
      : normalizedIndex;
    const breadcrumb = breadcrumbs[index]!;

    if (isEven) {
      atEnd.unshift(breadcrumb);
    } else {
      atStart.push(breadcrumb);
    }
  }

  return [
    ...atStart.map((breadcrumb) => ({ breadcrumb })),
    { overflow },
    ...atEnd.map((breadcrumb) => ({ breadcrumb }))
  ];
}

interface EuiBreadcrumbsComponentArgs {
  /**
   * Shows fewer breadcrumbs on smaller screens, collapsing the ones in the
   * middle into a "…" popover. `true` uses `{ xs: 1, s: 2, m: 4 }` (at most
   * 1 breadcrumb on extra small screens, 2 on small, 4 on medium); pass an
   * object with any of the `xs`, `s`, `m`, `l`, `xl` keys for your own
   * limits (a missing key falls back to `@max`). Never shows more than
   * `@max`. Defaults to `true`, as upstream; `false` turns it off.
   */
  responsive?: boolean | EuiBreadcrumbResponsiveMaxCount;

  /**
   * Forces all breadcrumbs to a single line and truncates each breadcrumb
   * to 160px, except the last one, which fills the remaining space.
   * Defaults to `true`.
   */
  truncate?: boolean;

  /**
   * Collapses the breadcrumbs in the middle past this number into a single
   * "…" item that opens a popover with them. Defaults to `5`; pass `0` or
   * `null` to always show all breadcrumbs.
   */
  max?: number | null;

  /**
   * `'page'` (default) separates breadcrumbs with slashes; `'application'`
   * renders them as connected arrow-shaped chips, for the top of an app.
   */
  type?: EuiBreadcrumbsType;

  /**
   * Extra styles composed last into this component's class (like upstream's
   * `css` prop). Prefer this to an extra class when styling it from a parent.
   */
  css?: EuiCss;

  /**
   * Marks the last breadcrumb as the current page (`aria-current="page"`).
   * Defaults to `true`.
   */
  lastBreadcrumbIsCurrentPage?: boolean;

  /**
   * The breadcrumbs, from the root to the current page:
   * `[{ text: 'Home', href: '/' }, { text: 'Users', onClick: … }, { text: 'Jane' }]`.
   */
  breadcrumbs: EuiBreadcrumb[];
}

/**
 * A `<nav aria-label="Breadcrumbs">` trail of links to the current page.
 */
export interface EuiBreadcrumbsSignature {
  Element: HTMLElement;
  Args: EuiBreadcrumbsComponentArgs;
  Blocks: { default: [] };
}

export default class EuiBreadcrumbs extends Component<EuiBreadcrumbsSignature> {
  @service declare euiI18n: EuiI18nService;
  @tracked currentBreakpoint: EuiBreakpointSize | undefined;

  constructor(owner: Owner, args: EuiBreadcrumbsComponentArgs) {
    super(owner, args);
    this.currentBreakpoint = getBreakpoint(
      typeof window === 'undefined' ? -Infinity : window.innerWidth
    );
  }

  updateBreakpoint = () => {
    const breakpoint = getBreakpoint(window.innerWidth);
    if (breakpoint !== this.currentBreakpoint) {
      this.currentBreakpoint = breakpoint;
    }
  };

  onResize = () => {
    throttle(this, this.updateBreakpoint, 50);
  };

  get ariaLabel(): string {
    return this.euiI18n.lookupToken('euiBreadcrumbs.nav.ariaLabel', 'Breadcrumbs');
  }

  get collapsedLabel(): string {
    return this.euiI18n.lookupToken(
      'euiBreadcrumb.collapsedBadge.ariaLabel',
      'See collapsed breadcrumbs'
    );
  }

  get type(): EuiBreadcrumbsType {
    return this.args.type ?? 'page';
  }

  get lastBreadcrumbIsCurrentPage(): boolean {
    return this.args.lastBreadcrumbIsCurrentPage ?? true;
  }

  get truncate(): boolean {
    return this.args.truncate ?? true;
  }

  get max(): number | null {
    return this.args.max === null ? null : (this.args.max ?? 5);
  }

  /** Upstream `useResponsiveMax`. */
  get responsiveMax(): number | null {
    const responsive = this.args.responsive ?? true;
    const responsiveObject =
      typeof responsive === 'object' ? responsive : responsiveDefault;
    const max = this.max;
    let responsiveMax = max;
    const breakpoint = this.currentBreakpoint;

    if (responsive && breakpoint && responsiveObject[breakpoint]) {
      responsiveMax = responsiveObject[breakpoint]!;
    }

    if (max && responsiveMax) {
      responsiveMax = max < responsiveMax ? max : responsiveMax;
    }

    return responsiveMax;
  }

  @cached
  get classes(): string {
    if (!this.args.css) return 'euiBreadcrumbs';
    return `euiBreadcrumbs ${euiClass(getEuiThemeContext(this), this.args.css)}`;
  }

  @cached
  get listClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiBreadcrumbsListStyles);
    return `euiBreadcrumbs__list ${euiClass(
      context,
      // Scoped stand-in for React's global list reset.
      LIST_RESET,
      styles.euiBreadcrumbs__list,
      this.truncate && styles.isTruncated
    )}`;
  }

  @cached
  get items(): Item[] {
    const { breadcrumbs } = this.args;
    const max = this.responsiveMax;
    const visible: { breadcrumb?: EuiBreadcrumb; overflow?: EuiBreadcrumb[] }[] =
      max && breadcrumbs.length > max
        ? limitBreadcrumbs(breadcrumbs, max)
        : breadcrumbs.map((breadcrumb) => ({ breadcrumb }));

    return visible.map(({ breadcrumb, overflow }, index) => ({
      breadcrumb,
      overflow,
      isFirst: index === 0,
      isLast: index === visible.length - 1,
      isOnly: visible.length === 1
    }));
  }

  <template>
    <nav
      aria-label={{this.ariaLabel}}
      class={{this.classes}}
      {{onWindowResize this.onResize}}
      ...attributes
    >
      <ol class={{this.listClasses}}>
        {{#each this.items as |item|}}
          <BreadcrumbItem
            @item={{item}}
            @type={{this.type}}
            @truncate={{this.truncate}}
            @lastBreadcrumbIsCurrentPage={{this.lastBreadcrumbIsCurrentPage}}
            @collapsedLabel={{this.collapsedLabel}}
          />
        {{/each}}
      </ol>
    </nav>
  </template>
}

interface BreadcrumbItemSignature {
  Args: {
    item: Item;
    type: EuiBreadcrumbsType;
    truncate: boolean;
    lastBreadcrumbIsCurrentPage: boolean;
    collapsedLabel: string;
  };
}

/**
 * One breadcrumb (or the collapsed "…" item). Its link styles go through
 * EuiLink's `@css`, composed last into the link's own class (like upstream
 * `css`).
 */
class BreadcrumbItem extends Component<BreadcrumbItemSignature> {
  get isCollapsed(): boolean {
    return Boolean(this.args.item.overflow);
  }

  get breadcrumb(): EuiBreadcrumb | undefined {
    return this.args.item.breadcrumb;
  }

  get itemTruncate(): boolean {
    return this.isCollapsed
      ? this.args.truncate
      : (this.breadcrumb!.truncate ?? this.args.truncate);
  }

  get truncateLast(): boolean {
    return (
      !this.isCollapsed &&
      this.args.item.isLast &&
      this.args.truncate &&
      this.breadcrumb!.truncate == null
    );
  }

  get isInteractive(): boolean {
    return (
      !this.isCollapsed &&
      Boolean(this.breadcrumb!.href || this.breadcrumb!.onClick)
    );
  }

  get ariaCurrent(): 'page' | undefined {
    const { item, lastBreadcrumbIsCurrentPage } = this.args;
    return !this.isCollapsed && item.isLast && lastBreadcrumbIsCurrentPage
      ? 'page'
      : undefined;
  }

  get linkColor(): string {
    return this.breadcrumb?.color ?? 'subdued';
  }

  @cached
  get liClass(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiBreadcrumbStyles);
    return `euiBreadcrumb ${euiClass(
      context,
      ITEM_RESET,
      styles.euiBreadcrumb,
      styles[this.args.type],
      this.itemTruncate && styles.isTruncated,
      this.isCollapsed && styles.isCollapsed
    )}`;
  }

  @cached
  get contentCss(): CSSInterpolation[] {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiBreadcrumbContentStyles);
    const { type, item } = this.args;
    const isApplication = type === 'application';
    const css: CSSInterpolation[] = [styles.euiBreadcrumb__content, styles[type]];
    if (isApplication) {
      css.push(
        item.isOnly
          ? styles.applicationStyles.onlyChild
          : item.isFirst
            ? styles.applicationStyles.firstChild
            : item.isLast
              ? styles.applicationStyles.lastChild
              : styles.applicationStyles.intermediateChild
      );
    }
    return css;
  }

  @cached
  get truncationCss(): CSSInterpolation[] {
    // The collapsed item never truncates (upstream `truncate: false`).
    if (this.isCollapsed) return [];
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiBreadcrumbContentStyles);
    return [
      this.itemTruncate && !this.truncateLast && styles.isTruncated,
      this.truncateLast && styles.isTruncatedLast
    ];
  }

  @cached
  get interactionCss(): CSSInterpolation {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiBreadcrumbContentStyles);
    return (this.isInteractive || this.isCollapsed) &&
      this.args.type !== 'application'
      ? styles.isInteractive
      : undefined;
  }

  /** The content's styles: EuiLink's `@css`, or the plain span's class. */
  @cached
  get contentStyles(): CSSInterpolation[] {
    const context = getEuiThemeContext(this);
    const popoverStyles = useEuiBorealisStyles(
      context,
      euiBreadcrumbPopoverStyles
    );
    return this.isCollapsed
      ? [
          popoverStyles.euiBreadcrumb__popoverButton,
          ...this.contentCss,
          this.interactionCss
        ]
      : [...this.contentCss, ...this.truncationCss, this.interactionCss];
  }

  get contentClassNames(): string {
    return ['euiBreadcrumb__content', this.breadcrumb?.className]
      .filter(Boolean)
      .join(' ');
  }

  @cached
  get contentClass(): string {
    return `${this.contentClassNames} ${euiClass(
      getEuiThemeContext(this),
      ...this.contentStyles
    )}`;
  }

  @cached
  get truncationClass(): string {
    const context = getEuiThemeContext(this);
    const popoverStyles = useEuiBorealisStyles(
      context,
      euiBreadcrumbPopoverStyles
    );
    return euiClass(
      context,
      popoverStyles.euiBreadcrumb__popoverTruncation,
      ...this.truncationCss
    );
  }

  /** Upstream's `css` on the collapsed item's EuiPopover. */
  @cached
  get popoverCss(): CSSInterpolation[] {
    const context = getEuiThemeContext(this);
    const popoverStyles = useEuiBorealisStyles(
      context,
      euiBreadcrumbPopoverStyles
    );
    return [
      popoverStyles.popoverWrapper.euiBreadcrumb__popoverWrapper,
      !this.args.item.isLast && popoverStyles.popoverWrapper[this.args.type]
    ];
  }

  <template>
    {{#if @item.overflow}}
      {{#let (useState false) as |popover|}}
        <li class={{this.liClass}} data-test-subj="euiBreadcrumb">
          <EuiPopover
            @css={{this.popoverCss}}
            @isOpen={{popover.value}}
            @closePopover={{fn popover.setState false}}
          >
            <:button>
              <EuiLink
                class={{this.contentClassNames}}
                @css={{this.contentStyles}}
                @color="subdued"
                aria-label={{@collapsedLabel}}
                title={{@collapsedLabel}}
                {{on "click" (fn popover.setState (if popover.value false true))}}
              >
                <span class={{this.truncationClass}}>&hellip;</span>
                <EuiIcon @type="chevronSingleDown" @size="s" />
              </EuiLink>
            </:button>
            <:content>
              <EuiBreadcrumbs
                @breadcrumbs={{@item.overflow}}
                @lastBreadcrumbIsCurrentPage={{false}}
                @responsive={{false}}
                @truncate={{false}}
                @max={{0}}
              />
            </:content>
          </EuiPopover>
        </li>
      {{/let}}
    {{else if this.breadcrumb}}
      <li class={{this.liClass}} data-test-subj="euiBreadcrumb">
        <EuiInnerText as |setInnerTextRef innerText|>
          {{#if this.isInteractive}}
            <EuiLink
              {{didInsert setInnerTextRef}}
              @color={{this.linkColor}}
              @href={{this.breadcrumb.href}}
              @rel={{this.breadcrumb.rel}}
              title={{if innerText innerText}}
              class={{this.contentClassNames}}
              @css={{this.contentStyles}}
              aria-current={{this.ariaCurrent}}
              {{on "click" (optional this.breadcrumb.onClick)}}
            >
              {{this.breadcrumb.text}}
            </EuiLink>
          {{else}}
            <span
              {{didInsert setInnerTextRef}}
              title={{if innerText innerText}}
              class={{this.contentClass}}
              aria-current={{this.ariaCurrent}}
            >
              {{this.breadcrumb.text}}
            </span>
          {{/if}}
        </EuiInnerText>
      </li>
    {{/if}}
  </template>
}
