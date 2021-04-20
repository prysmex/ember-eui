import EmberPowerSelectMultipleTrigger from 'ember-power-select/components/power-select-multiple/trigger';
import { action } from '@ember/object';
import { isBlank } from '@ember/utils';

export default class EuiComboBoxTriggerComponent extends EmberPowerSelectMultipleTrigger {
  @action
  handleKeydown(e) {
    if (e.target === null) return;
    if (this.args.onKeydown && this.args.onKeydown(e) === false) {
      if (
        e.keyCode === 13 &&
        this.args.select.options.length == 0 &&
        this.args.onCreateOption &&
        this.args.select.searchText.length >= 1 &&
        this.args.select.results.length == 0
      ) {
        this.args.onCreateOption();
        return false;
      }
      e.stopPropagation();
      return false;
    }
    if (e.keyCode === 8) {
      e.stopPropagation();
      if (isBlank(e.target.value)) {
        let lastSelection = this.args.select.selected[
          this.args.select.selected.length - 1
        ];
        if (lastSelection) {
          this.args.select.actions.select(
            this.args.buildSelection(lastSelection, this.args.select),
            e
          );
          this.args.select.actions.search('');
          this.args.select.actions.open(e);
        }
      }
    } else if ((e.keyCode >= 48 && e.keyCode <= 90) || e.keyCode === 32) {
      // Keys 0-9, a-z or SPACE
      e.stopPropagation();
    }
  }

  @action
  submitSearchInput(e) {
    e.preventDefault();
  }
}
