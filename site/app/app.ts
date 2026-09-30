import Application from '@ember/application';
import compatModules from '@embroider/virtual/compat-modules';
import { importSync, isDevelopingApp, macroCondition } from '@embroider/macros';
import setupInspector from '@embroider/legacy-inspector-support/ember-source-4.12';

import loadInitializers from 'ember-load-initializers';
import Resolver from 'ember-resolver';
import config from 'site/config/environment';

import '@ember-eui/core/styles/ember-eui.css';
// layout of the prose code blocks (e.g. the copy button in the corner)
import '@docfy/ember/code-block.css';
import 'flatpickr/dist/flatpickr.css';

if (macroCondition(isDevelopingApp())) {
  importSync('./deprecation-workflow');
}

export default class App extends Application {
  modulePrefix = config.modulePrefix;
  podModulePrefix = config.podModulePrefix;
  Resolver = Resolver.withModules(compatModules);
  inspector = setupInspector(this);
}

loadInitializers(App, config.modulePrefix, compatModules);
