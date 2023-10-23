import EmberPowerSelectOptions from 'ember-power-select/components/power-select/options';
import { emberPowerSelectIsGroup } from 'ember-power-select/helpers/ember-power-select-is-group';

let config = {};

export default class EuiComboBoxOptionsComponent extends EmberPowerSelectOptions {
  _optionsCache = [];

  get flattedOptions() {
    if (this._optionsCache !== this.args.options) {
      this._optionsCache = this.args.options;
      return this.args.options?.reduce((acc, curr) => {
        if (emberPowerSelectIsGroup([curr])) {
          acc.push(curr, ...curr.options);
        } else {
          acc.push(curr);
        }
        return acc;
      }, []);
    }
    return this._optionsCache;
  }

  _optionFromIndex(index) {
    let parts = index.split('.');
    let option = this.flattedOptions.at?.(parseInt(parts[0], 10));
    for (let i = 1; i < parts.length; i++) {
      option = option.options[parseInt(parts[i], 10)];
    }
    return option;
  }

  get configRowHeight() {
    //@ts-expect-error
    return config?.['@ember-eui/core']?.euiComboBoxOptionsHeight || 29;
  }

  get rowHeight() {
    return this.args.rowHeight ?? this.configRowHeight;
  }
}
