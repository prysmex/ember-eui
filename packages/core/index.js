'use strict';

module.exports = {
  name: require('./package').name,

  options: {
    'ember-power-select': {
      theme: false
    }
  },

  isDevelopingAddon() {
    return true;
  },

  included() {
    let app;

    // If the addon has the _findHost() method (in ember-cli >= 2.7.0), we'll just
    // use that.
    if (typeof this._findHost === 'function') {
      app = this._findHost();
    } else {
      // Otherwise, we'll use this implementation borrowed from the _findHost()
      // method in ember-cli.
      //eslint-disable-next-line
      let current = this;
      do {
        app = current.app || app;
      } while (current.parent.parent && (current = current.parent));
    }

    //ensure we don't include ember-power-select styles.
    const powerSelectOptions = app.options['ember-power-select'] || {};
    powerSelectOptions.theme = false;
    app.options['ember-power-select'] = powerSelectOptions;

    // make sure to include ember-basic-dropdown styles
    app.__skipEmberBasicDropdownStyles = true;
    app.import(
      'node_modules/ember-basic-dropdown/vendor/ember-basic-dropdown.css'
    );

    this.emberEuiOptions = Object.assign({}, app.options['@ember-eui/core']);

    this.emberEuiOptions.theme = this.emberEuiOptions.theme
      ? this.emberEuiOptions.theme
      : 'amsterdam_light';

    if (this.emberEuiOptions.theme) {
      app.import(
        `node_modules/@elastic/eui/dist/eui_theme_${this.emberEuiOptions.theme}.min.css`
      );
    } else {
      app.import(
        'node_modules/@elastic/eui/dist/eui_theme_amsterdam_light.min.css'
      );
    }

    this._super.included.apply(this, arguments);
  },

  contentFor(type, config) {
    const emberPowerSelect = this.addons.find(
      (a) => a.name === 'ember-power-select'
    );
    return emberPowerSelect.contentFor(type, config);
  }
};
