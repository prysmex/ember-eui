import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked, cached } from '@glimmer/tracking';
//@ts-ignore
import { emberPowerSelectIsGroup } from 'ember-power-select/helpers/ember-power-select-is-group';
import { isEqual } from '@ember/utils';

interface PromiseProxy<T> extends Promise<T> {
  content: any;
}

interface EuiComboBoxArgs {
  singleSelection: boolean;
  onCreateOption?: (search: string) => boolean | undefined;
  options: any[];
  search?: (term: string, select: Select) => any[] | PromiseProxy<any[]>;
}

interface Select {
  selected: any;
  actions: {
    search: (str: string) => void;
  };
}

interface Arrayable<T> {
  toArray(): T[];
}
const isArrayable = <T>(coll: any): coll is Arrayable<T> => {
  return typeof coll.toArray === 'function';
};

const toPlainArray = <T>(collection: T[] | Arrayable<T>): T[] => {
  if (isArrayable<T>(collection)) {
    return collection.toArray();
  } else {
    return collection;
  }
};

export default class EuiComboBoxComponent extends Component<EuiComboBoxArgs> {
  @tracked select: any = null;
  @tracked private _resolvedOptions?: any[];
  @tracked searchText = '';
  @tracked private _searchResult?: any[];
  private _filterResultsCache: {
    results: any[];
    options: any[];
    searchText: string;
  } = { results: [], options: [], searchText: this.searchText };

  //This is to allow scrolling between virtualized groups
  @cached
  get opts() {
    //@ts-ignore
    return this.results.reduce((acc, curr) => {
      if (emberPowerSelectIsGroup([curr])) {
        acc.push(curr, ...curr.options);
      } else {
        acc.push(curr);
      }
      return acc;
    }, []);
  }

  @cached
  get options(): any[] {
    if (this._resolvedOptions) return toPlainArray(this._resolvedOptions);
    if (this.args.options) {
      return toPlainArray(this.args.options);
    } else {
      return [];
    }
  }

  @cached
  get results(): any[] {
    if (this.searchText.length > 0) {
      if (this.args.search) {
        return toPlainArray(this._searchResult || this.options);
      } else {
        if (
          this._filterResultsCache.options === this.options &&
          this._filterResultsCache.searchText === this.searchText
        ) {
          // This is an optimization to avoid filtering several times, which may be a bit expensive
          // if there are many options, if neither the options nor the searchtext have changed
          return this._filterResultsCache.results;
        }
        //@ts-ignore
        let results = this._filter(this.options, this.searchText);
        //eslint-disable-next-line
        this._filterResultsCache = {
          results,
          options: this.options,
          searchText: this.searchText
        };
        return results;
      }
    } else {
      return this.options;
    }
  }

  @action
  scrollTo(option: any, select: { results: []; uniqueId: string }): void {
    let optionsList = document.querySelector(
      `[aria-controls="ember-power-select-trigger-${select.uniqueId}"]`
    ) as HTMLElement;
    if (!optionsList) {
      return;
    }

    let index = this.opts.indexOf(option);

    if (index === -1) {
      return;
    }

    let optionElement = optionsList.querySelector(
      `[data-option-index="${index}"]`
    ) as HTMLElement;

    if (!optionElement) {
      return;
    }

    let optionTopScroll = optionElement.offsetTop;
    let optionBottomScroll = optionTopScroll + optionElement.offsetHeight;

    if (optionBottomScroll > optionsList.offsetHeight + optionsList.scrollTop) {
      optionsList.scrollTop = optionBottomScroll - optionsList.offsetHeight;
    } else if (optionTopScroll < optionsList.scrollTop) {
      optionsList.scrollTop = optionTopScroll;
    }
  }

  @action
  registerAPI(select: Select) {
    this.select = select;
  }

  @action
  onChange(selected: any) {
    if (this.args.singleSelection) {
      return selected.length > 0 ? [selected[selected.length - 1]] : [];
    }
    return selected;
  }

  @action
  onCreateOption() {
    let option;
    if (
      this.args.onCreateOption &&
      typeof this.args.onCreateOption === 'function'
    ) {
      // The `onCreateOption` function can be used to sanitize the input or explicitly return `false` to reject the input
      option = this.args.onCreateOption(this.select.searchText);
      if (option === false) {
        return;
      }
    }
    let search = option || this.select.searchText;
    this.select.actions.search('');
    this.select.actions.close();
    return search;
  }

  @action
  buildSelection(option: any, select: Select) {
    let newSelection = (select.selected || []).slice(0);
    let idx = -1;
    for (let i = 0; i < newSelection.length; i++) {
      if (isEqual(newSelection[i], option)) {
        idx = i;
        break;
      }
    }
    if (idx > -1) {
      newSelection.splice(idx, 1);
    } else {
      newSelection.push(option);
    }

    if (this.args.singleSelection && newSelection.length === 0) {
      select.actions.search('');
    }
    if (select?.selected?.length < newSelection.length) {
      select.actions.search('');
    }
    return newSelection;
  }
}
