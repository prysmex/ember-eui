"use strict";
const path = require("path");
const resolve = require("resolve");
const BroccoliMergeTrees = require("broccoli-merge-trees");
const writeFile = require("broccoli-file-creator");
const Funnel = require("broccoli-funnel");
const EuiScssFilter = require('./lib/elastic-eui-scss-filter');

module.exports = {
  name: require("./package").name,

  inDevelopingAddon() {
    return true;
  },

  included() {
    this._super.included.apply(this, arguments);
    let app;

    // If the addon has the _findHost() method (in ember-cli >= 2.7.0), we'll just
    // use that.
    if (typeof this._findHost === "function") {
      app = this._findHost();
    } else {
      // Otherwise, we'll use this implementation borrowed from the _findHost()
      // method in ember-cli.
      let current = this;
      do {
        app = current.app || app;
      } while (current.parent.parent && (current = current.parent));
    }

    this.emberEuiOptions = Object.assign(
      { ...this.config },
      app.options["ember-eui"]
    );
  },

  config() {
    return {
      "ember-eui": {
        theme: "light",
      },
    };
  },

  treeForStyles(tree) {
    let selectedTheme = this.emberEuiOptions.theme || this.config.theme;
    console.log(selectedTheme);

    let euiScssFiles = new Funnel(this.pathBase("@elastic/eui"), {
      srcDir: "/src",
      include: ["**/*.scss"],
      destDir: "elastic-eui",
      annotation: "ElasticEUIScssFunnel",
    });

    euiScssFiles = new EuiScssFilter(euiScssFiles);

    console.log(euiScssFiles);
    let importer = writeFile(
      "ember-eui-components.scss",
      `@import './elastic-eui/theme_light.scss';`
    );

    let mergedTrees = new BroccoliMergeTrees([euiScssFiles, importer, tree], {
      overwrite: true,
    });
    return this._super.treeForStyles(mergedTrees);
  },

  /*
    Rely on the `resolve` package to mimic node's resolve algorithm.
    It finds the angular-material-source module in a manner that works for npm 2.x,
    3.x, and yarn in both the addon itself and projects that depend on this addon.
    This is an edge case b/c angular-material-source does not have a main
    module we can require.resolve through node itself and similarily ember-cli
    does not have such a hack for the same reason.
    tl;dr - We want the non built scss files, and b/c this dep is only provided via
    git, we use this hack. Please change it if you read this and know a better way.
  */
  pathBase(packageName) {
    return path.dirname(
      resolve.sync(`${packageName}/package.json`, { basedir: __dirname })
    );
  },
};
