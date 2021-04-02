import EmberPowerSelectOptions from 'ember-power-select/components/power-select/options';
import { emberPowerSelectIsGroup } from 'ember-power-select/helpers/ember-power-select-is-group';
import { cached } from '@glimmer/tracking';

export default class EuiComboBoxOptionsComponent extends EmberPowerSelectOptions {
  @cached
  get flattedOptions() {
    return this.args.options.reduce((acc, curr) => {
      return [
        ...acc,
        ...(emberPowerSelectIsGroup([curr]) ? [curr, ...curr.options] : [curr])
      ];
    }, []);
  }

  _optionFromIndex(index) {
    let parts = index.split('.');
    let option = this.flattedOptions[parseInt(parts[0], 10)];
    for (let i = 1; i < parts.length; i++) {
      option = option.options[parseInt(parts[i], 10)];
    }
    return option;
  }
}
