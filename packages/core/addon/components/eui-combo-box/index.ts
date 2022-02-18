import Component from '@glimmer/component';
import { action } from '@ember/object';
// @ts-ignore
import { indexOfOption } from 'ember-power-select/utils/group-utils';
import { tracked } from '@glimmer/tracking';
import { isEqual } from '@ember/utils';

interface EuiComboBoxArgs {
  singleSelection: boolean;
}

interface Select {
  selected: any;
  actions: {
    search: (str: string) => void;
  };
}

export default class EuiComboBoxComponent extends Component<EuiComboBoxArgs> {
  @tracked select: any = null;

  @action
  scrollTo(option: any, select: { results: []; uniqueId: string }): void {
    let optionsList = document.querySelector(
      `[aria-controls="ember-power-select-trigger-${select.uniqueId}"]`
    ) as HTMLElement;
    if (!optionsList) {
      return;
    }
    let index = indexOfOption(select.results, option);
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
    let search = this.select.searchText;
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
