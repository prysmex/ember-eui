import EmberPowerSelectOptions from 'ember-power-select/components/power-select/options';
import { emberPowerSelectIsGroup } from 'ember-power-select/helpers/ember-power-select-is-group';
import { tracked } from '@glimmer/tracking';

export default class EuiComboBoxOptionsComponent extends EmberPowerSelectOptions {
  @tracked flattedOptions = [];
  _optionsCache = [];

  setFlattedOptions = () => {
    if (this._optionsCache !== this.args.options) {
      this.flattedOptions = this.args.options?.reduce((acc, curr) => {
        if (emberPowerSelectIsGroup([curr])) {
          acc.push(curr, ...curr.options);
        } else {
          acc.push(curr);
        }
        return acc;
      }, []);
      this._optionsCache = this.args.options;
    }
  };

  constructor() {
    super(...arguments);
    this.setFlattedOptions();
    this._optionsCache = this.args.options;
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
