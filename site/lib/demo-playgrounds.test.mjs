import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  demoFiles,
  playgroundManifest,
  playgroundOverrides,
  starterFiles,
} from './demo-playgrounds.mjs';

test('the starter is a standalone Ember/Vite app with published dependencies', () => {
  const files = starterFiles();
  const pkg = JSON.parse(files['package.json']);
  assert.equal(pkg.name, 'site');
  assert.equal(pkg.scripts.start, 'vite --host 0.0.0.0');
  assert.ok(files['ember-cli-build.mjs']);
  assert.ok(files['config/environment.js']);
  assert.ok(files['app/config/environment.js']);
  assert.ok(files['babel.config.mjs']);
  assert.ok(files['index.html']);
  assert.ok(files['app/app.js'].includes('@ember-eui/core/themes/light.css'));
  assert.equal(files['app/routes/application.js'], undefined);
  assert.equal(files['app/icons/rocket.svg'], undefined);
  assert.equal(files['translations/en-us.json'], undefined);
  assert.ok(!files['app/styles/app.css'].includes('guideSideNav'));
  for (const version of Object.values(pkg.devDependencies)) {
    assert.ok(!version.startsWith('workspace:'), 'no workspace-only versions');
  }
  assert.equal(pkg.devDependencies['@docfy/ember'], undefined);
});

test('a core demo omits optional date, form, and translation dependencies', () => {
  const starter = starterFiles();
  const files = playgroundOverrides(
    [{ ext: 'hbs', code: '<EuiAccordion />' }],
    starter,
  );
  const { devDependencies } = JSON.parse(files['package.json']);
  assert.ok(devDependencies['@ember-eui/core']);
  for (const name of [
    '@ember-eui/flatpickr',
    '@ember-eui/pikaday',
    '@ember-eui/validated-form',
    '@ember-eui/changeset-form',
    'flatpickr',
    'ember-changeset',
    'ember-changeset-validations',
    'ember-intl',
  ]) {
    assert.equal(devDependencies[name], undefined, `${name} is unnecessary`);
  }
  assert.equal(
    files['app/app.js'],
    undefined,
    'the minimal app needs no extra setup',
  );
  assert.equal(files['app/routes/application.js'], undefined);
});

test('specialized demos retain their packages and setup', () => {
  const starter = starterFiles();
  const files = playgroundOverrides(
    [
      {
        ext: 'hbs',
        code: '<EuiFlatpickr /><EuiPikaday /><ValidatedForm /><EuiChangesetForm />{{t "label"}}',
      },
    ],
    starter,
  );
  const { devDependencies } = JSON.parse(files['package.json']);
  for (const name of [
    '@ember-eui/flatpickr',
    '@ember-eui/pikaday',
    '@ember-eui/validated-form',
    '@ember-eui/changeset-form',
    'flatpickr',
    'ember-changeset',
    'ember-changeset-validations',
    'ember-intl',
  ]) {
    assert.ok(devDependencies[name], `${name} is required`);
  }
  assert.ok(files['app/app.js'].includes('flatpickr/dist/flatpickr.css'));
  assert.ok(files['app/routes/application.js'].includes('addTranslations'));
  assert.ok(files['translations/en-us.json']);
});

test('custom SVG demos include the plugin and assets only when needed', () => {
  const files = playgroundOverrides(
    [{ ext: 'js', code: "import Rocket from 'site/icons/rocket.svg';" }],
    starterFiles(),
  );
  assert.ok(
    JSON.parse(files['package.json']).devDependencies['@svg-jar/plugin'],
  );
  assert.ok(files['app/icons/rocket.svg']);
  assert.ok(files['vite.config.mjs'].includes('svgJar'));
  assert.ok(files['app/routes/application.js'].includes('iconsFromGlob'));
});

test('template-only demos get a component and preserve their source literally', () => {
  const code = '<EuiText>\n  {{@title}}\n</EuiText>';
  const files = demoFiles([{ ext: 'hbs', code }]);
  assert.equal(files['app/components/demo.hbs'], code);
  assert.match(files['app/components/demo.js'], /templateOnly/);
});

test('demos with backing classes keep their complete source', () => {
  const code =
    "import Component from '@ember/component';\nexport default class Demo extends Component {}";
  const files = demoFiles([
    { ext: 'js', code },
    { ext: 'hbs', code: '{{this.value}}' },
  ]);
  assert.equal(files['app/components/demo.js'], code);
  assert.equal(files['app/components/demo.hbs'], '{{this.value}}');
});

test('Docfy IDs connect playgrounds to demos, including inline previews', () => {
  const { demos } = playgroundManifest([
    {
      pluginData: {
        demoComponents: [
          {
            name: { dashCase: 'card-demo' },
            description: { title: 'Card' },
            chunks: [{ ext: 'hbs', code: '<EuiCard />' }],
          },
          {
            name: { dashCase: 'inline-preview' },
            chunks: [{ ext: 'hbs', code: '<EuiButton />' }],
          },
        ],
      },
    },
    { pluginData: {} },
  ]);
  assert.equal(demos['card-demo'].title, 'Card');
  assert.equal(demos['inline-preview'].title, 'Ember EUI demo');
  assert.equal(
    demos['inline-preview'].files['app/components/demo.hbs'],
    '<EuiButton />',
  );
});
