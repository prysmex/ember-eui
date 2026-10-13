import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, fillIn, focus, render, rerender, triggerKeyEvent, waitUntil } from '@ember/test-helpers';
import { on } from '@ember/modifier';
import { tracked } from '@glimmer/tracking';

import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiSelectableTemplateSitewide from '#src/components/eui-selectable-template-sitewide.gts';
import { BREAKPOINTS } from '#src/utils/breakpoint.ts';
import { currentBreakpoint } from '#src/components/eui-show-for.gts';

import type { EuiSelectableTemplateSitewideOption } from '#src/components/eui-selectable-template-sitewide.gts';

class State {
  @tracked options: EuiSelectableTemplateSitewideOption[] = [
    {
      label: 'Dashboards',
      icon: { type: 'dashboardApp' },
      meta: [{ text: 'Analytics', type: 'application' }],
    },
    {
      label: 'Revenue by region',
      icon: { type: 'visBarVertical' },
      avatar: { name: 'Sales' },
      meta: [{ text: 'Visualization' }, { text: 'Revenue', highlightSearchString: true }],
    },
  ];

  chosen?: string;
  searched?: string;

  onSearch = (value: string) => {
    this.searched = value;
  };

  onChange = (options: EuiSelectableTemplateSitewideOption[]) => {
    this.chosen = options.find((option) => option.checked === 'on')?.label;
  };
}

module('Integration | Component | eui-selectable-template-sitewide', function (hooks) {
  setupRenderingTest(hooks);

  test('focusing the search opens the results', async function (assert) {
    const state = new State();

    await render(<template><EuiSelectableTemplateSitewide @options={{state.options}} @onChange={{state.onChange}} /></template>);

    assert.dom('input.euiSelectableTemplateSitewide__search').hasAttribute('placeholder', 'Search for anything...');

    await focus('input.euiSelectableTemplateSitewide__search');
    await waitUntil(() => document.querySelector('.euiSelectableTemplateSitewide__listItem'));

    assert.dom('.euiSelectableTemplateSitewide__listItem', document.body).exists({ count: 2 });
    assert.dom('.euiSelectableTemplateSitewide__listItemTitle', document.body).exists({ count: 2 });
    assert.dom('.euiSelectableTemplateSitewide__optionMeta--application', document.body).hasText('Analytics');
    assert.dom('.euiSelectableListItem__prepend .euiIcon', document.body).exists({ count: 2 });
    assert.dom('.euiSelectableListItem__append .euiAvatar', document.body).exists({ count: 1 });

    await fillIn('input.euiSelectableTemplateSitewide__search', 'rev');
    assert.dom('.euiSelectableTemplateSitewide__listItem', document.body).exists({ count: 1 });
    assert.dom('.euiSelectableTemplateSitewide__optionMeta mark', document.body).hasText('Rev', 'meta with highlightSearchString is highlighted');

    await click(document.querySelector('.euiSelectableTemplateSitewide__listItem') as Element);
    await rerender();
    assert.strictEqual(state.chosen, 'Revenue by region');
  });

  test('a popover button, title, footer and loading', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiSelectableTemplateSitewide @options={{state.options}} @isLoading={{true}}>
          <:popoverButton as |toggle|><button type="button" class="open" {{on "click" toggle}}>Search</button></:popoverButton>
          <:popoverTitle><span class="title">Find</span></:popoverTitle>
          <:popoverFooter><span class="footer">Tip</span></:popoverFooter>
        </EuiSelectableTemplateSitewide>
      </template>
    );

    assert.dom('input.euiSelectableTemplateSitewide__search').doesNotExist('the search moves into the popover');
    await click('.open');
    await waitUntil(() => document.querySelector('.euiSelectableTemplateSitewide__popover'));

    assert.dom('.euiPopoverTitle .title', document.body).exists();
    assert.dom('.euiPopoverTitle input.euiSelectableTemplateSitewide__search', document.body).exists();
    assert.dom('.euiPopoverFooter .footer', document.body).exists();
    assert.dom('.euiSelectableTemplateSitewide__popover', document.body).includesText('Loading results');
  });

  const openSearch = async () => {
    await focus('input.euiSelectableTemplateSitewide__search');
    await waitUntil(() => document.querySelector('.euiSelectableTemplateSitewide__popover'));
  };

  test('searchProps: className, append, onKeyUpCapture, inputRef, handlers, placeholder', async function (assert) {
    const state = new State();
    const calls: string[] = [];
    let input: HTMLInputElement | undefined;
    const searchProps = {
      className: 'customSearchClass',
      append: '⌘K',
      placeholder: 'Find it',
      inputRef: (element: HTMLInputElement) => (input = element),
      onKeyUpCapture: (event: KeyboardEvent) =>
        calls.push(`keyup:${(event.currentTarget as HTMLInputElement).value}`),
      onFocus: () => calls.push('focus'),
      onKeyDown: () => calls.push('keydown'),
      onSearch: (value: string) => calls.push(`search:${value}`),
    };

    await render(
      <template>
        <EuiSelectableTemplateSitewide
          @options={{state.options}}
          @searchProps={{searchProps}}
          @onSearch={{state.onSearch}}
        />
      </template>
    );

    const field = 'input.euiSelectableTemplateSitewide__search';

    assert.dom(field).hasClass('customSearchClass');
    assert.dom(field).hasClass('euiSelectableSearch');
    assert.dom(field).hasAttribute('placeholder', 'Find it');
    assert.dom('.euiFormControlLayout .euiFormAppend').hasText('⌘K');
    assert.strictEqual(input, document.querySelector(field), 'inputRef gets the input');

    await focus(field);
    assert.true(calls.includes('focus'), 'onFocus runs besides opening the popover');
    await waitUntil(() => document.querySelector('.euiSelectableTemplateSitewide__popover'));

    await fillIn(field, 'rev');
    await triggerKeyEvent(field, 'keyup', 'ArrowRight');
    assert.true(calls.includes('keyup:rev'), 'onKeyUpCapture sees the typed text');
    assert.true(calls.includes('search:rev'), 'searchProps.onSearch runs');
    assert.strictEqual(state.searched, 'rev', '@onSearch runs too');
    await triggerKeyEvent(field, 'keydown', 'ArrowLeft');
    assert.true(calls.includes('keydown'));
  });

  test('Enter in the search opens the closed popover', async function (assert) {
    const state = new State();

    await render(<template><EuiSelectableTemplateSitewide @options={{state.options}} /></template>);

    const field = 'input.euiSelectableTemplateSitewide__search';

    await openSearch();
    await triggerKeyEvent(field, 'keydown', 'Escape');
    await waitUntil(() => !document.querySelector('.euiSelectableTemplateSitewide__popover'));

    await triggerKeyEvent(field, 'keydown', 'Enter');
    await waitUntil(() => document.querySelector('.euiSelectableTemplateSitewide__popover'));
    assert.dom('.euiSelectableTemplateSitewide__popover', document.body).exists();
  });

  test('listProps: className, rowHeight, css and the defaults', async function (assert) {
    const state = new State();
    const listProps = {
      className: 'customListClass',
      rowHeight: 80,
      css: {
        '.euiSelectableTemplateSitewide__optionMeta--PINK': { fontStyle: 'italic' },
      },
    };

    await render(
      <template><EuiSelectableTemplateSitewide @options={{state.options}} @listProps={{listProps}} /></template>
    );
    await openSearch();

    const list = document.querySelector('.euiSelectableTemplateSitewide__list') as HTMLElement;

    assert.dom(list).hasClass('customListClass');
    assert.dom('.euiSelectableTemplateSitewide__list', document.body).hasClass('euiSelectableList');
    assert.dom('.euiSelectableListItem__prepend .euiIcon', document.body).exists('showIcons default keeps the icon slot');
    assert.dom('.euiSelectableListItem__icon', document.body).doesNotExist('showIcons: false by default');
    assert.dom('.euiSelectableTemplateSitewide__listItem', document.body).hasStyle({ height: '80px' });
  });

  test('listProps: onFocusBadge default is "Go to" on the right and can be turned off', async function (assert) {
    const state = new State();
    const off = { onFocusBadge: false };

    await render(
      <template>
        <EuiSelectableTemplateSitewide @options={{state.options}} @listProps={{off}} />
      </template>
    );
    await openSearch();
    await triggerKeyEvent('input.euiSelectableTemplateSitewide__search', 'keydown', 'ArrowDown');
    assert.dom('.euiSelectableListItem__onFocusBadge', document.body).doesNotExist();

    await render(
      <template><EuiSelectableTemplateSitewide @options={{state.options}} /></template>
    );
    await openSearch();
    await triggerKeyEvent('input.euiSelectableTemplateSitewide__search', 'keydown', 'ArrowDown');
    assert.dom('.euiSelectableListItem__onFocusBadge', document.body).hasText('Go to');
  });

  test('popoverProps: width, className, panelClassName, anchorPosition, closePopover and panelRef', async function (assert) {
    const state = new State();
    let panel: HTMLElement | null = null;
    let closed = 0;
    const popoverProps = {
      width: 420,
      className: 'customPopoverClass',
      panelClassName: 'customPanelClass',
      closePopover: () => closed++,
      panelRef: (element: HTMLElement | null) => (panel = element),
    };

    await render(
      <template>
        <EuiSelectableTemplateSitewide @options={{state.options}} @popoverProps={{popoverProps}} />
      </template>
    );

    assert.dom('.euiPopover.customPopoverClass').exists();
    await openSearch();
    assert.dom('.euiSelectableTemplateSitewide__popover', document.body).hasStyle({ width: '420px' });
    assert.dom('.euiPopover__panel.customPanelClass', document.body).exists();
    assert.strictEqual(panel, document.querySelector('.customPanelClass'), 'panelRef gets the panel');

    await triggerKeyEvent('input.euiSelectableTemplateSitewide__search', 'keydown', 'Escape');
    await waitUntil(() => !document.querySelector('.euiSelectableTemplateSitewide__popover'));
    assert.strictEqual(closed, 1, 'closePopover runs after the template closes it');
  });

  test('@popoverWidth still works and popoverProps.width wins', async function (assert) {
    const state = new State();
    const popoverProps = { width: '50vw' };

    await render(
      <template>
        <EuiSelectableTemplateSitewide @options={{state.options}} @popoverWidth={{300}} />
      </template>
    );
    await openSearch();
    assert.dom('.euiSelectableTemplateSitewide__popover', document.body).hasStyle({ width: '300px' });

    await render(
      <template>
        <EuiSelectableTemplateSitewide @options={{state.options}} @popoverWidth={{300}} @popoverProps={{popoverProps}} />
      </template>
    );
    await openSearch();
    assert.dom('.euiSelectableTemplateSitewide__popover', document.body).hasStyle({ width: `${window.innerWidth / 2}px` });
  });

  test('popoverButtonBreakpoints: the button replaces the search only at those breakpoints', async function (assert) {
    const state = new State();
    const current = currentBreakpoint(window.innerWidth, BREAKPOINTS)!;
    const other = (['xs', 's', 'm', 'l', 'xl'] as const).filter((size) => size !== current);
    const here = [current];

    await render(
      <template>
        <EuiSelectableTemplateSitewide @options={{state.options}} @popoverButtonBreakpoints={{here}}>
          <:popoverButton as |toggle|><button type="button" class="open" {{on "click" toggle}}>Search</button></:popoverButton>
        </EuiSelectableTemplateSitewide>
      </template>
    );
    assert.dom('.open').exists('shown at the current breakpoint');
    assert.dom('input.euiSelectableTemplateSitewide__search').doesNotExist();

    await render(
      <template>
        <EuiSelectableTemplateSitewide @options={{state.options}} @popoverButtonBreakpoints={{other}}>
          <:popoverButton as |toggle|><button type="button" class="open" {{on "click" toggle}}>Search</button></:popoverButton>
        </EuiSelectableTemplateSitewide>
      </template>
    );
    assert.dom('.open').doesNotExist('not shown at other breakpoints');
    assert.dom('input.euiSelectableTemplateSitewide__search').exists('the search stays inline');

    await openSearch();
    assert.dom('.euiPopoverTitle', document.body).doesNotExist('no title wrapper without the button');
    assert.dom('.euiSelectableTemplateSitewide__popover', document.body).exists();
  });

  const background = (selector: string) =>
    getComputedStyle(document.querySelector(selector) as Element).backgroundColor;

  test('colorModes: popover and search take their own mode', async function (assert) {
    const state = new State();
    const light = { popover: 'light', search: 'light' } as const;
    const dark = { popover: 'dark', search: 'dark' } as const;
    const inverse = { popover: 'inverse', search: 'default' } as const;

    await render(
      <template>
        <EuiEmotionProvider @colorMode="light" @globalStyles={{false}}>
          <EuiSelectableTemplateSitewide @options={{state.options}} @colorModes={{light}} />
        </EuiEmotionProvider>
      </template>
    );
    await openSearch();
    const lightPanel = background('.euiPopover__panel');
    const lightSearch = background('input.euiSelectableTemplateSitewide__search');

    await render(
      <template>
        <EuiEmotionProvider @colorMode="light" @globalStyles={{false}}>
          <EuiSelectableTemplateSitewide @options={{state.options}} @colorModes={{dark}} />
        </EuiEmotionProvider>
      </template>
    );
    await openSearch();
    assert.notStrictEqual(background('.euiPopover__panel'), lightPanel, 'a dark popover');
    assert.notStrictEqual(background('input.euiSelectableTemplateSitewide__search'), lightSearch, 'a dark search');

    await render(
      <template>
        <EuiEmotionProvider @colorMode="light" @globalStyles={{false}}>
          <EuiSelectableTemplateSitewide @options={{state.options}} @colorModes={{inverse}} />
        </EuiEmotionProvider>
      </template>
    );
    await openSearch();
    assert.notStrictEqual(background('.euiPopover__panel'), lightPanel, 'inverse of light is dark');
    assert.strictEqual(
      background('input.euiSelectableTemplateSitewide__search'),
      lightSearch,
      'the search stays in the nearest mode inside an inverse popover'
    );
  });

  test('colorModes: global is the outermost provider, default the nearest', async function (assert) {
    const state = new State();
    const global = { popover: 'global', search: 'default' } as const;
    const nearest = { popover: 'default', search: 'default' } as const;

    await render(
      <template>
        <EuiEmotionProvider @colorMode="light" @globalStyles={{false}}>
          <EuiEmotionProvider @colorMode="dark" @globalStyles={{false}}>
            <EuiSelectableTemplateSitewide @options={{state.options}} @colorModes={{nearest}} />
          </EuiEmotionProvider>
        </EuiEmotionProvider>
      </template>
    );
    await openSearch();
    const darkPanel = background('.euiPopover__panel');

    await render(
      <template>
        <EuiEmotionProvider @colorMode="light" @globalStyles={{false}}>
          <EuiEmotionProvider @colorMode="dark" @globalStyles={{false}}>
            <EuiSelectableTemplateSitewide @options={{state.options}} @colorModes={{global}} />
          </EuiEmotionProvider>
        </EuiEmotionProvider>
      </template>
    );
    await openSearch();
    assert.notStrictEqual(background('.euiPopover__panel'), darkPanel, 'global (light) differs from the nearest (dark)');
  });

  test('meta: className, custom type class hook and data-test-subj', async function (assert) {
    const options: EuiSelectableTemplateSitewideOption[] = [
      {
        label: 'Totally custom',
        icon: { type: 'warning', color: 'accent', size: 'm' },
        avatar: { name: 'Sales', size: 'm', type: 'user' },
        meta: [
          { text: 'I have a custom type', type: 'PINK', className: 'myMeta', 'data-test-subj': 'pinkMeta' },
          { text: 'Plain' },
        ],
      },
    ];
    const listProps = {
      css: { '.euiSelectableTemplateSitewide__optionMeta--PINK': { fontStyle: 'italic' } },
    };

    await render(
      <template><EuiSelectableTemplateSitewide @options={{options}} @listProps={{listProps}} /></template>
    );
    await openSearch();

    const pink = document.querySelector('.euiSelectableTemplateSitewide__optionMeta--PINK') as HTMLElement;

    assert.dom(pink).hasClass('euiSelectableTemplateSitewide__optionMeta');
    assert.dom(pink).hasClass('myMeta');
    assert.dom(pink).hasAttribute('data-test-subj', 'pinkMeta');
    assert.dom(pink).hasStyle({ fontStyle: 'italic' });
    assert.dom('.euiSelectableTemplateSitewide__optionMeta--PINK', document.body).doesNotHaveStyle({ fontWeight: '600' });
    assert.true(
      /-m-/.test(document.querySelector('.euiSelectableListItem__prepend .euiIcon')!.getAttribute('class')!),
      'icon.size is passed (medium)'
    );
    assert.dom('.euiSelectableListItem__append .euiAvatar', document.body).hasAttribute('aria-label', 'Sales');
    assert.true(
      /-m-|-user/.test(document.querySelector('.euiSelectableListItem__append .euiAvatar')!.getAttribute('class')!),
      'avatar.size and type are passed'
    );
  });

  test('options without icon or avatar keep their prepend and append', async function (assert) {
    const options: EuiSelectableTemplateSitewideOption[] = [{ label: 'Plain', prepend: '1.', append: '(x)' }];

    await render(<template><EuiSelectableTemplateSitewide @options={{options}} /></template>);
    await openSearch();
    assert.dom('.euiSelectableListItem__prepend', document.body).includesText('1.');
    assert.dom('.euiSelectableListItem__append', document.body).includesText('(x)');
  });

  test('loading and empty messages can be overridden', async function (assert) {
    const none: EuiSelectableTemplateSitewideOption[] = [];

    await render(
      <template><EuiSelectableTemplateSitewide @options={{none}} @emptyMessage="Nothing here" /></template>
    );
    await openSearch();
    assert.dom('.euiSelectableTemplateSitewide__popover', document.body).includesText('Nothing here');

    await render(
      <template>
        <EuiSelectableTemplateSitewide @options={{none}} @isLoading={{true}} @loadingMessage="Hold on" />
      </template>
    );
    await openSearch();
    assert.dom('.euiSelectableTemplateSitewide__popover', document.body).includesText('Hold on');
  });
});
