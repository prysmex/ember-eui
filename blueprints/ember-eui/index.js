'use strict'

module.exports = {
  description: 'Installs ember-cli-sass',

  normalizeEntityName() {
    // this prevents an error when the entityName is
    // not specified
  },

  afterInstall() {
    return this.addAddonToProject('ember-cli-sass');
  }
};