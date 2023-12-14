import Component from '@glimmer/component';
import { hash } from '@ember/helper';

import add from 'ember-math-helpers/helpers/add';
import sub from 'ember-math-helpers/helpers/sub';

import EuiHideFor from './eui-hide-for.gts';
import EuiI18n from './eui-i18n.gts';
import ButtonWrapper from './eui-pagination/button-wrapper.gts';
import NextButton from './eui-pagination/next-button.gts';
import PreviousButton from './eui-pagination/previous-button.gts';
import EuiText from './eui-text.gts';

import type { EuiHideForBreakpoints } from './eui-hide-for.gts';

const BREAKPOINTS: EuiHideForBreakpoints[] = ['xs', 's'];

export type PageClickHandler = (pageIndex: number) => void;
export type SafeClickHandler = (pageIndex: number) => void;

interface Args {
  /**
   * The total number of pages.
   */
  pageCount?: number;

  /**
   * The current page using a zero based index.
   * So if you set the activePage to 1, it will activate the second page.
   */
  activePage?: number;

  onPageClick?: PageClickHandler;

  /**
   * If true, will only show next/prev arrows instead of page numbers.
   */
  compressed?: boolean;

  /**
   * If passed in, passes value through to each button to set aria-controls
   */
  'aria-controls'?: string;
  ariaControls?: string;
}

const MAX_VISIBLE_PAGES = 5;
const NUMBER_SURROUNDING_PAGES = Math.floor(MAX_VISIBLE_PAGES * 0.5);

export interface EuiPaginationSignature {
  Element: HTMLElement;
  Args: Args;
}

export default class EuiPaginationComponent extends Component<EuiPaginationSignature> {
  get pageCount() {
    return this.args.pageCount ?? 1;
  }

  get activePage() {
    return this.args.activePage ?? 0;
  }

  get ariaControls() {
    return this.args['aria-controls'] || this.args.ariaControls;
  }

  get hasControl() {
    return this.ariaControls !== undefined;
  }

  get pages() {
    let pages = [];
    const { firstPageInRange, lastPageInRange } = this;

    for (
      let i = firstPageInRange, index = 0;
      i < lastPageInRange;
      i++, index++
    ) {
      pages.push({
        pageIndex: i
      });
    }

    return pages;
  }

  get firstPageButtons() {
    let firstPageButtons = [];

    if (this.firstPageInRange > 0) {
      firstPageButtons.push({
        pageIndex: 0
      });

      if (this.firstPageInRange > 1 && this.firstPageInRange !== 2) {
        firstPageButtons.push({
          i18n: {
            key: 'startingEllipses',
            token: 'euiPagination.firstRangeAriaLabel',
            default: 'Skipping pages 2 to {lastPage}',
            values: { lastPage: this.firstPageInRange }
          }
        });
      } else if (this.firstPageInRange === 2) {
        firstPageButtons.push({ pageIndex: 1 });
      }
    }

    return firstPageButtons;
  }

  get lastPageButtons() {
    let lastPageButtons = [];
    let pageCount = this.pageCount;
    let lastPageInRange = this.lastPageInRange;

    if (lastPageInRange < pageCount) {
      if (lastPageInRange + 1 === pageCount - 1) {
        lastPageButtons.push({ pageIndex: lastPageInRange });
      } else if (lastPageInRange < pageCount - 1) {
        lastPageButtons.push({
          i18n: {
            key: 'endingEllipses',
            token: 'euiPagination.lastRangeAriaLabel',
            default: 'Skipping pages {firstPage} to {lastPage}',
            values: { firstPage: lastPageInRange + 1, lastPage: pageCount - 1 }
          }
        });
      }

      lastPageButtons.push({ pageIndex: pageCount - 1 });
    }

    return lastPageButtons;
  }

  get sharedButtonProps() {
    return {
      activePage: this.activePage,
      pageCount: this.pageCount,
      ariaControls: this.ariaControls,
      safeClick: this.safeClick
    };
  }

  get prevPageButtonProps() {
    let prevPageButtonProps = {};

    if (this.hasControl && this.activePage !== 0) {
      prevPageButtonProps = {
        'aria-controls': this.ariaControls,
        href: `#${this.ariaControls}`
      };
    } else {
      prevPageButtonProps = { disabled: this.activePage === 0 };
    }

    return prevPageButtonProps;
  }

  get nextPageButtonProps() {
    let nextPageButtonProps = {};

    if (this.hasControl && this.activePage !== this.pageCount - 1) {
      nextPageButtonProps = {
        'aria-controls': this.ariaControls,
        href: `#${this.ariaControls}`
      };
    } else {
      nextPageButtonProps = {
        disabled: this.activePage === this.pageCount - 1
      };
    }

    return nextPageButtonProps;
  }

  safeClick: SafeClickHandler = (pageIndex) => {
    if (this.ariaControls) {
      const controlledElement = document.getElementById(this.ariaControls);

      if (controlledElement) {
        controlledElement.focus();
      }
    }

    this.args.onPageClick?.(pageIndex);
  };

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

  <template>
    {{#if @compressed}}
      <nav class="euiPagination" ...attributes>
        <PreviousButton
          @activePage={{this.activePage}}
          @safeClick={{this.safeClick}}
          @props={{this.prevPageButtonProps}}
        />
        <EuiHideFor @sizes={{BREAKPOINTS}}>
          <EuiText @size="s" class="euiPagination__compressedText">
            <EuiI18n
              @token="euiPagination.pageOfTotalCompressed"
              @default="{page} of {total}"
              @values={{hash
                page=(component
                  ButtonWrapper
                  pageIndex=this.activePage
                  props=this.sharedButtonProps
                  inList=false
                )
                total=(component
                  ButtonWrapper
                  pageIndex=(sub this.pageCount 1)
                  props=this.sharedButtonProps
                  inList=false
                )
              }}
              as |Token|
            >
              <Token as |value|>
                {{value}}
              </Token>
            </EuiI18n>
          </EuiText>
        </EuiHideFor>
        <NextButton
          @activePage={{this.activePage}}
          @safeClick={{this.safeClick}}
          @props={{this.nextPageButtonProps}}
          @pageCount={{this.pageCount}}
        />
      </nav>
    {{else}}
      {{!template-lint-disable no-duplicate-landmark-elements}}
      <nav class="euiPagination" ...attributes>
        <PreviousButton
          @activePage={{this.activePage}}
          @safeClick={{this.safeClick}}
          @props={{this.prevPageButtonProps}}
        />
        <ul class="euiPagination__list">
          {{#each this.firstPageButtons as |page|}}
            {{#if page.i18n}}
              <EuiI18n
                @token="euiPagination.firstRangeAriaLabel"
                @default="Skipping pages 2 to {lastPage}"
                @values={{hash lastPage=this.firstPageInRange}}
                as |Token|
              >
                <Token as |firstRangeAriaLabel|>
                  <li
                    aria-label={{firstRangeAriaLabel}}
                    class="euiPaginationButton-isPlaceholder euiPagination__item"
                  >
                    &hellip;
                  </li>
                </Token>
              </EuiI18n>
            {{else}}
              <ButtonWrapper
                @pageIndex={{page.pageIndex}}
                @props={{this.sharedButtonProps}}
              />
            {{/if}}
          {{/each}}
          {{#each this.pages as |page|}}
            <ButtonWrapper
              @pageIndex={{page.pageIndex}}
              @props={{this.sharedButtonProps}}
            />
          {{/each}}
          {{#each this.lastPageButtons as |page|}}
            {{#if page.i18n}}
              <EuiI18n
                @token="euiPagination.lastRangeAriaLabel"
                @default="Skipping pages {firstPage} to {lastPage}"
                @values={{hash
                  firstPage=(add this.lastPageInRange 1)
                  lastPage=(sub this.pageCount 1)
                }}
                as |Token|
              >
                <Token as |lastRangeAriaLabel|>
                  <li
                    aria-label={{lastRangeAriaLabel}}
                    class="euiPaginationButton-isPlaceholder euiPagination__item"
                  >
                    &hellip;
                  </li>
                </Token>
              </EuiI18n>
            {{else}}
              <ButtonWrapper
                @pageIndex={{page.pageIndex}}
                @props={{this.sharedButtonProps}}
              />
            {{/if}}
          {{/each}}
        </ul>
        <NextButton
          @activePage={{this.activePage}}
          @safeClick={{this.safeClick}}
          @props={{this.nextPageButtonProps}}
          @pageCount={{this.pageCount}}
        />
      </nav>
    {{/if}}
  </template>
}
