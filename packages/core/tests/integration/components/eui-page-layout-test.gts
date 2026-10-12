import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import {
  clearRender,
  render,
  settled,
  waitUntil
} from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import EuiBottomBar from '#src/components/eui-bottom-bar.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiPage from '#src/components/eui-page.gts';
import EuiPageBody from '#src/components/eui-page-body.gts';
import EuiPageContentBody from '#src/components/eui-page-content-body.gts';
import EuiPageContentHeader from '#src/components/eui-page-content-header.gts';
import EuiPageContentHeaderSection from '#src/components/eui-page-content-header-section.gts';
import EuiPageHeader from '#src/components/eui-page-header.gts';
import EuiPageHeaderSection from '#src/components/eui-page-header-section.gts';
import EuiPageSideBar from '#src/components/eui-page-side-bar.gts';
import EuiPageTemplate from '#src/components/eui-page-template.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type {
  EuiPageBreakpoint,
  EuiPagePaddingSize
} from '#src/utils/eui/page-layout.ts';
import type { EuiBorealisOverrides } from '#src/utils/eui/theme.ts';

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;
/** Borealis `m` breakpoint; upstream layouts respond below it. */
const BREAKPOINT = light.breakpoint.m as number;

/** Upstream `euiPaddingSize`: xs, s, base (m), l, xl. */
const PADDING: Record<EuiPagePaddingSize, number> = {
  none: 0,
  xs: parseFloat(light.size.xs),
  s: parseFloat(light.size.s),
  m: parseFloat(light.size.base),
  l: parseFloat(light.size.l),
  xl: parseFloat(light.size.xl)
};
const SIZES = Object.keys(PADDING) as EuiPagePaddingSize[];
const BODY_SIZES = ['none', 's', 'm', 'l'] as const;
const ALL_BREAKPOINTS: EuiPageBreakpoint[] = ['xs', 's', 'm', 'l', 'xl'];

const TABS = [
  { id: 'a', label: 'Tab A', isSelected: true },
  { id: 'b', label: 'Tab B' }
];

function el(root: ParentNode, selector: string): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function style(root: ParentNode, selector: string) {
  return getComputedStyle(el(root, selector));
}

/** ember-qunit may scale #ember-testing; measure in layout pixels. */
function scale(element: Element) {
  const container = element.closest<HTMLElement>('#ember-testing');
  if (!container || !container.offsetWidth) return 1;
  return container.getBoundingClientRect().width / container.offsetWidth;
}

function box(root: ParentNode, selector: string) {
  const element = el(root, selector);
  const rect = element.getBoundingClientRect();
  const factor = scale(element);
  return {
    left: rect.left / factor,
    right: rect.right / factor,
    top: rect.top / factor,
    bottom: rect.bottom / factor,
    width: rect.width / factor,
    height: rect.height / factor
  };
}

function px(value: string) {
  return parseFloat(value);
}

function close(
  assert: Assert,
  actual: number,
  expected: number,
  message: string,
  tolerance = 0.6
) {
  assert.true(
    Math.abs(actual - expected) <= tolerance,
    `${message} (expected ${expected}, got ${actual})`
  );
}

/** A theme color as computed `rgb()`. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.append(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

/** `1px solid #abc` -> the color part as `rgb()`. */
function borderColor(border: string) {
  return rgb(border.split(' ').slice(2).join(' '));
}

/**
 * Copies the rendered markup and every stylesheet rule (including Emotion's
 * inserted rules) into an iframe of the given width, so media queries are
 * evaluated against a real narrow viewport (see eui-flex-family-test).
 */
function inViewport(width: number, html: string) {
  const iframe = document.createElement('iframe');
  iframe.style.cssText = `position:fixed;top:0;left:0;width:${width}px;height:800px;border:0;visibility:hidden`;
  document.body.appendChild(iframe);
  const css = Array.from(document.styleSheets)
    .map((sheet) => {
      try {
        return Array.from(sheet.cssRules)
          .map((rule) => rule.cssText)
          .join('\n');
      } catch {
        return '';
      }
    })
    .join('\n');
  const doc = iframe.contentDocument!;
  doc.open();
  doc.write(
    `<!doctype html><html><head><style>${css}</style></head><body style="margin:0">${html}</body></html>`
  );
  doc.close();
  const win = iframe.contentWindow!;
  return {
    matches: (query: string) => win.matchMedia(query).matches,
    rect: (selector: string) => el(doc, selector).getBoundingClientRect(),
    style: (selector: string) => win.getComputedStyle(el(doc, selector)),
    remove: () => iframe.remove()
  };
}

module('Integration | Component | Borealis page layout', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiPage: padding sizes, grow, background and restricted width', async function (assert) {
    await render(
      <template>
        {{#each SIZES as |size|}}
          <EuiPage @paddingSize={{size}} data-padding={{size}}>
            <span>{{size}}</span>
          </EuiPage>
        {{/each}}
        <EuiPage data-default>x</EuiPage>
        <div style="display: flex; width: 1000px; height: 200px" data-row>
          <EuiPage @grow={{false}} data-fixed>fixed</EuiPage>
          <EuiPage data-grow>grows</EuiPage>
        </div>
        <div style="width: 1500px" data-wide>
          <EuiPage @restrictWidth={{true}} data-default-width>x</EuiPage>
          <EuiPage @restrictWidth={{600}} data-number-width>x</EuiPage>
          <EuiPage @restrictWidth="40rem" data-string-width>x</EuiPage>
          <EuiPage
            @restrictWidth={{500}}
            @style={{hash color="rgb(1, 2, 3)"}}
            data-merged-style
          >x</EuiPage>
        </div>
        <EuiPage @color="subdued" data-subdued>x</EuiPage>
      </template>
    );

    for (const size of SIZES) {
      const computed = style(this.element, `[data-padding="${size}"]`);
      for (const side of [
        computed.paddingTop,
        computed.paddingRight,
        computed.paddingBottom,
        computed.paddingLeft
      ])
        assert.strictEqual(side, `${PADDING[size]}px`, `padding ${size}`);
    }
    assert.dom('[data-default]').hasStyle({
      padding: '0px',
      display: 'flex',
      flexShrink: '0',
      flexGrow: '1',
      backgroundColor: 'rgba(0, 0, 0, 0)',
      boxSizing: 'border-box'
    });
    assert.dom('[data-default]').hasClass('euiPage');
    const row = box(this.element, '[data-row]');
    const fixed = box(this.element, '[data-fixed]');
    close(
      assert,
      box(this.element, '[data-grow]').width,
      row.width - fixed.width,
      'a growing page fills the remaining space'
    );
    assert.true(fixed.width < 100, 'grow=false keeps its content width');

    const wide = box(this.element, '[data-wide]');
    for (const [selector, width] of [
      ['[data-default-width]', 1200],
      ['[data-number-width]', 600],
      ['[data-string-width]', 40 * px(getComputedStyle(document.documentElement).fontSize)],
      ['[data-merged-style]', 500]
    ] as const) {
      const page = box(this.element, selector);
      close(assert, page.width, width, `${selector} max width`);
      close(
        assert,
        page.left - wide.left,
        wide.right - page.right,
        `${selector} is centered`
      );
    }
    assert
      .dom('[data-default-width]')
      .hasStyle({ maxWidth: '1200px' }, 'upstream PAGE_MAX_WIDTH');
    assert
      .dom('[data-merged-style]')
      .hasStyle({ color: 'rgb(1, 2, 3)', maxWidth: '500px' });
    assert
      .dom('[data-subdued]')
      .hasStyle({ backgroundColor: rgb(light.colors.backgroundBaseSubdued) });
  });

  test('EuiPage direction: rows from the m breakpoint, stacked below it, RTL', async function (assert) {
    await render(
      <template>
        <EuiPage data-row-page>
          <EuiPageSideBar data-side>Side</EuiPageSideBar>
          <EuiPageBody data-body>Body</EuiPageBody>
        </EuiPage>
        <EuiPage @direction="column" data-column-page>
          <EuiPageSideBar data-side>Side</EuiPageSideBar>
          <EuiPageBody data-body>Body</EuiPageBody>
        </EuiPage>
        <div dir="rtl">
          <EuiPage data-rtl-page>
            <EuiPageSideBar data-side>Side</EuiPageSideBar>
            <EuiPageBody data-body>Body</EuiPageBody>
          </EuiPage>
        </div>
      </template>
    );
    assert.false(
      window.matchMedia(`(max-width: ${BREAKPOINT - 1}px)`).matches,
      'the test window is wider than the breakpoint'
    );
    const at = (page: string, part: string) =>
      box(this.element, `${page} ${part}`);
    close(assert, at('[data-row-page]', '[data-side]').width, 248, 'default sidebar min width');
    close(
      assert,
      at('[data-row-page]', '[data-side]').right,
      at('[data-row-page]', '[data-body]').left,
      'row: side bar beside the body'
    );
    close(
      assert,
      at('[data-row-page]', '[data-side]').top,
      at('[data-row-page]', '[data-body]').top,
      'row: same line'
    );
    assert.true(
      at('[data-column-page]', '[data-side]').bottom <=
        at('[data-column-page]', '[data-body]').top + 0.5,
      'column: stacked'
    );
    close(
      assert,
      at('[data-rtl-page]', '[data-side]').left,
      at('[data-rtl-page]', '[data-body]').right,
      'RTL row: side bar on the right'
    );

    const html = el(this.element, '[data-row-page]').outerHTML;
    const narrow = inViewport(BREAKPOINT - 1, html);
    const wide = inViewport(BREAKPOINT, html);
    try {
      assert.strictEqual(narrow.style('.euiPage').flexDirection, 'column');
      assert.strictEqual(wide.style('.euiPage').flexDirection, 'row');
      close(
        assert,
        narrow.rect('[data-side]').width,
        BREAKPOINT - 1,
        'narrow: the side bar takes the full width'
      );
      assert.true(
        narrow.rect('[data-side]').bottom <= narrow.rect('[data-body]').top + 0.5,
        'narrow: the body is below the side bar'
      );
      close(assert, wide.rect('[data-side]').width, 248, 'wide: min width');
    } finally {
      narrow.remove();
      wide.remove();
    }
  });

  test('EuiPageBody: padding, tag, restricted width and the panelled variant', async function (assert) {
    await render(
      <template>
        {{#each BODY_SIZES as |size|}}
          <EuiPageBody @paddingSize={{size}} data-padding={{size}}>x</EuiPageBody>
        {{/each}}
        <EuiPageBody @tagName="main" data-tag>x</EuiPageBody>
        <div style="width: 1500px; display: flex" data-wide>
          <EuiPageBody @restrictWidth={{true}} data-restricted>x</EuiPageBody>
        </div>
        <div style="display: flex; height: 300px">
          <EuiPageBody @panelled={{true}} data-panelled>
            <span data-a>a</span><span data-b>b</span>
          </EuiPageBody>
        </div>
        <EuiPageBody
          @panelled={{true}}
          @paddingSize="l"
          @borderRadius="m"
          @color="subdued"
          @hasBorder={{false}}
          @restrictWidth={{400}}
          data-custom-panel
        >x</EuiPageBody>
      </template>
    );
    for (const size of ['none', 's', 'm', 'l'] as const)
      assert
        .dom(`[data-padding="${size}"]`)
        .hasStyle({ padding: `${PADDING[size]}px` }, `padding ${size}`);
    assert.dom('[data-padding="none"]').hasStyle({
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'stretch',
      flexGrow: '1',
      flexShrink: '1',
      minWidth: '0px'
    });
    assert.dom('main[data-tag]').hasClass('euiPageBody');
    const wide = box(this.element, '[data-wide]');
    const restricted = box(this.element, '[data-restricted]');
    close(assert, restricted.width, 1200, 'restricted to PAGE_MAX_WIDTH');
    close(
      assert,
      restricted.left - wide.left,
      wide.right - restricted.right,
      'restricted body is centered'
    );

    // Upstream passes the body styles as the panel's `css`, after its own,
    // so the body's flex column wins over the panel's display.
    assert
      .dom('[data-panelled]')
      .hasAttribute('data-eui-panel')
      .hasClass('euiPageBody')
      .hasStyle({
        display: 'flex',
        flexDirection: 'column',
        padding: '0px',
        borderRadius: '0px',
        backgroundColor: rgb(light.colors.backgroundBasePlain)
      });
    assert.true(
      box(this.element, '[data-panelled] [data-b]').top >=
        box(this.element, '[data-panelled] [data-a]').bottom - 0.5,
      'panelled children stack in a column'
    );
    assert.notStrictEqual(
      getComputedStyle(el(this.element, '[data-panelled]'), '::after').content,
      'none',
      'panelled body keeps the latest panel border'
    );
    assert.dom('[data-custom-panel]').hasStyle({
      padding: '24px',
      borderRadius: light.border.radius.panel,
      backgroundColor: rgb(light.colors.backgroundBaseSubdued),
      maxWidth: '400px'
    });
    assert.strictEqual(
      getComputedStyle(el(this.element, '[data-custom-panel]'), '::after')
        .content,
      'none'
    );
  });

  test('EuiPageContentBody and EuiPageContentHeader map onto latest section/header layouts', async function (assert) {
    await render(
      <template>
        <div style="width: 1000px" data-parent>
          {{#each SIZES as |size|}}
            <EuiPageContentBody @paddingSize={{size}} data-padding={{size}}>
              x
            </EuiPageContentBody>
          {{/each}}
          <EuiPageContentBody @restrictWidth={{600}} @paddingSize="l" data-restricted>
            x
          </EuiPageContentBody>
        </div>
        <EuiPageContentHeader style="width: 600px" data-header>
          <EuiPageContentHeaderSection data-a>Title</EuiPageContentHeaderSection>
          <EuiPageContentHeaderSection data-b>Actions</EuiPageContentHeaderSection>
        </EuiPageContentHeader>
        <div dir="rtl">
          <EuiPageContentHeader style="width: 600px" data-rtl-header>
            <EuiPageContentHeaderSection data-a>Title</EuiPageContentHeaderSection>
            <EuiPageContentHeaderSection data-b>Actions</EuiPageContentHeaderSection>
          </EuiPageContentHeader>
        </div>
        <EuiPageContentHeader @responsive={{true}} data-responsive>
          <EuiPageContentHeaderSection data-a>Title</EuiPageContentHeaderSection>
          <EuiPageContentHeaderSection data-b>Actions</EuiPageContentHeaderSection>
        </EuiPageContentHeader>
        <EuiPageContentHeader data-fixed>
          <EuiPageContentHeaderSection data-a>Title</EuiPageContentHeaderSection>
          <EuiPageContentHeaderSection data-b>Actions</EuiPageContentHeaderSection>
        </EuiPageContentHeader>
      </template>
    );
    const parent = box(this.element, '[data-parent]');
    for (const size of SIZES) {
      assert
        .dom(`[data-padding="${size}"]`)
        .hasStyle({ padding: `${PADDING[size]}px` }, `padding ${size}`)
        .hasClass('euiPageContentBody');
      close(
        assert,
        box(this.element, `[data-padding="${size}"]`).width,
        parent.width,
        `width 100% including ${size} padding (border-box)`
      );
    }
    const restricted = box(this.element, '[data-restricted]');
    close(assert, restricted.width, 600, 'restricted width');
    close(
      assert,
      restricted.left - parent.left,
      parent.right - restricted.right,
      'restricted content body is centered'
    );

    assert.dom('[data-header]').hasStyle({
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      columnGap: light.size.base,
      marginBottom: light.size.l
    });
    const header = box(this.element, '[data-header]');
    close(assert, box(this.element, '[data-header] [data-a]').left, header.left, 'first section starts');
    close(assert, box(this.element, '[data-header] [data-b]').right, header.right, 'last section ends');
    const rtl = box(this.element, '[data-rtl-header]');
    close(assert, box(this.element, '[data-rtl-header] [data-a]').right, rtl.right, 'RTL: first section on the right');
    close(assert, box(this.element, '[data-rtl-header] [data-b]').left, rtl.left, 'RTL: last section on the left');

    const html = (this.element as HTMLElement).innerHTML;
    const narrow = inViewport(BREAKPOINT - 1, html);
    const wide = inViewport(BREAKPOINT, html);
    try {
      assert.strictEqual(narrow.style('[data-responsive]').flexDirection, 'column');
      assert.strictEqual(narrow.style('[data-responsive]').alignItems, 'flex-start');
      close(
        assert,
        narrow.rect('[data-responsive] [data-b]').top -
          narrow.rect('[data-responsive] [data-a]').bottom,
        px(light.size.base),
        'narrow: stacked with the gap'
      );
      assert.strictEqual(narrow.style('[data-fixed]').flexDirection, 'row', 'not responsive');
      assert.strictEqual(wide.style('[data-responsive]').flexDirection, 'row');
    } finally {
      narrow.remove();
      wide.remove();
    }
  });

  test('EuiPageSideBar: min width, padding, embellish, sticky offsets and responsive', async function (assert) {
    class State {
      @tracked sticky: boolean | { offset: number } = true;
    }
    const state = new State();
    await render(
      <template>
        {{#each SIZES as |size|}}
          <EuiPageSideBar @paddingSize={{size}} data-padding={{size}}>x</EuiPageSideBar>
        {{/each}}
        <EuiPageSideBar @minWidth={{300}} data-number>x</EuiPageSideBar>
        <EuiPageSideBar @minWidth="20rem" data-string>x</EuiPageSideBar>
        <EuiPageSideBar @hasEmbellish={{true}} data-embellish>x</EuiPageSideBar>
        <EuiPageSideBar @sticky={{true}} @responsive={{false}} data-always>x</EuiPageSideBar>
        <EuiPageSideBar @sticky={{true}} @responsive={{ALL_BREAKPOINTS}} data-never>x</EuiPageSideBar>
        <div
          style="height: 300px; overflow: auto; --euiFixedHeadersOffset: 20px"
          data-scroller
        >
          <EuiPage>
            <EuiPageSideBar @sticky={{state.sticky}} data-sticky>Side</EuiPageSideBar>
            <EuiPageBody><div style="height: 2000px">Tall</div></EuiPageBody>
          </EuiPage>
        </div>
      </template>
    );
    for (const size of SIZES)
      assert
        .dom(`[data-padding="${size}"]`)
        .hasStyle({ padding: `${PADDING[size]}px` }, `padding ${size}`);
    assert
      .dom('[data-padding="none"]')
      .hasClass('euiPageSideBar')
      .hasStyle({ minWidth: '248px', flexGrow: '0', flexShrink: '1', position: 'static' });
    assert.dom('[data-number]').hasStyle({ minWidth: '300px' });
    assert.dom('[data-string]').hasStyle({
      minWidth: `${20 * px(getComputedStyle(document.documentElement).fontSize)}px`
    });
    assert.true(
      style(this.element, '[data-embellish]').backgroundImage.includes('linear-gradient'),
      'embellish gradient'
    );
    assert.dom('[data-always]').hasStyle({ position: 'sticky' });
    assert.dom('[data-never]').hasStyle({ position: 'static' });

    const sticky = el(this.element, '[data-sticky]');
    const scroller = el(this.element, '[data-scroller]');
    assert.dom(sticky).hasStyle({ position: 'sticky', top: '20px', overflowY: 'auto' });
    close(
      assert,
      px(getComputedStyle(sticky).maxHeight),
      window.innerHeight - 20,
      'max height is the viewport minus the fixed header offset'
    );
    scroller.scrollTop = 500;
    close(
      assert,
      box(this.element, '[data-sticky]').top - box(this.element, '[data-scroller]').top,
      20,
      'sticks below the fixed header offset while scrolling'
    );

    state.sticky = { offset: 48 };
    await settled();
    assert.strictEqual(el(this.element, '[data-sticky]'), sticky, 'same element');
    assert.dom(sticky).hasStyle({ top: '48px' });
    close(assert, px(getComputedStyle(sticky).maxHeight), window.innerHeight - 48, 'pixel offset');
    close(
      assert,
      box(this.element, '[data-sticky]').top - box(this.element, '[data-scroller]').top,
      48,
      'sticks at the pixel offset'
    );
    state.sticky = false;
    await settled();
    assert.dom(sticky).hasStyle({ position: 'static', maxHeight: 'none' });

    state.sticky = true;
    await settled();
    const html = el(this.element, '[data-scroller]').outerHTML;
    const narrow = inViewport(BREAKPOINT - 1, html);
    const wide = inViewport(BREAKPOINT, html);
    try {
      assert.strictEqual(narrow.style('[data-sticky]').position, 'static', 'never sticky while responding');
      assert.strictEqual(wide.style('[data-sticky]').position, 'sticky');
      close(assert, wide.rect('[data-sticky]').width, 248, 'wide min width');
    } finally {
      narrow.remove();
      wide.remove();
    }
    const always = inViewport(BREAKPOINT - 1, el(this.element, '[data-always]').outerHTML);
    try {
      assert.strictEqual(always.style('[data-always]').position, 'sticky', 'responsive=false stays sticky');
    } finally {
      always.remove();
    }
  });

  test('EuiPageHeader: title, icon, description, right side items, tabs and padding rules', async function (assert) {
    await render(
      <template>
        <EuiPageHeader
          @pageTitle="Dashboard"
          @iconType="dashboardApp"
          @description="Overview"
          @paddingSize="m"
          style="width: 900px"
          data-full
        >
          <:rightSideItems as |Item|>
            <Item><button type="button" data-first>First</button></Item>
            <Item><button type="button" data-second>Second</button></Item>
          </:rightSideItems>
        </EuiPageHeader>
        <EuiPageHeader @pageTitle="Bordered" @bottomBorder={{true}} data-border />
        <EuiPageHeader
          @pageTitle="Extended"
          @paddingSize="l"
          @bottomBorder="extended"
          data-extended
        />
        <EuiPageHeader @pageTitle="Tabs" @tabs={{TABS}} @paddingSize="l" data-title-tabs />
        <EuiPageHeader @tabs={{TABS}} @paddingSize="l" data-only-tabs />
        <EuiPageHeader @tabs={{TABS}} @description="Tab description" @paddingSize="l" data-tabs-title />
        <EuiPageHeader @pageTitle="Wide" @restrictWidth={{600}} style="width: 1000px" data-restricted />
        <EuiPageHeader @paddingSize="s" data-children>
          <EuiPageHeaderSection data-a>Left</EuiPageHeaderSection>
          <EuiPageHeaderSection data-b>Right</EuiPageHeaderSection>
        </EuiPageHeader>
      </template>
    );
    assert.dom('[data-full]').hasTagName('header').hasClass('euiPageHeader');
    assert.dom('[data-full] h1.euiTitle').containsText('Dashboard');
    assert.dom('[data-full] h1 svg.euiPageHeaderContent__titleIcon').exists('title icon');
    assert.dom('[data-full] .euiText p').hasText('Overview');
    assert.dom('[data-full]').hasStyle({
      display: 'flex',
      flexDirection: 'column',
      paddingLeft: '16px',
      paddingRight: '16px',
      paddingTop: '0px',
      backgroundColor: 'rgba(0, 0, 0, 0)'
    });
    assert.dom('[data-full] > .euiPageHeaderContent').hasStyle({
      paddingTop: '16px',
      paddingBottom: '16px',
      borderBottomWidth: '0px'
    });
    const full = box(this.element, '[data-full] > .euiPageHeaderContent');
    const right = box(this.element, '[data-full] .euiPageHeaderContent__rightSideItems');
    close(assert, right.right, full.right, 'right side items end on the right');
    assert.true(
      box(this.element, '[data-first]').left < box(this.element, '[data-second]').left,
      'items keep their block order'
    );
    close(
      assert,
      box(this.element, '[data-second]').left - box(this.element, '[data-first]').right,
      px(light.size.base),
      'items have an m gutter'
    );
    assert.true(
      box(this.element, '[data-full] h1').left < right.left,
      'title on the left'
    );

    const border = borderColor(light.border.thin);
    assert.dom('[data-border] > .euiPageHeaderContent').hasStyle({
      borderBottomWidth: '1px',
      borderBottomColor: border,
      paddingTop: '0px',
      paddingBottom: light.size.l
    });
    assert.dom('[data-border]').hasStyle({ borderBottomWidth: '0px' });
    assert.dom('[data-extended]').hasStyle({
      borderBottomWidth: '1px',
      borderBottomColor: border,
      paddingLeft: light.size.l
    });
    assert.dom('[data-extended] > .euiPageHeaderContent').hasStyle({
      borderBottomWidth: '0px',
      paddingTop: light.size.l,
      paddingBottom: light.size.l
    });

    assert.dom('[data-title-tabs] .euiPageHeaderContent__bottom .euiTab').exists({ count: 2 });
    assert.dom('[data-title-tabs] > .euiPageHeaderContent').hasStyle({
      paddingTop: light.size.l,
      paddingBottom: '0px',
      borderBottomWidth: '1px'
    });
    assert.dom('[data-only-tabs] > .euiPageHeaderContent').hasStyle({
      padding: '0px'
    });
    assert.dom('[data-only-tabs] h1').hasText('Tab A', 'screen reader title from the selected tab');
    assert.true(box(this.element, '[data-only-tabs] h1').width <= 1, 'visually hidden');
    assert.dom('[data-tabs-title] > .euiPageHeaderContent').hasStyle({
      paddingTop: '0px',
      paddingBottom: light.size.l
    });
    assert.dom('[data-tabs-title] .euiPageHeaderContent__bottom').doesNotExist();
    assert.true(
      box(this.element, '[data-tabs-title] .euiTabs').bottom <=
        box(this.element, '[data-tabs-title] .euiText').top + 0.5,
      'tabs act as the title above the description'
    );

    const restricted = box(this.element, '[data-restricted] > .euiPageHeaderContent');
    const restrictedHeader = box(this.element, '[data-restricted]');
    close(assert, restrictedHeader.width, 1000, 'the header stays full width');
    close(assert, restricted.width, 600, 'content max width');
    close(assert, restricted.left - restrictedHeader.left, restrictedHeader.right - restricted.right, 'content centered');

    const children = el(this.element, '[data-children] > .euiPageHeaderContent > div');
    assert.dom(children).hasStyle({
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      columnGap: light.size.base
    });
    assert.dom('[data-children] > .euiPageHeaderContent').hasStyle({
      paddingTop: '8px',
      paddingBottom: '8px'
    });
    assert.dom('[data-children]').hasStyle({ paddingLeft: '8px' });
  });

  test('EuiPageHeader: alignItems, responsive and reverse collapse at the breakpoint, RTL', async function (assert) {
    const alignments = ['top', 'bottom', 'center', 'stretch'] as const;
    const mapped = {
      top: 'flex-start',
      bottom: 'flex-end',
      center: 'center',
      stretch: 'stretch'
    };
    await render(
      <template>
        {{#each alignments as |align|}}
          <EuiPageHeader @pageTitle="T" @alignItems={{align}} data-align={{align}}>
            <:rightSideItems as |Item|><Item>R</Item></:rightSideItems>
          </EuiPageHeader>
        {{/each}}
        <EuiPageHeader @pageTitle="T" data-align-default />
        <EuiPageHeader @pageTitle="Title" data-responsive>
          <:rightSideItems as |Item|><Item><span data-right>Right</span></Item></:rightSideItems>
        </EuiPageHeader>
        <EuiPageHeader @pageTitle="Title" @responsive="reverse" data-reverse>
          <:rightSideItems as |Item|><Item><span data-right>Right</span></Item></:rightSideItems>
        </EuiPageHeader>
        <EuiPageHeader @pageTitle="Title" @responsive={{false}} data-fixed>
          <:rightSideItems as |Item|><Item><span data-right>Right</span></Item></:rightSideItems>
        </EuiPageHeader>
        <EuiPageHeader @responsive="reverse" data-children-reverse>
          <EuiPageHeaderSection data-a>A</EuiPageHeaderSection>
          <EuiPageHeaderSection data-b>B</EuiPageHeaderSection>
        </EuiPageHeader>
        <div dir="rtl">
          <EuiPageHeader @pageTitle="Title" style="width: 800px" data-rtl>
            <:rightSideItems as |Item|><Item><span data-right>Right</span></Item></:rightSideItems>
          </EuiPageHeader>
        </div>
      </template>
    );
    for (const align of alignments)
      assert
        .dom(`[data-align="${align}"] .euiPageHeaderContent__top`)
        .hasStyle({ alignItems: mapped[align] }, align);
    assert
      .dom('[data-align-default] .euiPageHeaderContent__top')
      .hasStyle({ alignItems: 'stretch', flexWrap: 'wrap', columnGap: light.size.l });
    assert.dom('[data-align-default] .euiPageHeaderContent__top').hasStyle({
      containerType: 'inline-size'
    });
    const rtl = box(this.element, '[data-rtl] > .euiPageHeaderContent');
    close(assert, box(this.element, '[data-rtl] [data-right]').left, rtl.left, 'RTL: right side items on the left', 1);
    close(assert, box(this.element, '[data-rtl] h1').right, rtl.right, 'RTL: title on the right', 1);

    const html = (this.element as HTMLElement).innerHTML;
    const narrow = inViewport(BREAKPOINT - 1, html);
    const wide = inViewport(BREAKPOINT, html);
    try {
      for (const view of [narrow, wide]) {
        const isNarrow = view === narrow;
        const title = view.rect('[data-responsive] h1');
        const rightItem = view.rect('[data-responsive] [data-right]');
        assert.strictEqual(
          rightItem.top >= title.bottom - 0.5,
          isNarrow,
          `${isNarrow ? 'narrow' : 'wide'}: right side items wrap below the title`
        );
        const reverseTitle = view.rect('[data-reverse] h1');
        const reverseRight = view.rect('[data-reverse] [data-right]');
        assert.strictEqual(
          reverseRight.bottom <= reverseTitle.top + 0.5,
          isNarrow,
          `${isNarrow ? 'narrow' : 'wide'}: reverse puts the items above the title`
        );
        assert.strictEqual(
          view.rect('[data-fixed] [data-right]').top < view.rect('[data-fixed] h1').bottom,
          true,
          'responsive=false keeps one row'
        );
        assert.strictEqual(
          view.style('[data-children-reverse] > .euiPageHeaderContent > div').flexDirection,
          isNarrow ? 'column-reverse' : 'row',
          'children-only reverse'
        );
      }
    } finally {
      narrow.remove();
      wide.remove();
    }
  });

  test('EuiBottomBar: fixed, static and sticky positions, padding and dark styling', async function (assert) {
    class State {
      @tracked padding: 'none' | 's' | 'm' | 'l' = 'm';
      @tracked position: 'static' | 'sticky' = 'static';
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider @colorMode="light" @globalStyles={{false}}>
          <EuiBottomBar @left={{12}} @right="1rem" data-fixed>
            <span data-content>Save</span>
          </EuiBottomBar>
          <div style="height: 200px; overflow: auto" data-scroller>
            <div style="height: 1000px" data-tall>Tall</div>
            <EuiBottomBar
              @position={{state.position}}
              @paddingSize={{state.padding}}
              data-inline
            >Inline</EuiBottomBar>
          </div>
          <EuiBottomBar @position="fixed" @usePortal={{false}} data-unportaled>Here</EuiBottomBar>
        </EuiEmotionProvider>
      </template>
    );
    const fixed = el(document.body, '[data-fixed]');
    assert.strictEqual(fixed.parentElement?.closest('#ember-testing'), null, 'fixed bars use a portal');
    assert
      .dom(fixed)
      .hasTagName('section')
      .hasClass('euiBottomBar')
      .hasClass('euiBottomBar--fixed')
      .hasStyle({
        position: 'fixed',
        zIndex: String(Number(dark.levels.header) - 2),
        left: '12px',
        bottom: '0px',
        padding: dark.size.base,
        backgroundColor: rgb(dark.components.bottomBarBackground),
        color: rgb(dark.colors.textParagraph),
        borderTopWidth: '1px',
        borderTopColor: borderColor(dark.border.thin)
      });
    assert.dom(fixed).hasStyle({
      right: `${px(getComputedStyle(document.documentElement).fontSize)}px`
    });
    // Compare with a plain fixed probe: the harness viewport is not
    // necessarily `window.innerHeight` tall.
    const probe = document.createElement('div');
    probe.style.cssText = 'position:fixed;bottom:0;left:0;right:0;height:1px';
    document.body.append(probe);
    const viewport = probe.getBoundingClientRect();
    probe.remove();
    // Upstream's appear animation slides the bar in from below.
    const animations = fixed.getAnimations();
    if (window.matchMedia('(prefers-reduced-motion: no-preference)').matches)
      assert.true(animations.length > 0, 'appear animation runs');
    animations.forEach((animation) => animation.finish());
    const rect = fixed.getBoundingClientRect();
    close(assert, rect.bottom, viewport.bottom, 'fixed to the bottom of the window');
    close(assert, rect.left, viewport.left + 12, 'left offset');
    assert.strictEqual(
      style(fixed, '.euiBottomBar__heading').position,
      'absolute',
      'landmark heading is visually hidden'
    );
    assert.true(
      el(fixed, '.euiBottomBar__heading').getBoundingClientRect().width <= 1,
      'landmark heading takes no visible space'
    );
    assert.dom('h2', fixed).hasText('Page level controls');

    const inline = el(this.element, '[data-inline]');
    assert.dom(inline).hasClass('euiBottomBar--static').hasStyle({ position: 'static', padding: '16px' });
    assert.true(
      box(this.element, '[data-inline]').top >= box(this.element, '[data-tall]').bottom - 0.5,
      'static bars render in place'
    );
    for (const [size, expected] of [['none', '0px'], ['s', dark.size.s], ['l', dark.size.l], ['m', dark.size.base]] as const) {
      state.padding = size;
      await settled();
      assert.dom(inline).hasStyle({ padding: expected }, `padding ${size}`);
    }
    state.position = 'sticky';
    await settled();
    assert.strictEqual(el(this.element, '[data-inline]'), inline, 'position change keeps the element');
    assert
      .dom(inline)
      .hasClass('euiBottomBar--sticky')
      .hasStyle({ position: 'sticky', bottom: '0px', top: 'auto' });
    inline.getAnimations().forEach((animation) => animation.finish());
    close(
      assert,
      box(this.element, '[data-inline]').bottom,
      box(this.element, '[data-scroller]').bottom,
      'sticky bars stick to the bottom of their scroll container'
    );

    const unportaled = el(this.element, '[data-unportaled]');
    assert.dom(unportaled).hasStyle({ position: 'fixed' });
    assert.ok(unportaled.closest('#ember-testing'), 'usePortal=false renders in place');
  });

  test('EuiBottomBar: body displacement, CSS offset variable, body class and cleanup', async function (assert) {
    class State {
      @tracked afford = true;
      @tracked visible = true;
      @tracked padding: 's' | 'l' = 's';
    }
    const state = new State();
    const before = document.body.style.paddingBottom;
    await render(
      <template>
        {{#if state.visible}}
          <EuiBottomBar
            @affordForDisplacement={{state.afford}}
            @paddingSize={{state.padding}}
            @bodyClassName="has-bottom-bar"
            @landmarkHeading="Form actions"
            data-bar
          >Save</EuiBottomBar>
        {{/if}}
        <EuiBottomBar @position="static" data-static>Static</EuiBottomBar>
      </template>
    );
    const bar = el(document.body, '[data-bar]');
    const offset = () =>
      document.documentElement.style.getPropertyValue('--euiBottomBarOffset');
    await waitUntil(() => document.body.style.paddingBottom !== before);
    close(
      assert,
      px(document.body.style.paddingBottom),
      bar.getBoundingClientRect().height,
      'body padding equals the bar height'
    );
    assert.strictEqual(offset(), document.body.style.paddingBottom);
    assert.dom(document.body).hasClass('has-bottom-bar');
    assert.dom(bar).hasAria('label', 'Form actions');
    assert.dom('[aria-live="assertive"]', document.body).includesText('Form actions');

    const small = px(document.body.style.paddingBottom);
    state.padding = 'l';
    await settled();
    await waitUntil(() => px(document.body.style.paddingBottom) > small);
    close(
      assert,
      px(document.body.style.paddingBottom) - small,
      2 * (px(light.size.l) - px(light.size.s)),
      'displacement follows the bar size'
    );

    state.afford = false;
    await settled();
    assert.strictEqual(document.body.style.paddingBottom, before, 'opt out removes the padding');
    assert.strictEqual(offset(), '', 'and the variable');
    assert.dom(document.body).hasClass('has-bottom-bar');

    state.afford = true;
    await settled();
    await waitUntil(() => document.body.style.paddingBottom !== before);
    state.visible = false;
    await settled();
    assert.strictEqual(document.body.style.paddingBottom, before, 'teardown restores the body');
    assert.strictEqual(offset(), '');
    assert.dom(document.body).doesNotHaveClass('has-bottom-bar');
    assert.dom('[data-bar]', document.body).doesNotExist();

    assert.dom('[data-static]').hasAria('label', 'Page level controls');
    await clearRender();
    assert.strictEqual(document.body.style.paddingBottom, before, 'static bars never displace');
  });

  test('reactive args update styles without replacing elements', async function (assert) {
    class State {
      @tracked padding: EuiPagePaddingSize = 'none';
      @tracked width: boolean | number = false;
      @tracked direction: 'row' | 'column' = 'row';
      @tracked grow = true;
      @tracked border: boolean | 'extended' = false;
      @tracked minWidth = 248;
      @tracked title = 'First';
    }
    const state = new State();
    await render(
      <template>
        <div style="width: 1500px; display: flex; flex-direction: column">
          <EuiPage
            @paddingSize={{state.padding}}
            @restrictWidth={{state.width}}
            @direction={{state.direction}}
            @grow={{state.grow}}
            data-page
          >
            <EuiPageSideBar @minWidth={{state.minWidth}} @paddingSize={{state.padding}} data-side>Side</EuiPageSideBar>
            <EuiPageBody @paddingSize="s" @restrictWidth={{state.width}} data-body>
              <EuiPageHeader
                @pageTitle={{state.title}}
                @bottomBorder={{state.border}}
                @paddingSize={{state.padding}}
                data-header
              />
              <EuiPageContentBody @paddingSize={{state.padding}} @restrictWidth={{state.width}} data-content>
                Content
              </EuiPageContentBody>
            </EuiPageBody>
          </EuiPage>
        </div>
      </template>
    );
    const ids = ['data-page', 'data-side', 'data-body', 'data-header', 'data-content'];
    const elements = ids.map((id) => el(this.element, `[${id}]`));
    const headerContent = el(this.element, '[data-header] > .euiPageHeaderContent');

    state.padding = 'xl';
    state.width = 900;
    state.direction = 'column';
    state.grow = false;
    state.border = true;
    state.minWidth = 320;
    state.title = 'Second';
    await settled();

    ids.forEach((id, i) =>
      assert.strictEqual(el(this.element, `[${id}]`), elements[i], `${id} kept`)
    );
    assert.strictEqual(
      el(this.element, '[data-header] > .euiPageHeaderContent'),
      headerContent,
      'header content kept'
    );
    assert.dom('[data-page]').hasStyle({
      padding: light.size.xl,
      maxWidth: '900px',
      flexDirection: 'column',
      flexGrow: '0'
    });
    assert.dom('[data-side]').hasStyle({ padding: light.size.xl, minWidth: '320px' });
    assert.dom('[data-body]').hasStyle({ maxWidth: '900px' });
    assert.dom('[data-header]').hasStyle({ paddingLeft: light.size.xl });
    assert.dom(headerContent).hasStyle({
      borderBottomWidth: '1px',
      paddingTop: light.size.xl,
      paddingBottom: light.size.xl
    });
    assert.dom('[data-header] h1').hasText('Second');
    assert.dom('[data-content]').hasStyle({ padding: light.size.xl, maxWidth: '900px' });

    state.border = 'extended';
    state.width = false;
    state.padding = 'none';
    await settled();
    assert.dom('[data-header]').hasStyle({ borderBottomWidth: '1px', paddingLeft: '0px' });
    assert.dom(headerContent).hasStyle({ borderBottomWidth: '0px', paddingTop: '0px', maxWidth: 'none' });
    assert.dom('[data-page]').hasStyle({ maxWidth: '100%', padding: '0px' });
    assert.dom('[data-content]').hasStyle({ maxWidth: 'none', padding: '0px' });
    ids.forEach((id, i) =>
      assert.strictEqual(el(this.element, `[${id}]`), elements[i], `${id} still kept`)
    );
  });

  test('light/dark nearest provider, sibling isolation and JS-object token overrides', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
      @tracked overrides: EuiBorealisOverrides = {};
    }
    const state = new State();
    const nested: EuiBorealisOverrides = {
      size: { base: '20px' },
      border: { color: '#ff0000' }
    } as EuiBorealisOverrides;
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}} @borealisOverrides={{state.overrides}} @globalStyles={{false}}>
          <EuiPage @color="plain" @paddingSize="m" data-page>
            <EuiPageBody>
              <EuiPageHeader @pageTitle="T" @bottomBorder="extended" data-header />
              <EuiBottomBar @position="static" data-bar>Bar</EuiBottomBar>
            </EuiPageBody>
          </EuiPage>
          <EuiEmotionProvider @borealisOverrides={{nested}}>
            <EuiPage @paddingSize="m" data-nested>
              <EuiPageHeader @pageTitle="T" @bottomBorder="extended" data-nested-header />
              <EuiBottomBar @position="static" data-nested-bar>Bar</EuiBottomBar>
            </EuiPage>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="dark" @globalStyles={{false}}>
          <EuiPage @color="plain" data-dark>
            <EuiPageHeader @pageTitle="T" @bottomBorder="extended" data-dark-header />
          </EuiPage>
        </EuiEmotionProvider>
        <EuiPage @color="plain" @paddingSize="m" data-outside>
          <EuiPageHeader @pageTitle="T" @bottomBorder="extended" data-outside-header />
        </EuiPage>
      </template>
    );
    const page = el(this.element, '[data-page]');
    assert.dom(page).hasStyle({
      backgroundColor: rgb(light.colors.backgroundBasePlain),
      padding: light.size.base
    });
    assert.dom('[data-header]').hasStyle({ borderBottomColor: borderColor(light.border.thin) });
    assert.dom('[data-dark]').hasStyle({ backgroundColor: rgb(dark.colors.backgroundBasePlain) });
    assert.dom('[data-dark-header]').hasStyle({ borderBottomColor: borderColor(dark.border.thin) });
    assert.dom('[data-bar]').hasStyle({
      color: rgb(dark.colors.textParagraph),
      backgroundColor: rgb(dark.components.bottomBarBackground)
    });
    assert.dom('[data-nested]').hasStyle({ padding: '20px' });
    assert.dom('[data-nested-header]').hasStyle({ borderBottomColor: 'rgb(255, 0, 0)' });
    assert.dom('[data-nested-bar]').hasStyle({ padding: '20px' }, 'the dark bar inherits overrides');

    state.mode = 'dark';
    state.overrides = { size: { base: '10px' } } as EuiBorealisOverrides;
    await settled();
    assert.strictEqual(el(this.element, '[data-page]'), page, 'same element');
    assert.dom(page).hasStyle({
      backgroundColor: rgb(dark.colors.backgroundBasePlain),
      padding: '10px'
    });
    assert.dom('[data-header]').hasStyle({ borderBottomColor: borderColor(dark.border.thin) });
    assert.dom('[data-bar]').hasStyle({ padding: '10px' });
    assert.dom('[data-nested]').hasStyle({ padding: '20px' }, 'the nearest provider wins');
    assert.dom('[data-nested-header]').hasStyle({ borderBottomColor: 'rgb(255, 0, 0)' });
    assert.dom('[data-outside]').hasStyle({
      backgroundColor: rgb(light.colors.backgroundBasePlain),
      padding: light.size.base
    });
    assert.dom('[data-outside-header]').hasStyle({ borderBottomColor: borderColor(light.border.thin) });
    assert.dom('[data-dark]').hasStyle({ backgroundColor: rgb(dark.colors.backgroundBasePlain) });

    state.overrides = {};
    await settled();
    assert.dom(page).hasStyle({ padding: light.size.base });
  });

  test('EuiPageTemplate full height uses the latest utility mixins', async function (assert) {
    await render(
      <template>
        <div style="height: 500px; display: flex; flex-direction: column">
          <EuiPageTemplate @fullHeight={{true}} @minHeight={{0}} @pageHeader={{hash pageTitle="T"}}>
            <:default><div style="height: 2000px; flex-shrink: 0" data-tall>Tall</div></:default>
            <:bottomBar>Save</:bottomBar>
          </EuiPageTemplate>
        </div>
      </template>
    );
    // The test window is wider than `m`, so full height is active.
    assert.dom('.euiPageTemplate').hasClass('eui-fullHeight').hasStyle({ overflow: 'hidden' });
    const item = el(this.element, '.euiPageContentBody > .euiFlexGroup > .euiFlexItem');
    assert.dom(item).hasClass('eui-yScroll').hasStyle({ overflowY: 'auto', overflowX: 'hidden' });
    assert.true(item.scrollHeight > item.clientHeight, 'content scrolls inside the page');
    assert
      .dom('.euiBottomBar')
      .hasClass('euiBottomBar--static')
      .hasStyle({ overflow: 'hidden', flexShrink: '0' });
    assert.true(box(this.element, '.euiPageTemplate').height <= 500.5, 'page stays within its height');
  });
});
