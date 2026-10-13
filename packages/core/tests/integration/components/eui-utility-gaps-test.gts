import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiTimeline from '#src/components/eui-timeline.gts';
import {
  euiContainerCSS,
  euiContainerQuery,
  euiScrollBarStyles,
  euiYScroll,
  euiYScrollWithShadows
} from '#src/theming.ts';
import { htmlIdGenerator } from '#src/utils/html-id-generator.ts';

import type { EuiThemeStyleContext } from '#src/theming.ts';

module('Integration | Utilities | htmlIdGenerator', function () {
  test('generates unique ids with an optional prefix and suffix', function (assert) {
    const generate = htmlIdGenerator();
    const a = generate();
    const b = generate();
    assert.ok(a.startsWith('i'));
    assert.notStrictEqual(a, b);
    assert.ok(htmlIdGenerator('foo')().startsWith('foo_'));
    assert.ok(htmlIdGenerator()('bar').endsWith('_bar'));
    assert.ok(htmlIdGenerator('foo')('bar').match(/^foo_.+_bar$/));
  });

  test('suffixed ids from one generator share the unique part', function (assert) {
    const generate = htmlIdGenerator('test');
    const label = generate('label');
    const input = generate('input');
    const unique = (id: string) => id.replace(/^test_/, '').replace(/_[a-z]+$/, '');
    assert.strictEqual(unique(label), unique(input));
    assert.notStrictEqual(label, input);
    assert.notStrictEqual(generate(), generate(), 'no suffix: always unique');
  });
});

module('Integration | Utilities | theming style helpers', function (hooks) {
  setupRenderingTest(hooks);

  const containerCss = euiContainerCSS('inline-size', 'card');
  const scrollCss = (theme: EuiThemeStyleContext) =>
    euiYScroll(theme, { height: '100px' });
  const shadowCss = (theme: EuiThemeStyleContext) => euiYScrollWithShadows(theme);
  const barCss = (theme: EuiThemeStyleContext) =>
    euiScrollBarStyles(theme, { width: 'auto' });

  test('euiContainerCSS and euiContainerQuery', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiTimeline id="c" @css={{containerCss}} />
        </EuiEmotionProvider>
      </template>
    );
    const style = getComputedStyle(document.getElementById('c')!);
    assert.strictEqual(style.containerType, 'inline-size');
    assert.strictEqual(style.containerName, 'card');
    assert.strictEqual(euiContainerQuery('(width < 300px)'), '@container (width < 300px)');
    assert.strictEqual(euiContainerQuery('(width < 300px)', 'card'), '@container card (width < 300px)');
  });

  test('euiYScroll, euiYScrollWithShadows and euiScrollBarStyles', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiTimeline id="y" @css={{scrollCss}} />
          <EuiTimeline id="s" @css={{shadowCss}} />
          <EuiTimeline id="b" @css={{barCss}} />
        </EuiEmotionProvider>
      </template>
    );
    const y = getComputedStyle(document.getElementById('y')!);
    assert.strictEqual(y.overflowY, 'auto');
    assert.strictEqual(y.overflowX, 'hidden');
    assert.strictEqual(y.height, '100px');
    assert.ok(getComputedStyle(document.getElementById('s')!).maskImage.includes('linear-gradient'));
    assert.strictEqual(getComputedStyle(document.getElementById('b')!).scrollbarWidth, 'auto');
  });
});
