'use strict';

const Filter = require('broccoli-filter');

module.exports = class EuiScssFilter extends Filter {
  constructor(inputNode) {
    super(inputNode, { annotation: 'EuiScssFilter' });

    this.extensions = ['scss'];
    this.targetExtension = 'scss';
  }

  processString(content) {
    return content.replace("@import '../packages/index';", '')
  }

};