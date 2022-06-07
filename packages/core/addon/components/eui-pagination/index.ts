import Component from '@glimmer/component';

export type PageClickHandler = (pageIndex: number) => void;
type SafeClickHandler = (pageIndex: number) => void;

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

export default class EuiPaginationComponent extends Component<Args> {
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
}
