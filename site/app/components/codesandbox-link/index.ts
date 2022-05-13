import Component from '@glimmer/component';
import { getParameters } from 'codesandbox/lib/api/define';
//@ts-expect-error
import docfySnippets from 'site/docfy-snippets.json';

import config from 'ember-get-config';

const packageJson = config.packageJson;

interface Args {
  theme?: string;
  componentName: string;
}

function removeDeps(deps: Record<string, string>) {
  return Object.fromEntries(
    Object.entries(deps).filter(([key]) => {
      return (
        !key.match(/@types/gi) &&
        !key.match(/typescript/gi) &&
        !key.match(/postcss/gi) &&
        !key.match(/broccoli-file-creator/gi) &&
        !key.match(/ember-intl/gi) &&
        !key.match(/ember-href-to/gi) &&
        !key.match(/ember-cli-netlify/gi) &&
        !key.match(/ember-get-config/gi) &&
        !key.match(/docfy/gi) &&
        !key.match(/webpack-bundle-analyzer/gi)
      );
    })
  );
}

export default class CodesandboxLink extends Component<Args> {
  get params() {
    console.log(this.args.componentName);
    const hbsFile = docfySnippets.components[this.args.componentName].hbs;
    const jsFile = docfySnippets.components[this.args.componentName].js;

    const componentName = '<Demo />';
    const appName = '';
    const appNameSpace = `${appName}/app`;
    const testsNameSpace = `tests`;
    const configNameSpace = `config`;
    const theme = this.args.theme || 'amsterdam_light';

    const removedDeps = removeDeps(packageJson.devDependencies);
    delete packageJson.dependencies;
    delete packageJson.volta;

    const config = {
      files: {
        [`package.json`]: {
          content: {
            ...packageJson,
            name: 'site',
            description: `${componentName} demo`,
            devDependencies: {
              ...removedDeps
            }
          }
        },
        [`${appNameSpace}/components/todo-text.hbs`]: {
          content: `<EuiText style="margin-bottom: 16px;">
					<h4>
						🚧<span style="margin: 0px 10px 0px 10px">{{if @text @text 'To do'}}</span>🚧
					</h4>
				</EuiText>`
        },
        [`${appNameSpace}/components/demo.js`]: {
          content: jsFile
        },
        [`${appNameSpace}/components/demo.hbs`]: {
          content: hbsFile
        },
        [`${appNameSpace}/templates/application.hbs`]: {
          content: `${componentName}`
        },
        [`${appNameSpace}/styles/app.css`]: {
          content: ``
        },
        [`${appNameSpace}/controllers/.gitkeep`]: {
          content: ``
        },
        [`${appNameSpace}/routes/.gitkeep`]: {
          content: ``
        },
        [`${appNameSpace}/helpers/.gitkeep`]: {
          content: ``
        },
        [`${appNameSpace}/app.js`]: {
          content: `import Application from '@ember/application';
					import Resolver from 'ember-resolver';
					import loadInitializers from 'ember-load-initializers';
					import config from 'site/config/environment';
					
					export default class App extends Application {
						modulePrefix = config.modulePrefix;
						podModulePrefix = config.podModulePrefix;
						Resolver = Resolver;
					}
					
					loadInitializers(App, config.modulePrefix);
					`
        },
        [`${appNameSpace}/router.js`]: {
          content: `import EmberRouter from '@ember/routing/router';
					import config from 'site/config/environment';
					
					export default class Router extends EmberRouter {
						location = config.locationType;
						rootURL = config.rootURL;
					}
					
					Router.map(function () {});
					`
        },
        [`${appNameSpace}/index.html`]: {
          content: `<!DOCTYPE html>
					<html>
						<head>
							<meta charset="utf-8" />
							<meta http-equiv="X-UA-Compatible" content="IE=edge" />
							<title>Ember Eui</title>
							<meta name="description" content="" />
							<meta name="viewport" content="width=device-width, initial-scale=1" />
					
							{{content-for "head"}}
					
							<link integrity="" rel="stylesheet" href="{{rootURL}}assets/vendor.css" />
							<link integrity="" rel="stylesheet" href="{{rootURL}}assets/site.css" />
							{{content-for "head-footer"}}
						</head>
						<body>
							{{content-for "body"}}
					
							<script src="{{rootURL}}assets/vendor.js"></script>
							<script src="{{rootURL}}assets/site.js"></script>
					
							{{content-for "body-footer"}}
						</body>
					</html>
					`
        },
        [`${testsNameSpace}/test-helper.js`]: {
          content: `import Application from 'site/app';
					import config from 'site/config/environment';
					import * as QUnit from 'qunit';
					import { setApplication } from '@ember/test-helpers';
					import { setup } from 'qunit-dom';
					import { start } from 'ember-qunit';
					
					setApplication(Application.create(config.APP));
					
					setup(QUnit.assert);
					
					start();`
        },
        [`${testsNameSpace}/index.html`]: {
          content: `<!DOCTYPE html>
					<html>
						<head>
							<meta charset="utf-8">
							<meta http-equiv="X-UA-Compatible" content="IE=edge">
							<title>Site Tests</title>
							<meta name="description" content="">
							<meta name="viewport" content="width=device-width, initial-scale=1">
					
							{{content-for "head"}}
							{{content-for "test-head"}}
					
							<link rel="stylesheet" href="{{rootURL}}assets/vendor.css">
							<link rel="stylesheet" href="{{rootURL}}assets/site.css">
							<link rel="stylesheet" href="{{rootURL}}assets/test-support.css">
					
							{{content-for "head-footer"}}
							{{content-for "test-head-footer"}}
						</head>
						<body>
							{{content-for "body"}}
							{{content-for "test-body"}}
					
							<div id="qunit"></div>
							<div id="qunit-fixture">
								<div id="ember-testing-container">
									<div id="ember-testing"></div>
								</div>
							</div>
					
							<script src="/testem.js" integrity="" data-embroider-ignore></script>
							<script src="{{rootURL}}assets/vendor.js"></script>
							<script src="{{rootURL}}assets/test-support.js"></script>
							<script src="{{rootURL}}assets/site.js"></script>
							<script src="{{rootURL}}assets/tests.js"></script>
					
							{{content-for "body-footer"}}
							{{content-for "test-body-footer"}}
						</body>
					</html>					
					`
        },
        [`${configNameSpace}/environment.js`]: {
          content: `'use strict';
					module.exports = function (environment) {
						let ENV = {
							modulePrefix: 'demo-codesandbox',
							environment,
							rootURL: '/',
							locationType: 'history',
							EmberENV: {
								FEATURES: {
									// Here you can enable experimental features on an ember canary build
									// e.g. EMBER_NATIVE_DECORATOR_SUPPORT: true
								},
								EXTEND_PROTOTYPES: {
									// Prevent Ember Data from overriding Date.parse.
									Date: false,
								},
							},
					
							APP: {
								// Here you can pass flags/options to your application instance
								// when it is created
							},
						};
					
						if (environment === 'development') {
							// ENV.APP.LOG_RESOLVER = true;
							// ENV.APP.LOG_ACTIVE_GENERATION = true;
							// ENV.APP.LOG_TRANSITIONS = true;
							// ENV.APP.LOG_TRANSITIONS_INTERNAL = true;
							// ENV.APP.LOG_VIEW_LOOKUPS = true;
						}
					
						if (environment === 'test') {
							// Testem prefers this...
							ENV.locationType = 'none';
					
							// keep test console output quieter
							ENV.APP.LOG_ACTIVE_GENERATION = false;
							ENV.APP.LOG_VIEW_LOOKUPS = false;
					
							ENV.APP.rootElement = '#ember-testing';
							ENV.APP.autoboot = false;
						}
					
						if (environment === 'production') {
							// here you can enable a production-specific feature
						}
					
						return ENV;
					};
					`
        },
        [`${configNameSpace}/targets.js`]: {
          content: `'use strict';

					const browsers = [
						'last 1 Chrome versions',
						'last 1 Firefox versions',
						'last 1 Safari versions',
					];
					
					module.exports = {
						browsers,
					};					
					`
        },
        [`${configNameSpace}/optional-features.json`]: {
          content: `{
						"application-template-wrapper": false,
						"default-async-observers": true,
						"jquery-integration": false,
						"template-only-glimmer-components": true
					}
					`
        },
        'ember-cli-build.js': {
          content: `'use strict';
					
					const EmberApp = require('ember-cli/lib/broccoli/ember-app');
					
					module.exports = function (defaults) {
					
						let app = new EmberApp(defaults, {
					
							// Add options here
							'@ember-eui/core': {
								theme: "${theme}"
							},
					
							svgJar: {
								sourceDirs: [
									'public/assets',
									'node_modules/@elastic/eui/lib/components/icon'
								]
							}
						});
					
						const { Webpack } = require('@embroider/webpack');

						return require('@embroider/compat').compatBuild(app, Webpack, {
							staticAddonTestSupportTrees: true,
							staticAddonTrees: true,
							staticHelpers: true,
							staticModifiers: true,
							staticComponents: true,
							splitAtRoutes: ['*'],
						});
					};
					`
        },
        '.watchmanconfig': {
          content: `{
						"ignore_dirs": ["tmp", "dist"]
					}
					`
        },
        [`public/robots.txt`]: {
          content: `# http://www.robotstxt.org
					User-agent: *
					Disallow:
					`
        }
      }
    };

    //@ts-expect-error
    return getParameters(config);
  }
}
