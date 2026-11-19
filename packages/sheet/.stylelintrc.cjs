'use strict';

module.exports = {
  extends: ['stylelint-config-standard', 'stylelint-prettier/recommended'],
  rules: {
    // EUI's class names are BEM with camelCase blocks (euiFlyout__body)
    'selector-class-pattern': null,
  },
};
