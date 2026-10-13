import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { blur, click, fillIn, focus, render, waitUntil } from '@ember/test-helpers';
import { array, get, hash } from '@ember/helper';
import { tracked } from '@glimmer/tracking';

import EuiButton from '#src/components/eui-button.gts';
import EuiColorPalettePicker from '#src/components/eui-color-palette-picker.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiFormPrepend from '#src/components/eui-form-prepend.gts';
import EuiI18n from '#src/components/eui-i18n.gts';
import EuiMarkdownEditor from '#src/components/eui-markdown-editor.gts';
import EuiMarkdownFormat from '#src/components/eui-markdown-format.gts';
import EuiSearchBar from '#src/components/eui-search-bar.gts';
import {
  euiMarkdownLinkValidator,
  isDocumentRelativeUrl,
  mutateLinkToText,
  validateUrl
} from '#src/utils/markdown/plugins/markdown-link-validator.ts';
import {
  getDefaultEuiMarkdownPlugins,
  getDefaultEuiMarkdownUiPlugins
} from '#src/utils/markdown/plugins/markdown-default-plugins/index.ts';

import type { TOC } from '@ember/component/template-only';

const noop = () => {};
const isString = (value: unknown) => typeof value === 'string';
const palettes = [{ value: 'a', title: 'A', type: 'fixed' as const, palette: ['#111111', '#222222'] }];

module('Integration | Text gaps', function (hooks) {
  setupRenderingTest(hooks);

  module('EuiColorPalettePicker prepend / append', function () {
    test('the blocks render around the control and are absent otherwise', async function (assert) {
      await render(
        <template>
          <EuiColorPalettePicker @palettes={{palettes}} @valueOfSelected="a" @onChange={{noop}}>
            <:prepend as |className|><span class="my-prepend {{className}}">Before</span></:prepend>
            <:append as |className|><span class="my-append {{className}}">After</span></:append>
          </EuiColorPalettePicker>
        </template>
      );

      assert.dom('.euiFormControlLayout__prepend .my-prepend').hasText('Before');
      assert.dom('.euiFormControlLayout__append .my-append').hasText('After');
      assert.dom('.euiFormControlLayout--group').exists();

      await render(
        <template><EuiColorPalettePicker @palettes={{palettes}} @valueOfSelected="a" @onChange={{noop}} /></template>
      );
      assert.dom('.euiFormControlLayout__prepend').doesNotExist();
      assert.dom('.euiFormControlLayout__append').doesNotExist();
    });
  });

  module('EuiI18n', function () {
    test('@tokens + @defaults yield an array of the texts', async function (assert) {
      const i18n = { mapping: { 'multi.two': 'Dos' } };
      await render(
        <template>
          <EuiI18n @tokens={{array "multi.one" "multi.two"}} @defaults={{array "One" "Two"}} @i18n={{i18n}} as |texts|>
            <span class="first">{{get texts 0}}</span>
            <span class="second">{{get texts 1}}</span>
            <span class="count">{{texts.length}}</span>
          </EuiI18n>
        </template>
      );

      assert.dom('.first').hasText('One', 'default when there is no translation');
      assert.dom('.second').hasText('Dos', 'mapping wins');
      assert.dom('.count').hasText('2', 'yielded once');
    });

    test('component values render in place of their placeholder', async function (assert) {
      const Name: TOC<{ Args: {} }> = <template><strong class="name">Ada</strong></template>;
      const values = { name: Name };

      await render(
        <template>
          <p class="plain">
            <EuiI18n @token="greet" @default="Hello {name}, welcome" @values={{values}} as |Text|><Text /></EuiI18n>
          </p>
          <p class="custom">
            <EuiI18n @token="greet" @default="Hello {name}, welcome" @values={{values}} as |Text|>
              <Text as |part|><em>{{if (isString part) part "[c]"}}</em></Text>
            </EuiI18n>
          </p>
        </template>
      );

      assert.dom('.plain').hasText('Hello Ada, welcome');
      assert.dom('.plain strong.name').exists({ count: 1 });
      assert.dom('.custom em').exists({ count: 3 }, 'text, component and text parts');
    });

    test('a string token renders without a block on the yielded component', async function (assert) {
      await render(
        <template>
          <EuiI18n @token="x" @default="Hi {who}" @values={{hash who="there"}} as |Text|><b class="out"><Text /></b></EuiI18n>
        </template>
      );
      assert.dom('.out').hasText('Hi there');
    });
  });

  module('EuiSearchBar box and filter view', function () {
    test('box.prepend / append (text and component) and click / focus / blur callbacks', async function (assert) {
      const calls: string[] = [];
      const Tools: TOC<{ Args: {} }> = <template><EuiFormPrepend @label="Scope" /></template>;
      const box = {
        prepend: 'Find',
        append: Tools,
        onClick: () => calls.push('click'),
        onFocus: () => calls.push('focus'),
        onBlur: () => calls.push('blur'),
        'data-test-subj': 'bar'
      };

      await render(<template><EuiEmotionProvider><EuiSearchBar @box={{box}} /></EuiEmotionProvider></template>);

      assert.dom('.euiFormControlLayout__prepend').containsText('Find');
      assert.dom('.euiFormControlLayout__append').containsText('Scope');

      await focus('[data-test-subj="bar"]');
      await click('[data-test-subj="bar"]');
      await blur('[data-test-subj="bar"]');
      assert.true(calls.includes('focus'));
      assert.true(calls.includes('click'));
      assert.true(calls.includes('blur'));
    });

    test('box.onFocus still opens the hint', async function (assert) {
      const box = { onFocus: noop, 'data-test-subj': 'bar' };
      const hint = {};

      await render(
        <template>
          <EuiEmotionProvider>
            <EuiSearchBar @box={{box}} @hint={{hint}}><:hint><span data-hint>A hint</span></:hint></EuiSearchBar>
          </EuiEmotionProvider>
        </template>
      );
      assert.dom('[data-hint]', document.body).doesNotExist();
      await focus('[data-test-subj="bar"]');
      await waitUntil(() => document.querySelector('[data-hint]'));
      assert.dom('[data-hint]', document.body).hasText('A hint');
    });

    test('a filter option view can be a component', async function (assert) {
      const Badge: TOC<{ Args: {} }> = <template><span class="opt-view">Fancy <b>Gamma</b></span></template>;
      const filters = [
        {
          type: 'field_value_selection' as const,
          field: 'tag',
          name: 'Tags',
          options: [
            { value: 'a', name: 'Alpha' },
            { value: 'c', name: 'Gamma', view: Badge }
          ]
        }
      ];

      await render(<template><EuiEmotionProvider><EuiSearchBar @filters={{filters}} /></EuiEmotionProvider></template>);
      await click('.euiFilterButton[aria-label="Tags Selection"]');
      await waitUntil(() => document.querySelector('.opt-view'));

      assert.dom('.euiSelectableListItem .opt-view b', document.body).hasText('Gamma');
      assert.dom(document.querySelectorAll('.euiSelectableListItem')[0]!).hasText('Alpha');
    });
  });

  module('EuiMarkdownEditor', function () {
    class State {
      @tracked value = 'x';
    }

    test('toolbarProps.right replaces the preview switch; className is added', async function (assert) {
      const state = new State();
      const Right: TOC<{ Args: {} }> = <template><EuiButton class="my-right" @size="s">Validate</EuiButton></template>;
      const toolbarProps = { right: Right, className: 'customToolbar' };

      await render(
        <template><EuiMarkdownEditor @value={{state.value}} @onChange={{noop}} @toolbarProps={{toolbarProps}} /></template>
      );

      assert.dom('.euiMarkdownEditorToolbar').hasClass('customToolbar');
      assert.dom('.euiMarkdownEditorToolbar .my-right').hasText('Validate');
      assert.dom('[data-test-subj="markdown_editor_edit_button"]').doesNotExist();

      await render(<template><EuiMarkdownEditor @value={{state.value}} @onChange={{noop}} /></template>);
      assert.dom('[data-test-subj="markdown_editor_edit_button"]').exists('default switch without toolbarProps');
      assert.dom('.euiMarkdownEditorToolbar .customToolbar').doesNotExist();
    });

    test('the tooltip toolbar button is there by default and gone when excluded', async function (assert) {
      const state = new State();
      const withTooltip = getDefaultEuiMarkdownPlugins();
      const withoutTooltip = getDefaultEuiMarkdownPlugins({ exclude: ['tooltip'] });

      await render(<template><EuiMarkdownEditor @value={{state.value}} @onChange={{noop}} /></template>);
      assert.dom('button[aria-label="Tooltip"]').exists('default uiPlugins');

      await render(
        <template>
          <EuiMarkdownEditor @value={{state.value}} @onChange={{noop}} @uiPlugins={{withTooltip.uiPlugins}} />
        </template>
      );
      assert.dom('button[aria-label="Tooltip"]').exists();

      await render(
        <template>
          <EuiMarkdownEditor
            @value={{state.value}}
            @onChange={{noop}}
            @uiPlugins={{withoutTooltip.uiPlugins}}
            @parsingPluginList={{withoutTooltip.parsingPlugins}}
            @processingPluginList={{withoutTooltip.processingPlugins}}
          />
        </template>
      );
      assert.dom('button[aria-label="Tooltip"]').doesNotExist();
      assert.dom('.euiMarkdownEditorToolbar__buttons .euiMarkdownEditorToolbar__divider').exists({ count: 2 }, 'no plugin divider');
    });

    test('the editor reacts to a changed uiPlugins list', async function (assert) {
      class Plugins {
        @tracked list = getDefaultEuiMarkdownUiPlugins({ exclude: ['tooltip'] });
      }
      const plugins = new Plugins();
      const state = new State();

      await render(<template><EuiMarkdownEditor @value={{state.value}} @onChange={{noop}} @uiPlugins={{plugins.list}} /></template>);
      assert.dom('button[aria-label="Tooltip"]').doesNotExist();

      plugins.list = getDefaultEuiMarkdownUiPlugins();
      await waitUntil(() => document.querySelector('button[aria-label="Tooltip"]'));
      await fillIn('textarea', 'abc');
      await click('button[aria-label="Tooltip"]');
      assert.true((document.querySelector('textarea') as HTMLTextAreaElement).value.includes('!{tooltip['), 'the new plugin list drives the toolbar actions');
    });

    test('exclude drops the matching parsing plugins', function (assert) {
      const all = getDefaultEuiMarkdownPlugins().parsingPlugins.length;

      for (const name of ['emoji', 'lineBreaks', 'linkValidator', 'checkbox', 'tooltip'] as const) {
        assert.strictEqual(getDefaultEuiMarkdownPlugins({ exclude: [name] }).parsingPlugins.length, all - 1, name);
      }

      assert.strictEqual(
        getDefaultEuiMarkdownPlugins({ exclude: ['emoji', 'checkbox', 'linkValidator', 'lineBreaks', 'tooltip'] }).parsingPlugins.length,
        all - 5
      );
      assert.strictEqual(getDefaultEuiMarkdownUiPlugins({ exclude: ['emoji'] }).length, 1, 'tooltip stays');
      assert.strictEqual(getDefaultEuiMarkdownUiPlugins({ exclude: ['tooltip'] }).length, 0);
    });
  });

  module('EuiMarkdownFormat default plugins', function () {
    async function renderFormat(value: string, config?: Parameters<typeof getDefaultEuiMarkdownPlugins>[0]) {
      const plugins = getDefaultEuiMarkdownPlugins(config);

      await render(
        <template>
          <EuiMarkdownFormat
            @value={{value}}
            @parsingPluginList={{plugins.parsingPlugins}}
            @processingPluginList={{plugins.processingPlugins}}
          />
        </template>
      );
    }

    test('excluded syntax stays plain text', async function (assert) {
      const value = ':smile:\n\nline one\nline two\n\n- [ ] todo\n\n!{tooltip[anchor](tip)}';

      await renderFormat(value);
      assert.dom('input[type="checkbox"]').exists();
      assert.dom('.euiMarkdownFormat').doesNotIncludeText(':smile:');
      assert.dom('.euiMarkdownFormat br').exists('lineBreaks');
      assert.dom('.euiMarkdownFormat').doesNotIncludeText('!{tooltip');

      await renderFormat(value, { exclude: ['emoji', 'lineBreaks', 'checkbox', 'tooltip'] });
      assert.dom('.euiMarkdownFormat').includesText(':smile:', 'emoji excluded');
      assert.dom('.euiMarkdownFormat br').doesNotExist('lineBreaks excluded');
      assert.dom('.euiMarkdownFormat').includesText('!{tooltip[anchor](tip)}', 'tooltip excluded');
      assert.dom('.euiMarkdownFormat__checkbox').doesNotExist('checkbox renderer excluded');
    });

    test('the link validator turns unsupported links into text', async function (assert) {
      const value = [
        '[ok](https://elastic.co)',
        '[mail](mailto:a@b.co)',
        '[abs](/app/discover)',
        '[js](javascript:alert(1))',
        '[ftp](ftp://host/file)',
        '[doc](discover)',
        '[bare](https://elastic.co)'
      ].join('\n\n');

      await renderFormat(value);
      const hrefs = [...document.querySelectorAll('.euiMarkdownFormat a')].map((a) => a.getAttribute('href'));
      assert.deepEqual(hrefs, ['https://elastic.co', 'mailto:a@b.co', '/app/discover', 'https://elastic.co']);
      assert.dom('.euiMarkdownFormat').includesText('[js](javascript:alert(1))', 'markdown kept as text');
      assert.dom('.euiMarkdownFormat').includesText('[doc](discover)');

      await renderFormat(value, { exclude: ['linkValidator'] });
      assert.dom('.euiMarkdownFormat a').exists({ count: 7 - 1 }, 'all links render (javascript: renders as a disabled button)');
    });

    test('parsingConfig.linkValidator: protocols and document relative links', async function (assert) {
      await renderFormat('[a](https://a.co)\n\n[m](mailto:x@y.co)\n\n[doc](discover)', {
        parsingConfig: {
          linkValidator: { allowProtocols: ['https:'], allowDocumentRelative: true, baseUrl: 'https://host.test/app/home/' }
        }
      });

      const hrefs = [...document.querySelectorAll('.euiMarkdownFormat a')].map((a) => a.getAttribute('href'));
      assert.deepEqual(hrefs, ['https://a.co', '/app/discover']);
      assert.dom('.euiMarkdownFormat').includesText('[m](mailto:x@y.co)');

      await renderFormat('[abs](/x)', { parsingConfig: { linkValidator: { allowRelative: false } } });
      assert.dom('.euiMarkdownFormat a').doesNotExist();
      assert.dom('.euiMarkdownFormat').includesText('[abs](/x)');
    });
  });

  module('link validator utils', function () {
    const options = { allowRelative: true, allowProtocols: ['http:', 'https:', 'mailto:'] };

    test('validateUrl', function (assert) {
      for (const ok of ['https://domain', 'http://domain', 'mailto:someone@elastic.co', '/', '//']) {
        assert.true(validateUrl(ok, options), ok);
      }
      for (const bad of ['httpm:', './', '../', 'word', 'gopher://domain', 'javascript:']) {
        assert.false(validateUrl(bad, options), bad);
      }
      assert.false(validateUrl('/x', { ...options, allowRelative: false }));
      assert.false(validateUrl('http://x', { allowProtocols: ['https:'] }));
    });

    test('isDocumentRelativeUrl and mutateLinkToText', function (assert) {
      for (const yes of ['app', 'page#/view/1', '../x', './app']) assert.true(isDocumentRelativeUrl(yes), yes);
      for (const no of ['/app', '//host', '#a', '?q', 'https://x', 'mailto:a@b.co']) assert.false(isDocumentRelativeUrl(no), no);

      assert.deepEqual(
        mutateLinkToText({ type: 'link', url: 'word', title: 't', children: [{ value: 'text' }] }),
        { type: 'text', value: '[text](word)' }
      );
      assert.deepEqual(mutateLinkToText({ type: 'link', url: 'word', children: [{ value: 'word' }] }), {
        type: 'text',
        value: 'word'
      });
    });

    test('euiMarkdownLinkValidator resolves document relative links against the base url without trailing slash', function (assert) {
      const link = (url: string) => ({ type: 'root', children: [{ type: 'link', url, children: [{ type: 'text', value: 'l' }] }] });
      const run = (url: string, baseUrl: string) => {
        const tree = link(url);
        euiMarkdownLinkValidator({ allowDocumentRelative: true, baseUrl })(tree);
        return tree.children[0] as { url?: string; type: string };
      };

      assert.strictEqual(run('baz', 'https://h.test/foo/bar/').url, '/foo/baz');
      assert.strictEqual(run('../baz?x=1#h', 'https://h.test/foo/bar').url, '/baz?x=1#h');
    });
  });
});
