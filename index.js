"use strict";
const path = require("path");
const resolve = require("resolve");
const BroccoliMergeTrees = require("broccoli-merge-trees");
const writeFile = require("broccoli-file-creator");
const Funnel = require("broccoli-funnel");
const EuiScssFilter = require("./lib/elastic-eui-scss-filter");

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

    this.emberEuiOptions = Object.assign({}, app.options["ember-eui"]);

   
    if(this.emberEuiOptions.theme) {
      app.import(`node_modules/@elastic/eui/dist/eui_theme_${this.emberEuiOptions.theme}.min.css`);
    } else {
      app.import("node_modules/@elastic/eui/dist/eui_theme_light.min.css");
    }

    
  },

  

  // TODO: Currently the performance of recompiling sass on every change are serious, find a way to improve them.
  // treeForStyles(tree) {
  //   let selectedTheme = this.emberEuiOptions.theme || this.config.theme;

  //   let euiScssFiles = new Funnel(this.pathBase("@elastic/eui"), {
  //     srcDir: "/src",
  //     include: ["**/*.scss"],
  //     destDir: "elastic-eui",
  //     annotation: "ElasticEUIScssFunnel",
  //   });

  //   euiScssFiles = new EuiScssFilter(euiScssFiles);

  //   console.log(euiScssFiles);
  //   let importer = writeFile(
  //     "ember-eui-components.scss",
  //     `@import './elastic-eui/theme_light.scss';`
  //   );

  //   let mergedTrees = new BroccoliMergeTrees([euiScssFiles, importer, tree], {
  //     overwrite: true,
  //   });
  //   return this._super.treeForStyles(mergedTrees);
  // },

  // pathBase(packageName) {
  //   return path.dirname(
  //     resolve.sync(`${packageName}/package.json`, { basedir: __dirname })
  //   );
  // },
};
