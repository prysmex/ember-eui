import EmberPowerSelectMultipleTrigger from 'ember-power-select/components/power-select-multiple/trigger';
import { action } from '@ember/object';
import { isBlank } from '@ember/utils';
import { scheduleOnce } from '@ember/runloop';
import { htmlSafe } from '@ember/template';

export default class EuiComboBoxTriggerComponent extends EmberPowerSelectMultipleTrigger {
  get triggerMultipleInputStyle() {
    scheduleOnce('actions', null, this.args.select.actions.reposition);

    let textWidth = 0;
    if (this.inputFont) {
      textWidth = this.textMeasurer.width(
        this.args.select.searchText,
        this.inputFont
      );
    }
    return htmlSafe(`box-sizing: content-box; width: ${textWidth + 2}px`);
  }

  @action
  handleKeydown(e) {
    if (e.target === null) return;
    if (this.args.onKeydown && this.args.onKeydown(e) === false) {
      if (
        this.args.onCreateOption && //if user wants to create an option and
        e.keyCode === 13 && //presses [Enter] and
        (this.args.select.options.length === 0 || //If There are no options or
          this.args.select.results.length === 0) && //Last search made returned no results and
        this.args.select.searchText.length >= 1 //There's something in the searchText box
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
        let lastSelection =
          this.args.select.selected[this.args.select.selected.length - 1];
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
}
