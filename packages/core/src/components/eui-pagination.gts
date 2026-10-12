import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { throttle } from '@ember/runloop';
import { service } from '@ember/service';
import type Owner from '@ember/owner';

import onWindowResize from '../-private/window-resize.ts';
import { getBreakpoint } from '../utils/breakpoint.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiPaginationStyles,
  euiScreenReaderOnly
} from '../utils/eui/styles.generated.ts';
import ArrowButton from './eui-pagination/arrow-button.gts';
import ButtonWrapper from './eui-pagination/button-wrapper.gts';
import NextButton from './eui-pagination/next-button.gts';
import PreviousButton from './eui-pagination/previous-button.gts';
import EuiText from './eui-text.gts';

import type EuiI18nService from '../services/eui-i18n.ts';
import type { EuiBreakpointSize } from '../utils/breakpoint.ts';

export type PageClickHandler = (pageIndex: number) => void;
export type SafeClickHandler = (pageIndex: number, event?: Event) => void;

interface Args {
  /**
   * The total number of pages. Defaults to `1`.
   */
  pageCount?: number;

  /**
   * The current page using a zero based index.
   * So if you set the activePage to 1, it will activate the second page.
   * Defaults to `0`.
   */
  activePage?: number;

  /** Called with the clicked page's zero based index; update `@activePage` here. */
  onPageClick?: PageClickHandler;

  /**
   * Shows "page of total" text with first/previous/next/last arrows instead
   * of page numbers.
   */
  compressed?: boolean;

  /**
   * Breakpoints at which it is automatically `compressed`. Defaults to
   * `['xs', 's']`, as upstream; `false` turns this off.
   */
  responsive?: false | EuiBreakpointSize[];

  /**
   * If passed in, passes value through to each button to set aria-controls
   * (the id of the content the pages change); the buttons then link to it.
   */
  'aria-controls'?: string;
  /** Same as `'aria-controls'`. */
  ariaControls?: string;
}

const MAX_VISIBLE_PAGES = 5;
const NUMBER_SURROUNDING_PAGES = Math.floor(MAX_VISIBLE_PAGES * 0.5);
const BOX_SIZING = { boxSizing: 'border-box' } as const;
// Scoped stand-in for React's global list reset.
const LIST_RESET = { margin: 0, padding: 0, listStyle: 'none' } as const;
const SCREEN_READER_ONLY = euiScreenReaderOnly();
const RESPONSIVE_DEFAULT: EuiBreakpointSize[] = ['xs', 's'];

type Ellipsis = { ellipsis: string };
type PageButton = { pageIndex: number };

const hasEllipsis = (page: PageButton | Ellipsis): page is Ellipsis =>
  'ellipsis' in page;
const ellipsisLabel = (page: PageButton | Ellipsis) =>
  'ellipsis' in page ? page.ellipsis : undefined;
const pageIndexOf = (page: PageButton | Ellipsis) =>
  'pageIndex' in page ? page.pageIndex : 0;
const lastIndex = (pageCount: number) => pageCount - 1;

/** Page numbers with previous/next buttons, for paged lists and tables. */
export interface EuiPaginationSignature {
  Element: HTMLElement;
  Args: Args;
}

export default class EuiPaginationComponent extends Component<EuiPaginationSignature> {
  @service declare euiI18n: EuiI18nService;
  @tracked currentBreakpoint: EuiBreakpointSize | undefined;

  constructor(owner: Owner, args: Args) {
    super(owner, args);
    this.currentBreakpoint = getBreakpoint(
      typeof window === 'undefined' ? Infinity : window.innerWidth
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

  get pageCount() {
    return this.args.pageCount ?? 1;
  }

  get activePage() {
    return this.args.activePage ?? 0;
  }

  get ariaControls() {
    return this.args['aria-controls'] || this.args.ariaControls;
  }

  get compressed(): boolean {
    if (this.args.compressed) return true;
    const responsive = this.args.responsive ?? RESPONSIVE_DEFAULT;
    return Boolean(
      responsive &&
        this.currentBreakpoint &&
        responsive.includes(this.currentBreakpoint)
    );
  }

  get firstPageInRange() {
    return Math.max(
      0,
      Math.min(
        this.activePage - NUMBER_SURROUNDING_PAGES,
        this.pageCount - MAX_VISIBLE_PAGES
      )
    );
  }

  get lastPageInRange() {
    return Math.min(this.pageCount, this.firstPageInRange + MAX_VISIBLE_PAGES);
  }

  get pages(): PageButton[] {
    const pages = [];
    for (let i = this.firstPageInRange; i < this.lastPageInRange; i++) {
      pages.push({ pageIndex: i });
    }
    return pages;
  }

  get firstPageButtons(): (PageButton | Ellipsis)[] {
    const buttons: (PageButton | Ellipsis)[] = [];
    const first = this.firstPageInRange;

    if (first > 0) {
      buttons.push({ pageIndex: 0 });

      if (first > 1 && first !== 2) {
        buttons.push({
          ellipsis: this.euiI18n.lookupToken(
            'euiPagination.firstRangeAriaLabel',
            'Skipping pages 2 to {lastPage}',
            { lastPage: first }
          )
        });
      } else if (first === 2) {
        buttons.push({ pageIndex: 1 });
      }
    }

    return buttons;
  }

  get lastPageButtons(): (PageButton | Ellipsis)[] {
    const buttons: (PageButton | Ellipsis)[] = [];
    const pageCount = this.pageCount;
    const last = this.lastPageInRange;

    if (last < pageCount) {
      if (last + 1 === pageCount - 1) {
        buttons.push({ pageIndex: last });
      } else if (last < pageCount - 1) {
        buttons.push({
          ellipsis: this.euiI18n.lookupToken(
            'euiPagination.lastRangeAriaLabel',
            'Skipping pages {firstPage} to {lastPage}',
            { firstPage: last + 1, lastPage: pageCount - 1 }
          )
        });
      }

      buttons.push({ pageIndex: pageCount - 1 });
    }

    return buttons;
  }

  get allPageButtons(): (PageButton | Ellipsis)[] {
    return [...this.firstPageButtons, ...this.pages, ...this.lastPageButtons];
  }

  get sharedButtonProps() {
    return {
      activePage: this.activePage,
      pageCount: this.pageCount,
      ariaControls: this.ariaControls,
      safeClick: this.safeClick
    };
  }

  get isFirstDisabled(): boolean {
    return this.activePage <= 0;
  }

  get isLastDisabled(): boolean {
    return this.activePage >= this.pageCount - 1;
  }

  get prevPageButtonProps() {
    return {
      disabled: this.isFirstDisabled,
      'aria-controls': this.ariaControls
    };
  }

  get nextPageButtonProps() {
    return {
      disabled: this.isLastDisabled,
      'aria-controls': this.ariaControls
    };
  }

  /** "{page} of {total}" split around its two numbers (upstream spans). */
  get compressedParts(): { text: string; number: boolean }[] {
    const page = { value: String(this.activePage + 1) };
    const total = { value: String(this.pageCount) };
    const parts = this.euiI18n._lookupToken({
      token: 'euiPagination.pageOfTotalCompressed',
      valueDefault: '{page} of {total}',
      values: { page, total }
    }) as unknown as string | (string | { value: string })[];
    return (Array.isArray(parts) ? parts : [parts]).map((part) =>
      typeof part === 'string'
        ? { text: part, number: false }
        : { text: part.value, number: true }
    );
  }

  /** Upstream's screen reader status, e.g. "Page 2 of 5". */
  get accessiblePageCount(): string {
    const lookup = (token: string, fallback: string) =>
      this.euiI18n.lookupToken(`euiPagination.${token}`, fallback);
    const total =
      this.pageCount === 0
        ? lookup('collection', 'collection')
        : String(this.pageCount);
    return `${lookup('page', 'Page')} ${this.activePage + 1} ${lookup('of', 'of')} ${total}`;
  }

  @cached
  get rootClass(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiPaginationStyles);
    return `euiPagination ${euiClass(context, BOX_SIZING, styles.euiPagination)}`;
  }

  @cached
  get listClass(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiPaginationStyles);
    return `euiPagination__list ${euiClass(context, LIST_RESET, styles.euiPagination__list)}`;
  }

  @cached
  get ellipsisClass(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiPaginationStyles);
    return `euiPagination__item ${euiClass(context, styles.euiPagination__ellipsis)}`;
  }

  // Read lazily where EuiText splats it, so it is inserted after EuiText's own class.
  @cached
  get compressedTextClass(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiPaginationStyles);
    return `euiPagination__compressedText ${euiClass(
      context,
      styles.euiPagination__compressedText
    )}`;
  }

  @cached
  get screenReaderOnlyClass(): string {
    return euiClass(getEuiThemeContext(this), SCREEN_READER_ONLY);
  }

  safeClick: SafeClickHandler = (pageIndex, event) => {
    // Buttons may link to `#aria-controls`; the page change happens here.
    event?.preventDefault();

    if (pageIndex < 0 || pageIndex >= this.pageCount) {
      return;
    }

    if (this.ariaControls) {
      const controlledElement = document.getElementById(this.ariaControls);

      if (controlledElement) {
        controlledElement.focus();
      }
    }

    this.args.onPageClick?.(pageIndex);
  };

  <template>
    {{!template-lint-disable no-duplicate-landmark-elements}}
    <nav class={{this.rootClass}} {{onWindowResize this.onResize}} ...attributes>
      <span class={{this.screenReaderOnlyClass}}>
        <span aria-atomic="true" aria-relevant="additions text" role="status">
          {{this.accessiblePageCount}}
        </span>
      </span>
      {{#if this.compressed}}
        <ArrowButton
          @type="first"
          @disabled={{this.isFirstDisabled}}
          @ariaControls={{this.ariaControls}}
          @onClick={{fn this.safeClick 0}}
        />
      {{/if}}
      <PreviousButton
        @activePage={{this.activePage}}
        @safeClick={{this.safeClick}}
        @props={{this.prevPageButtonProps}}
      />
      {{#if this.compressed}}
        <EuiText @size="s" class={{this.compressedTextClass}}>
          {{#each this.compressedParts as |part|}}
            {{#if part.number}}<span>{{part.text}}</span>{{else}}{{part.text}}{{/if}}
          {{/each}}
        </EuiText>
      {{else if this.pageCount}}
        <ul class={{this.listClass}}>
          {{#each this.allPageButtons as |page|}}
            {{#if (hasEllipsis page)}}
              <li aria-label={{ellipsisLabel page}} class={{this.ellipsisClass}}>
                &hellip;
              </li>
            {{else}}
              <ButtonWrapper
                @pageIndex={{pageIndexOf page}}
                @props={{this.sharedButtonProps}}
              />
            {{/if}}
          {{/each}}
        </ul>
      {{/if}}
      <NextButton
        @activePage={{this.activePage}}
        @safeClick={{this.safeClick}}
        @props={{this.nextPageButtonProps}}
        @pageCount={{this.pageCount}}
      />
      {{#if this.compressed}}
        <ArrowButton
          @type="last"
          @disabled={{this.isLastDisabled}}
          @ariaControls={{this.ariaControls}}
          @onClick={{fn this.safeClick (lastIndex this.pageCount)}}
        />
      {{/if}}
    </nav>
  </template>
}

