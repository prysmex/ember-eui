'use strict';

module.exports = {
  description: 'Installs ember-focus-trap',

  normalizeEntityName() {
    // this prevents an error when the entityName is
    // not specified
  },

  afterInstall() {
    return this.addAddonToProject('ember-focus-trap');
  }
};
