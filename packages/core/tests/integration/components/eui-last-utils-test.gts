import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, settled } from '@ember/test-helpers';
import { array, hash } from '@ember/helper';
import { tracked } from '@glimmer/tracking';
import markdownNoTrim from 'remark-parse-no-trim';

import EuiContainerQuery from '#src/components/eui-container-query.gts';
import EuiI18n from '#src/components/eui-i18n.gts';
import EuiMarkdownEditor from '#src/components/eui-markdown-editor.gts';
import EuiMarkdownFormat from '#src/components/eui-markdown-format.gts';
import EuiPrettyDuration from '#src/components/eui-pretty-duration.gts';
import containerQuery from '#src/modifiers/container-query.ts';
import { prettyDuration } from '#src/utils/pretty-duration.ts';
import { getDefaultEuiMarkdownPlugins } from '#src/utils/markdown/plugins/markdown-default-plugins/index.ts';
import { euiXScroll, euiXScrollWithShadows } from '#src/theming.ts';

const noop = () => {};
const upper = (text: string) => text.toUpperCase();

module('Integration | Last utils', function (hooks) {
  setupRenderingTest(hooks);

  module('EuiI18n mappingFunc', function () {
    test('maps the default and the mapped text, including string values', async function (assert) {
      const i18n = { mapping: { mapped: 'Mapped {who}' }, mappingFunc: upper };

      await render(
        <template>
          <EuiI18n @token="plain" @default="Plain text" @i18n={{i18n}} as |Text|><p id="a"><Text /></p></EuiI18n>
          <EuiI18n @token="mapped" @default="x {who}" @values={{hash who="bob"}} @i18n={{i18n}} as |Text|><p id="b"><Text /></p></EuiI18n>
        </template>
      );

      assert.dom('#a').hasText('PLAIN TEXT');
      assert.dom('#b').hasText('MAPPED BOB', 'the text and the value are both mapped');
    });

    test('without mappingFunc the text is untouched, and a formatting function is mapped as a whole', async function (assert) {
      const i18n = { mapping: { fn: ({ n }: { n: number }) => `${n} things` }, mappingFunc: upper };

      await render(
        <template>
          <EuiI18n @token="none" @default="Keep case" as |Text|><p id="a"><Text /></p></EuiI18n>
          <EuiI18n @token="fn" @default="x" @values={{hash n=2}} @i18n={{i18n}} as |Text|><p id="b"><Text /></p></EuiI18n>
        </template>
      );

      assert.dom('#a').hasText('Keep case');
      assert.dom('#b').hasText('2 THINGS');
    });

    test('@tokens are mapped too', async function (assert) {
      const i18n = { mapping: {}, mappingFunc: upper };

      await render(
        <template>
          {{! @glint-expect-error }}
          <EuiI18n @tokens={{(array "a" "b")}} @defaults={{(array "one" "two")}} @i18n={{i18n}} as |texts|><p id="a">{{texts}}</p></EuiI18n>
        </template>
      );

      assert.dom('#a').hasText('ONE,TWO');
    });
  });

  module('Markdown', function () {
    test('linkProps customizes every link', async function (assert) {
      const plugins = getDefaultEuiMarkdownPlugins({
        processingConfig: { linkProps: { target: '_blank', color: 'danger' } }
      });
      const value = '[one](https://elastic.co) and [two](https://example.com)';

      await render(
        <template>
          <EuiMarkdownFormat
            @value={{value}}
            @parsingPluginList={{plugins.parsingPlugins}}
            @processingPluginList={{plugins.processingPlugins}}
          />
        </template>
      );

      assert.dom('a.euiLink').exists({ count: 2 });
      assert.dom('a.euiLink').hasAttribute('target', '_blank');
      assert.dom('a.euiLink').hasAttribute('rel', 'noopener noreferrer');
      assert.dom('a.euiLink .euiLink__externalIcon').exists({ count: 2 }, '_blank adds the external icon');
    });

    test('linkProps onClick runs and overrides do not leak without them', async function (assert) {
      const clicks: string[] = [];
      const plugins = getDefaultEuiMarkdownPlugins({
        processingConfig: { linkProps: { onClick: (event: MouseEvent) => { event.preventDefault(); clicks.push('x'); } } }
      });
      const value = '[one](https://elastic.co)';
      const defaults = getDefaultEuiMarkdownPlugins();

      await render(
        <template>
          <EuiMarkdownFormat id="with" @value={{value}} @parsingPluginList={{plugins.parsingPlugins}} @processingPluginList={{plugins.processingPlugins}} />
          <EuiMarkdownFormat id="without" @value={{value}} @parsingPluginList={{defaults.parsingPlugins}} @processingPluginList={{defaults.processingPlugins}} />
        </template>
      );

      await click('#with a');
      assert.deepEqual(clicks, ['x']);
      assert.dom('#without a').doesNotHaveAttribute('target');
    });

    test('the editor takes markdownFormatProps for its preview', async function (assert) {
      const props = { textSize: 's' as const, rootClasses: ['my-preview'] };

      await render(
        <template>
          <EuiMarkdownEditor
            @value="hello"
            @onChange={{noop}}
            @initialViewMode="viewing"
            @markdownFormatProps={{props}}
          />
        </template>
      );

      assert.dom('.euiMarkdownEditorPreview .euiMarkdownFormat').hasClass('my-preview');
    });

    test('the parser is remark-parse-no-trim and intraword underscores stay text', async function (assert) {
      const { parsingPlugins } = getDefaultEuiMarkdownPlugins();

      assert.strictEqual((parsingPlugins[0] as unknown[])[0], markdownNoTrim);

      const value = 'ABCD__PineappleCherry__e and __bold__ and _em_ and foo_bar_baz';

      await render(<template><EuiMarkdownFormat @value={{value}} /></template>);

      assert.dom('.euiMarkdownFormat').includesText('ABCD__PineappleCherry__e');
      assert.dom('.euiMarkdownFormat').includesText('foo_bar_baz');
      assert.dom('.euiMarkdownFormat strong').hasText('bold');
      assert.dom('.euiMarkdownFormat em').hasText('em');
    });
  });

  module('container queries', function () {
    class State {
      @tracked wide: boolean | undefined;
      set = (value: boolean) => (this.wide = value);
    }

    test('the component yields whether the container matches and follows resizes', async function (assert) {
      const state = new State();

      await render(
        <template>
          <div id="host" style="width: 500px">
            <EuiContainerQuery @condition="(width > 400px)" @onChange={{state.set}} as |matches|>
              <p id="out">{{if matches "wide" "narrow"}}</p>
            </EuiContainerQuery>
          </div>
        </template>
      );

      assert.dom('#out').hasText('wide');
      assert.true(state.wide);

      (document.querySelector('#host') as HTMLElement).style.width = '300px';
      await new Promise((resolve) => setTimeout(resolve, 100));
      await settled();

      assert.dom('#out').hasText('narrow');
      assert.false(state.wide);
    });

    test('the modifier reports to onChange and cleans up its marker', async function (assert) {
      const state = new State();

      await render(
        <template>
          <div style="container-type: inline-size; width: 500px">
            <div id="probe" {{containerQuery "(width > 400px)" onChange=state.set}}></div>
          </div>
        </template>
      );

      assert.true(state.wide);
      assert.true(
        Array.from((document.querySelector('#probe') as HTMLElement).attributes).some((a) =>
          a.name.startsWith('data-container-query-observer')
        )
      );
    });
  });

  module('scroll helpers', function () {
    const context = { euiTheme: { colors: { darkShade: '#69707d' }, size: { base: '16px', s: '8px', xs: '4px' } } } as never;

    test('euiXScroll scrolls horizontally with the minimal scroll bar', function (assert) {
      assert.ok(/overflow-inline: auto|overflow-x: auto/.test(euiXScroll(context)));
      assert.ok(euiXScroll(context).includes('scrollbar-width'));
      assert.ok(euiXScrollWithShadows(context).includes('mask-image'));
    });
  });

  module('PrettyDuration', function () {
    test('the component renders the text of the range', async function (assert) {
      await render(
        <template>
          <p id="a"><EuiPrettyDuration @timeFrom="now-15m" @timeTo="now" /></p>
          <p id="b"><EuiPrettyDuration @timeFrom="now" @timeTo="now+2d/d" /></p>
          <p id="c"><EuiPrettyDuration @timeFrom="now/d" @timeTo="now/d" /></p>
          <p id="d"><EuiPrettyDuration @timeFrom="2018-01-17T18:57:57.149Z" @timeTo="2018-01-18T18:57:57.149Z" @dateFormat="YYYY-MM-DD" /></p>
        </template>
      );

      assert.dom('#a').hasText('Last 15 minutes');
      assert.dom('#b').hasText('Next 2 days rounded to the day');
      assert.dom('#c').hasText('Today');
      assert.dom('#d').hasText('2018-01-17 to 2018-01-18');
    });

    test('prettyDuration is exported as a function', function (assert) {
      assert.strictEqual(typeof prettyDuration, 'function');
    });
  });
});
