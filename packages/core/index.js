'use strict';
const path = require('path');
const resolve = require('resolve');
const BroccoliMergeTrees = require('broccoli-merge-trees');
const writeFile = require('broccoli-file-creator');
const Funnel = require('broccoli-funnel');
const EuiScssFilter = require('./lib/elastic-eui-scss-filter');

module.exports = {
  name: require('./package').name,

  inDevelopingAddon() {
    return true;
  },

  included() {
    this._super.included.apply(this, arguments);
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

    this.emberEuiOptions = Object.assign({}, app.options['@ember-eui/core']);

    this.emberEuiOptions.theme = this.emberEuiOptions.theme ? this.emberEuiOptions.theme : 'light';

    if (this.emberEuiOptions.useCompiledCss !== false) {
      if (this.emberEuiOptions.theme) {
        app.import(
          `node_modules/@elastic/eui/dist/eui_theme_${this.emberEuiOptions.theme}.min.css`
        );
      } else {
        app.import('node_modules/@elastic/eui/dist/eui_theme_light.min.css');
      }
    }
  },

  // TODO: Currently the performance of recompiling sass on every change are serious, find a way to improve them.
  treeForStyles(tree) {
    let trees = [];
    let euiScssFiles;

    if (this.emberEuiOptions.useCompiledCss === false) {
      euiScssFiles = new Funnel(this.pathBase('@elastic/eui'), {
        srcDir: '/src',
        include: ['**/*.scss'],
        destDir: 'elastic-eui',
        annotation: 'ElasticEUIScssFunnel'
      });

      euiScssFiles = new EuiScssFilter(euiScssFiles);

      trees.push(euiScssFiles);
    }

    let selectedTheme = this.emberEuiOptions.theme;

    let importer = writeFile(
      'eui-components.scss',
      euiScssFiles ? `@import './elastic-eui/theme_${selectedTheme}.scss';` : ''
    );

    trees.push(importer);

    trees.push(tree);

    let output = new BroccoliMergeTrees(trees, {
      overwrite: true
    });

    return this._super.treeForStyles(output);
  },

  pathBase(packageName) {
    return path.dirname(resolve.sync(`${packageName}/package.json`, { basedir: __dirname }));
  }
};
