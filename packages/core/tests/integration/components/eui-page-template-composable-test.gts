import { tracked } from '@glimmer/tracking';
import {
  getDeprecations,
  render,
  settled
} from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import EuiButton from '#src/components/eui-button.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiEmptyPrompt from '#src/components/eui-empty-prompt.gts';
import EuiPageSection from '#src/components/eui-page-section.gts';
import EuiPageTemplate from '#src/components/eui-page-template.gts';
import EuiPageTemplateSidebar from '#src/components/eui-page-template/sidebar.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type {
  EuiPageBreakpoint,
  EuiPagePaddingSize
} from '#src/utils/eui/page-layout.ts';

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;
/** Borealis `m` breakpoint; the template responds below it by default. */
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
const NO_BREAKPOINTS: EuiPageBreakpoint[] = [];
const ALL_BREAKPOINTS: EuiPageBreakpoint[] = ['xs', 's', 'm', 'l', 'xl'];
const TABS = [
  { label: 'Tab 1', isSelected: true },
  { label: 'Tab 2' }
];
const MAIN_PROPS = {
  id: 'customID',
  className: 'customClassName',
  'aria-label': 'Content',
  'data-test-subj': 'main',
  style: { color: 'rgb(1, 2, 3)' }
};
const PAGE_CSS = { outlineStyle: 'dotted' };
const MAIN_CSS_PROPS = { css: { outlineStyle: 'dashed' } };

function el(root: ParentNode, selector: string): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function style(root: ParentNode, selector: string) {
  return getComputedStyle(el(root, selector));
}

function px(value: string) {
  return parseFloat(value);
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

const TRANSPARENT = 'rgba(0, 0, 0, 0)';

/**
 * Copies the rendered markup and every stylesheet rule (including Emotion's
 * inserted rules) into an iframe of the given width, so media queries are
 * evaluated against a real narrow viewport (see eui-page-layout-test).
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
    rect: (selector: string) => el(doc, selector).getBoundingClientRect(),
    style: (selector: string) => win.getComputedStyle(el(doc, selector)),
    remove: () => iframe.remove()
  };
}

function legacyDeprecations() {
  return getDeprecations().filter(
    (d) => d.options?.id === 'ember-eui.eui-page-template-legacy.removed-upstream'
  );
}

module('Integration | Component | EuiPageTemplate composable', function (hooks) {
  setupRenderingTest(hooks);

  // upstream: 'is rendered' (+ shouldRenderCustomStyles)
  test('renders the outer page and the main element', async function (assert) {
    await render(
      <template>
        <EuiPageTemplate
          class="testClass1 testClass2"
          aria-label="aria-label"
          data-test-subj="test subject string"
          @css={{PAGE_CSS}}
          as |T|
        >
          <T.Section>Content</T.Section>
        </EuiPageTemplate>
      </template>
    );

    const page = el(this.element, '.euiPageTemplate');
    assert.dom(page).hasClass('testClass1').hasClass('testClass2');
    assert.dom(page).hasAttribute('aria-label', 'aria-label');
    assert.dom(page).hasAttribute('data-test-subj', 'test subject string');
    assert.strictEqual(page.tagName, 'DIV');
    assert.strictEqual(page.style.getPropertyValue('min-block-size'), 'max(460px, 100vh)');
    assert.strictEqual(
      page.style.getPropertyValue('padding-block-start'),
      'var(--euiFixedHeadersOffset, 0)'
    );

    const outer = getComputedStyle(page);
    assert.strictEqual(outer.display, 'flex');
    assert.strictEqual(outer.flexDirection, 'row');
    assert.strictEqual(outer.flexGrow, '1');
    assert.strictEqual(outer.flexShrink, '0');
    assert.strictEqual(outer.maxWidth, '100%');
    assert.strictEqual(outer.outlineStyle, 'dotted', '@css is composed into the page');

    const main = el(page, 'main');
    assert.strictEqual(main.parentElement, page, 'main is a direct child');
    assert.true(main.id.startsWith('EuiPageTemplateInner_'), 'generated inner id');
    const inner = getComputedStyle(main);
    assert.strictEqual(inner.display, 'flex');
    assert.strictEqual(inner.flexDirection, 'column');
    assert.strictEqual(inner.alignItems, 'stretch');
    assert.strictEqual(inner.flexBasis, '100%');
    assert.strictEqual(inner.minWidth, '0px');
    assert.strictEqual(inner.backgroundColor, TRANSPARENT, 'not panelled without a sidebar');
    assert.strictEqual(inner.borderLeftStyle, 'none');
    assert.strictEqual(inner.boxShadow, 'none');
    assert.dom('main .euiPageSection').hasText('Content');
  });

  // upstream: '_EuiPageOuterProps is rendered'
  test('outer props: grow, direction and responsive', async function (assert) {
    await render(
      <template>
        <EuiPageTemplate
          @grow={{false}}
          @direction="column"
          @responsive={{NO_BREAKPOINTS}}
          data-outer
          as |T|
        >
          <T.Section>A</T.Section>
        </EuiPageTemplate>
      </template>
    );
    const page = el(this.element, '[data-outer]');
    assert.strictEqual(page.style.getPropertyValue('min-block-size'), '460px', 'no 100vh without grow');
    assert.strictEqual(getComputedStyle(page).flexGrow, '0');
    assert.strictEqual(getComputedStyle(page).flexDirection, 'column');
  });

  // upstream: '_EuiPageInnerProps is rendered' / 'renders as panelled'
  test('inner props: component, contentBorder, panelled and mainProps', async function (assert) {
    await render(
      <template>
        <EuiPageTemplate
          @component="div"
          @contentBorder={{true}}
          @panelled={{false}}
          @mainProps={{MAIN_PROPS}}
          data-a
          as |T|
        >
          <T.Section>A</T.Section>
        </EuiPageTemplate>
        <EuiPageTemplate
          @component="div"
          @panelled={{true}}
          @mainProps={{MAIN_CSS_PROPS}}
          data-b
          as |T|
        >
          <T.Section>B</T.Section>
        </EuiPageTemplate>
      </template>
    );

    assert.dom('[data-a] main').doesNotExist();
    const a = el(this.element, '[data-a] > div');
    assert.strictEqual(a.id, 'customID');
    assert.dom(a).hasClass('customClassName');
    assert.dom(a).hasAttribute('aria-label', 'Content');
    assert.dom(a).hasAttribute('data-test-subj', 'main');
    assert.strictEqual(getComputedStyle(a).color, 'rgb(1, 2, 3)', 'mainProps.style');
    assert.strictEqual(getComputedStyle(a).backgroundColor, TRANSPARENT);
    assert.strictEqual(getComputedStyle(a).borderLeftStyle, 'solid', 'content border');
    assert.strictEqual(px(getComputedStyle(a).borderLeftWidth), 1);
    assert.strictEqual(
      getComputedStyle(a).borderLeftColor,
      borderColor(light.border.thin)
    );
    assert.strictEqual(getComputedStyle(a).borderTopStyle, 'none');

    const b = el(this.element, '[data-b] > div');
    assert.strictEqual(getComputedStyle(b).backgroundColor, rgb(light.colors.backgroundBasePlain));
    assert.notStrictEqual(getComputedStyle(b).boxShadow, 'none', 'panelled shadow');
    assert.strictEqual(getComputedStyle(b).borderLeftStyle, 'none', 'no sidebar, no border');
    assert.strictEqual(getComputedStyle(b).outlineStyle, 'dashed', 'mainProps.css');
  });

  // upstream: 'restrict width'
  test('restrictWidth is shared by the header, sections and bottom bar', async function (assert) {
    await render(
      <template>
        <EuiPageTemplate data-default as |T|>
          <T.Header @pageTitle="Title" />
          <T.Section>A</T.Section>
          <T.BottomBar>Bar</T.BottomBar>
        </EuiPageTemplate>
        <EuiPageTemplate @restrictWidth={{1024}} data-number as |T|>
          <T.Header @pageTitle="Title" />
          <T.Section>A</T.Section>
          <T.EmptyPrompt @title="Empty" @restrictWidth={{true}} />
        </EuiPageTemplate>
        <EuiPageTemplate @restrictWidth="24rem" data-string as |T|>
          <T.Section>A</T.Section>
        </EuiPageTemplate>
        <EuiPageTemplate @restrictWidth={{false}} data-none as |T|>
          <T.Section>A</T.Section>
        </EuiPageTemplate>
      </template>
    );

    const content = (page: string) =>
      el(this.element, `[data-${page}] main > .euiPageSection > .euiPageSection__content`);
    assert.strictEqual(content('default').style.maxWidth, '1200px');
    assert.strictEqual(content('number').style.maxWidth, '1024px');
    assert.strictEqual(content('string').style.maxWidth, '24rem');
    assert.strictEqual(content('none').style.maxWidth, '');
    assert.strictEqual(getComputedStyle(content('number')).marginLeft, getComputedStyle(content('number')).marginRight);

    assert.strictEqual(
      el(this.element, '[data-default] .euiPageHeader .euiPageHeaderContent').style.maxWidth,
      '1200px'
    );
    assert.strictEqual(
      el(this.element, '[data-number] .euiPageHeader .euiPageHeaderContent').style.maxWidth,
      '1024px'
    );
    assert.strictEqual(
      el(this.element, '[data-default] .euiBottomBar .euiPageSection__content').style.maxWidth,
      '1200px'
    );
    // The empty prompt does not inherit the width, but takes its own.
    assert.strictEqual(
      el(this.element, '[data-number] .euiEmptyPrompt').closest<HTMLElement>('.euiPageSection__content')!.style.maxWidth,
      '1200px'
    );
  });

  // upstream: 'bottomBorder'
  test('bottomBorder goes on the header: true, extended and the defaults', async function (assert) {
    await render(
      <template>
        <EuiPageTemplate @bottomBorder={{true}} data-true as |T|>
          <T.Header @pageTitle="Title" />
        </EuiPageTemplate>
        <EuiPageTemplate @bottomBorder="extended" data-extended as |T|>
          <T.Header @pageTitle="Title" />
        </EuiPageTemplate>
        <EuiPageTemplate data-default-extended as |T|>
          <T.Header @pageTitle="Title" />
        </EuiPageTemplate>
        <EuiPageTemplate data-sidebar-true>
          <:sidebar as |T|><T.Sidebar>Nav</T.Sidebar></:sidebar>
          <:default as |T|><T.Header @pageTitle="Title" /></:default>
        </EuiPageTemplate>
        <EuiPageTemplate @bottomBorder={{false}} data-false as |T|>
          <T.Header @pageTitle="Title" @tabs={{TABS}} />
        </EuiPageTemplate>
      </template>
    );

    const header = (page: string) => style(this.element, `[data-${page}] .euiPageHeader`);
    const content = (page: string) =>
      style(this.element, `[data-${page}] .euiPageHeader .euiPageHeaderContent`);

    assert.strictEqual(header('true').borderBottomStyle, 'none');
    assert.strictEqual(content('true').borderBottomStyle, 'solid', 'true: within the content');
    assert.strictEqual(header('extended').borderBottomStyle, 'solid', 'extended: on the header');
    assert.strictEqual(content('extended').borderBottomStyle, 'none');
    assert.strictEqual(header('default-extended').borderBottomStyle, 'solid', "no sidebar: 'extended'");
    assert.strictEqual(content('sidebar-true').borderBottomStyle, 'solid', 'sidebar: true');
    assert.strictEqual(header('sidebar-true').borderBottomStyle, 'none');
    assert.strictEqual(content('false').borderBottomStyle, 'none', 'false wins over tabs');
    assert.strictEqual(header('false').borderBottomStyle, 'none');
    assert.strictEqual(
      header('extended').borderBottomColor,
      borderColor(light.border.thin)
    );
  });

  // upstream: 'minHeight is rendered' / 'offset is rendered'
  test('minHeight and offset', async function (assert) {
    class State {
      @tracked offset: number | undefined = 100;
      @tracked minHeight: string | number = '40vh';
    }
    const state = new State();
    await render(
      <template>
        <EuiPageTemplate @minHeight={{state.minHeight}} @offset={{state.offset}} data-page as |T|>
          <T.Section>A</T.Section>
        </EuiPageTemplate>
      </template>
    );
    const page = el(this.element, '[data-page]');
    assert.strictEqual(page.style.getPropertyValue('min-block-size'), 'max(40vh, 100vh)');
    assert.strictEqual(page.style.getPropertyValue('padding-block-start'), '100px');
    assert.strictEqual(getComputedStyle(page).paddingTop, '100px');

    state.offset = 0;
    state.minHeight = 300;
    await settled();
    assert.strictEqual(el(this.element, '[data-page]'), page, 'same element');
    assert.strictEqual(page.style.getPropertyValue('padding-block-start'), '0px', '0 ignores fixed headers');
    assert.strictEqual(page.style.getPropertyValue('min-block-size'), 'max(300px, 100vh)');

    state.offset = undefined;
    await settled();
    document.documentElement.style.setProperty('--euiFixedHeadersOffset', '48px');
    try {
      assert.strictEqual(getComputedStyle(page).paddingTop, '48px', 'fixed headers offset');
    } finally {
      document.documentElement.style.removeProperty('--euiFixedHeadersOffset');
    }
  });

  // upstream: 'paddingSize'
  test('paddingSize is shared by the header, sections, sidebar and bottom bar', async function (assert) {
    await render(
      <template>
        {{#each SIZES as |size|}}
          <EuiPageTemplate @paddingSize={{size}} data-padding={{size}}>
            <:sidebar as |T|><T.Sidebar>Nav</T.Sidebar></:sidebar>
            <:default as |T|>
              <T.Header @pageTitle="Title" />
              <T.Section>A</T.Section>
              <T.BottomBar>Bar</T.BottomBar>
            </:default>
          </EuiPageTemplate>
        {{/each}}
      </template>
    );
    for (const size of SIZES) {
      const at = (selector: string) => style(this.element, `[data-padding="${size}"] ${selector}`);
      assert.strictEqual(px(at('main > .euiPageSection').paddingLeft), PADDING[size], `${size}: section inline`);
      assert.strictEqual(px(at('main > .euiPageSection > .euiPageSection__content').paddingTop), PADDING[size], `${size}: section block`);
      assert.strictEqual(px(at('.euiPageHeader').paddingLeft), PADDING[size], `${size}: header`);
      assert.strictEqual(px(at('.euiPageSidebar').paddingTop), PADDING[size], `${size}: sidebar`);
      assert.strictEqual(px(at('.euiBottomBar .euiPageSection').paddingRight), PADDING[size], `${size}: bottom bar`);
    }
  });

  // upstream: 'children'
  test('sidebars go beside the main element; everything else inside it, in order', async function (assert) {
    const RED = { color: 'red' };
    await render(
      <template>
        <EuiPageTemplate data-sidebars>
          <:sidebar as |T|>
            <T.Sidebar data-first />
            <T.Sidebar @css={{RED}} data-second />
          </:sidebar>
        </EuiPageTemplate>
        <EuiPageTemplate data-children as |T|>
          <T.Header>A</T.Header>
          <T.Section>B</T.Section>
          <section>C</section>
        </EuiPageTemplate>
      </template>
    );

    const sidebars = el(this.element, '[data-sidebars]');
    const children = Array.from(sidebars.children);
    assert.deepEqual(
      children.map((child) => child.tagName),
      ['DIV', 'DIV', 'MAIN'],
      'two sidebars, then main'
    );
    assert.dom(children[0]).hasClass('euiPageSidebar');
    assert.strictEqual(getComputedStyle(children[1]!).color, 'rgb(255, 0, 0)', 'sidebar @css');
    assert.strictEqual(el(sidebars, 'main').childElementCount, 0);
    assert.strictEqual(getComputedStyle(children[0]!).minWidth, '248px');

    const main = el(this.element, '[data-children] main');
    assert.strictEqual(main.childElementCount, 3);
    assert.deepEqual(
      Array.from(main.children).map((child) => child.textContent?.trim()),
      ['A', 'B', 'C'],
      'stacked in the given order'
    );
    assert.dom(main.children[0]).hasClass('euiPageHeader');
    assert.dom(main.children[1]).hasClass('euiPageSection');
  });

  test('parts inherit the template settings; their own args override them', async function (assert) {
    class State {
      @tracked panelled: boolean | undefined = undefined;
      @tracked paddingSize: EuiPagePaddingSize = 'l';
    }
    const state = new State();
    await render(
      <template>
        <EuiPageTemplate
          @panelled={{state.panelled}}
          @paddingSize={{state.paddingSize}}
          data-page
          as |T|
        >
          <T.Header @pageTitle="Title" data-header />
          <T.Section data-section>A</T.Section>
          <T.Section @color="subdued" @paddingSize="s" @grow={{false}} data-custom>B</T.Section>
          <EuiPageSection data-plain>C</EuiPageSection>
        </EuiPageTemplate>
      </template>
    );
    const plain = rgb(light.colors.backgroundBasePlain);
    const section = el(this.element, '[data-section]');

    assert.strictEqual(getComputedStyle(section).backgroundColor, plain, 'section: plain');
    assert.strictEqual(style(this.element, '[data-header]').backgroundColor, plain, 'header: plain');
    assert.strictEqual(getComputedStyle(section).flexGrow, '1', 'section grows');
    assert.strictEqual(
      style(this.element, '[data-custom]').backgroundColor,
      rgb(light.colors.backgroundBaseSubdued),
      'own color wins'
    );
    assert.strictEqual(px(style(this.element, '[data-custom]').paddingLeft), PADDING.s, 'own padding wins');
    assert.strictEqual(style(this.element, '[data-custom]').flexGrow, '0', 'own grow wins');
    assert.strictEqual(style(this.element, '[data-plain]').backgroundColor, TRANSPARENT, 'non-namespaced section does not inherit');
    assert.strictEqual(
      el(this.element, '[data-plain] .euiPageSection__content').style.maxWidth,
      '',
      'nor the width'
    );

    state.panelled = false;
    state.paddingSize = 'm';
    await settled();
    assert.strictEqual(el(this.element, '[data-section]'), section, 'same element');
    assert.strictEqual(getComputedStyle(section).backgroundColor, TRANSPARENT, 'panelled=false: transparent');
    assert.strictEqual(style(this.element, '[data-header]').backgroundColor, TRANSPARENT);
    assert.strictEqual(px(getComputedStyle(section).paddingLeft), PADDING.m, 'padding follows');
    assert.strictEqual(px(style(this.element, '[data-custom]').paddingLeft), PADDING.s);
  });

  test('a sidebar panels and borders the content and panels the empty prompt', async function (assert) {
    await render(
      <template>
        <EuiPageTemplate data-with>
          <:sidebar as |T|><T.Sidebar @sticky={{true}}>Nav</T.Sidebar></:sidebar>
          <:default as |T|>
            <T.EmptyPrompt @title="Empty">Body</T.EmptyPrompt>
          </:default>
        </EuiPageTemplate>
        <EuiPageTemplate data-without as |T|>
          <T.EmptyPrompt @title="Empty">Body</T.EmptyPrompt>
        </EuiPageTemplate>
        <EuiPageTemplate @panelled={{false}} @contentBorder={{false}} data-opt-out>
          <:sidebar as |T|><T.Sidebar>Nav</T.Sidebar></:sidebar>
          <:default as |T|>
            <T.EmptyPrompt @title="Empty">Body</T.EmptyPrompt>
          </:default>
        </EuiPageTemplate>
      </template>
    );
    const plain = rgb(light.colors.backgroundBasePlain);
    const subdued = rgb(light.colors.backgroundBaseSubdued);
    const at = (page: string, selector: string) => style(this.element, `[data-${page}] ${selector}`);

    assert.strictEqual(at('with', 'main').backgroundColor, plain, 'sidebar: panelled');
    assert.strictEqual(at('with', 'main').borderLeftStyle, 'solid', 'sidebar: bordered');
    assert.strictEqual(at('with', '.euiPageSection').backgroundColor, plain, 'panelled prompt: plain section');
    assert.strictEqual(at('with', '.euiEmptyPrompt').backgroundColor, subdued, 'panelled prompt: subdued');
    assert.strictEqual(at('with', '.euiPageSidebar').position, 'sticky', 'sidebar args still apply');

    assert.strictEqual(at('without', 'main').backgroundColor, TRANSPARENT);
    assert.strictEqual(at('without', '.euiPageSection').backgroundColor, TRANSPARENT, 'transparent section');
    assert.strictEqual(at('without', '.euiEmptyPrompt').backgroundColor, plain, 'plain prompt');

    assert.strictEqual(at('opt-out', 'main').backgroundColor, TRANSPARENT, 'panelled=false');
    assert.strictEqual(at('opt-out', 'main').borderLeftStyle, 'none', 'contentBorder=false');
    assert.strictEqual(at('opt-out', '.euiEmptyPrompt').backgroundColor, plain);
  });

  test('a conditional sidebar updates the layout without replacing the content', async function (assert) {
    class State {
      @tracked showSidebar = true;
      @tracked second = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiPageTemplate data-page>
          <:sidebar as |T|>
            {{#if state.showSidebar}}<T.Sidebar data-one>Nav</T.Sidebar>{{/if}}
            {{#if state.second}}<T.Sidebar data-two>More</T.Sidebar>{{/if}}
          </:sidebar>
          <:default as |T|>
            <T.Header @pageTitle="Title" />
            <T.EmptyPrompt @title="Empty" />
          </:default>
        </EuiPageTemplate>
      </template>
    );
    const plain = rgb(light.colors.backgroundBasePlain);
    const main = el(this.element, '[data-page] main');
    const header = el(this.element, '[data-page] .euiPageHeader');
    const prompt = el(this.element, '[data-page] .euiEmptyPrompt');
    const assertLayout = (withSidebar: boolean, message: string) => {
      assert.strictEqual(getComputedStyle(main).backgroundColor, withSidebar ? plain : TRANSPARENT, `${message}: panelled`);
      assert.strictEqual(getComputedStyle(main).borderLeftStyle, withSidebar ? 'solid' : 'none', `${message}: border`);
      assert.strictEqual(getComputedStyle(header).borderBottomStyle, withSidebar ? 'none' : 'solid', `${message}: header border`);
      assert.strictEqual(
        getComputedStyle(el(header, '.euiPageHeaderContent')).borderBottomStyle,
        withSidebar ? 'solid' : 'none',
        `${message}: header content border`
      );
      assert.strictEqual(
        getComputedStyle(prompt).backgroundColor,
        rgb(withSidebar ? light.colors.backgroundBaseSubdued : light.colors.backgroundBasePlain),
        `${message}: prompt`
      );
    };

    assertLayout(true, 'one sidebar');
    state.showSidebar = false;
    await settled();
    assert.dom('[data-page] .euiPageSidebar').doesNotExist();
    assert.strictEqual(el(this.element, '[data-page] main'), main, 'same main');
    assert.strictEqual(el(this.element, '[data-page] .euiEmptyPrompt'), prompt, 'same prompt');
    assertLayout(false, 'no sidebar');

    state.second = true;
    await settled();
    assertLayout(true, 'another sidebar');
    state.showSidebar = true;
    await settled();
    assert.dom('[data-page] > .euiPageSidebar').exists({ count: 2 });
    state.second = false;
    await settled();
    assertLayout(true, 'still one sidebar');
  });

  test('responsive: the sidebar stacks above the content on narrow screens', async function (assert) {
    await render(
      <template>
        <EuiPageTemplate @offset={{0}} data-default>
          <:sidebar as |T|><T.Sidebar @sticky={{true}} data-sidebar>Nav</T.Sidebar></:sidebar>
          <:default as |T|><T.Section>A</T.Section></:default>
        </EuiPageTemplate>
        <EuiPageTemplate @offset={{0}} @responsive={{NO_BREAKPOINTS}} data-never>
          <:sidebar as |T|><T.Sidebar data-sidebar>Nav</T.Sidebar></:sidebar>
          <:default as |T|><T.Section>A</T.Section></:default>
        </EuiPageTemplate>
        <EuiPageTemplate @offset={{0}} @responsive={{ALL_BREAKPOINTS}} data-always>
          <:sidebar as |T|><T.Sidebar data-sidebar>Nav</T.Sidebar></:sidebar>
          <:default as |T|><T.Section>A</T.Section></:default>
        </EuiPageTemplate>
      </template>
    );
    const html = (this.element as HTMLElement).innerHTML;
    const narrow = inViewport(BREAKPOINT - 1, html);
    const wide = inViewport(BREAKPOINT, html);
    try {
      assert.strictEqual(narrow.style('[data-default]').flexDirection, 'column', 'narrow: stacked');
      assert.strictEqual(narrow.style('[data-default] main').borderTopStyle, 'solid', 'narrow: top border');
      assert.strictEqual(narrow.style('[data-default] main').borderLeftStyle, 'none');
      assert.strictEqual(narrow.style('[data-default] [data-sidebar]').minWidth, '100%', 'narrow: full width sidebar');
      assert.strictEqual(narrow.style('[data-default] [data-sidebar]').position, 'static', 'narrow: not sticky');
      assert.true(
        narrow.rect('[data-default] main').top >= narrow.rect('[data-default] [data-sidebar]').bottom - 0.5,
        'narrow: content under the sidebar'
      );

      assert.strictEqual(wide.style('[data-default]').flexDirection, 'row', 'wide: side by side');
      assert.strictEqual(wide.style('[data-default] main').borderLeftStyle, 'solid', 'wide: left border');
      assert.strictEqual(wide.style('[data-default] main').borderTopStyle, 'none');
      assert.strictEqual(wide.style('[data-default] [data-sidebar]').minWidth, '248px');
      assert.strictEqual(wide.style('[data-default] [data-sidebar]').position, 'sticky');

      assert.strictEqual(narrow.style('[data-never]').flexDirection, 'row', 'responsive=[]: never stacks');
      assert.strictEqual(narrow.style('[data-never] main').borderLeftStyle, 'solid');
      assert.strictEqual(narrow.style('[data-never] [data-sidebar]').minWidth, '248px');

      assert.strictEqual(wide.style('[data-always]').flexDirection, 'column', 'all breakpoints: always stacked');
      assert.strictEqual(wide.style('[data-always] main').borderTopStyle, 'solid');
      assert.strictEqual(wide.style('[data-always] main').borderLeftStyle, 'none');
    } finally {
      narrow.remove();
      wide.remove();
    }
  });

  test('RTL: the content border is on the inline start', async function (assert) {
    await render(
      <template>
        <div dir="rtl">
          <EuiPageTemplate @responsive={{NO_BREAKPOINTS}} data-page>
            <:sidebar as |T|><T.Sidebar>Nav</T.Sidebar></:sidebar>
            <:default as |T|><T.Section>A</T.Section></:default>
          </EuiPageTemplate>
        </div>
      </template>
    );
    assert.strictEqual(style(this.element, '[data-page] main').borderRightStyle, 'solid');
    assert.strictEqual(style(this.element, '[data-page] main').borderLeftStyle, 'none');
    const sidebar = el(this.element, '[data-page] .euiPageSidebar').getBoundingClientRect();
    const main = el(this.element, '[data-page] main').getBoundingClientRect();
    assert.true(sidebar.left >= main.right - 0.5, 'sidebar on the right');
  });

  // upstream: _EuiPageEmptyPrompt
  test('T.EmptyPrompt: centered, growing and colored per panelling', async function (assert) {
    await render(
      <template>
        <EuiPageTemplate @offset={{0}} @minHeight={{600}} @grow={{false}} data-page as |T|>
          <T.EmptyPrompt @iconType="warning" @footer="Footer" @layout="horizontal" data-prompt>
            <:title><h2>No spice</h2></:title>
            <:default>Body text</:default>
          </T.EmptyPrompt>
        </EuiPageTemplate>
        <EuiPageTemplate data-props as |T|>
          <T.EmptyPrompt @grow={{false}} @alignment="horizontalCenter" @title="Title" />
        </EuiPageTemplate>
        <EuiPageTemplate as |T|>
          <T.EmptyPrompt @panelled={{true}} data-a>A</T.EmptyPrompt>
          <T.EmptyPrompt @panelled={{true}} @color="accent" data-b>B</T.EmptyPrompt>
          <T.EmptyPrompt @panelled={{false}} data-c>C</T.EmptyPrompt>
          <T.EmptyPrompt @panelled={{false}} @color="warning" data-d>D</T.EmptyPrompt>
          <T.EmptyPrompt @panelled={{true}} @color="plain" data-e>E</T.EmptyPrompt>
          <T.EmptyPrompt @paddingSize="s" data-s>S</T.EmptyPrompt>
        </EuiPageTemplate>
      </template>
    );

    const prompt = el(this.element, '[data-prompt]');
    const section = prompt.closest<HTMLElement>('.euiPageSection')!;
    const content = el(section, '.euiPageSection__content');
    assert.strictEqual(section.parentElement!.tagName, 'MAIN');
    assert.strictEqual(getComputedStyle(section).flexGrow, '1', 'grows');
    assert.strictEqual(getComputedStyle(section).display, 'flex');
    assert.strictEqual(getComputedStyle(section).flexDirection, 'column');
    assert.strictEqual(getComputedStyle(section).justifyContent, 'center', 'vertically centered');
    assert.strictEqual(getComputedStyle(section).alignItems, 'center', 'horizontally centered');
    assert.strictEqual(getComputedStyle(content).marginLeft, getComputedStyle(content).marginRight);
    const main = el(this.element, '[data-page] main').getBoundingClientRect();
    const box = prompt.getBoundingClientRect();
    assert.true(
      Math.abs((box.top + box.bottom) / 2 - (main.top + main.bottom) / 2) < 2,
      'the prompt is vertically centered in the page'
    );
    assert.true(
      Math.abs((box.left + box.right) / 2 - (main.left + main.right) / 2) < 2,
      'and horizontally'
    );
    assert.dom(prompt).hasClass('euiEmptyPrompt');
    assert.dom('[data-prompt] .euiEmptyPrompt__icon').exists();
    assert.dom('[data-prompt] h2').hasText('No spice');
    assert.dom('[data-prompt] .euiTitle, [data-prompt] h2.euiTitle').exists('title in an EuiTitle');
    assert.dom('[data-prompt] .euiText').hasText('Body text', 'block is the body');
    assert.dom('[data-prompt] .euiEmptyPrompt__footer').hasText('Footer');
    assert.strictEqual(px(getComputedStyle(content).paddingTop), PADDING.l, 'section padding l');

    const props = el(this.element, '[data-props] .euiPageSection');
    assert.strictEqual(getComputedStyle(props).flexGrow, '0', '@grow');
    assert.strictEqual(getComputedStyle(props).alignItems, 'center', 'horizontalCenter');
    assert.strictEqual(getComputedStyle(props).justifyContent, 'normal', 'horizontalCenter: not vertically centered');
    assert.dom('[data-props] .euiText').doesNotExist('no body');

    const plain = rgb(light.colors.backgroundBasePlain);
    const pair = (name: string) => {
      const p = el(this.element, `[data-${name}]`);
      return [
        getComputedStyle(p.closest('.euiPageSection')!).backgroundColor,
        getComputedStyle(p).backgroundColor
      ];
    };
    assert.deepEqual(pair('a'), [plain, rgb(light.colors.backgroundBaseSubdued)], 'panelled: subdued prompt');
    assert.deepEqual(pair('b'), [plain, rgb(light.colors.backgroundBaseAccent)], 'panelled + color: inherits');
    assert.deepEqual(pair('c'), [TRANSPARENT, plain], 'not panelled: plain prompt');
    assert.deepEqual(pair('d'), [TRANSPARENT, rgb(light.colors.backgroundBaseWarning)], 'not panelled + color');
    assert.deepEqual(pair('e'), [TRANSPARENT, plain], 'panelled + plain: plain prompt');
    assert.strictEqual(
      px(getComputedStyle(el(this.element, '[data-s]').closest('.euiPageSection__content')!).paddingTop),
      PADDING.s,
      'paddingSize'
    );
  });

  test('EuiEmptyPrompt: title, body and actions blocks', async function (assert) {
    await render(
      <template>
        <EuiEmptyPrompt data-blocks>
          <:title><h2>Title</h2></:title>
          <:body><p>Body</p></:body>
          <:actions as |Item|>
            <Item><EuiButton>One</EuiButton></Item>
            <Item><EuiButton>Two</EuiButton></Item>
          </:actions>
        </EuiEmptyPrompt>
        <EuiEmptyPrompt @title="Only a title" data-title />
      </template>
    );
    assert.dom('[data-blocks] h2').hasText('Title');
    assert.dom('[data-blocks] .euiText p').hasText('Body');
    assert.dom('[data-blocks] .euiEmptyPrompt__actions > .euiFlexItem').exists({ count: 2 });
    assert.dom('[data-blocks] .euiBorealisSpacer').exists({ count: 2 }, 'spacers between title, body and actions');
    assert.dom('[data-title] .euiBorealisSpacer').doesNotExist();
    assert.dom('[data-title] .euiEmptyPrompt__actions').doesNotExist();
  });

  test('T.BottomBar: sticky at the end of the main content', async function (assert) {
    await render(
      <template>
        <EuiPageTemplate @offset={{0}} @grow={{false}} data-page>
          <:sidebar as |T|><T.Sidebar>Nav</T.Sidebar></:sidebar>
          <:default as |T|>
            <T.Section>A</T.Section>
            <T.BottomBar @paddingSize="s" @landmarkHeading="Page actions">Bar</T.BottomBar>
          </:default>
        </EuiPageTemplate>
      </template>
    );
    const bar = el(this.element, '[data-page] .euiBottomBar');
    assert.strictEqual(bar.parentElement!.tagName, 'MAIN', 'inside main');
    assert.strictEqual(bar.parentElement!.lastElementChild, bar, 'last');
    assert.dom(bar).hasClass('euiBottomBar--sticky');
    assert.dom(bar).hasAttribute('aria-label', 'Page actions');
    const computed = getComputedStyle(bar);
    assert.strictEqual(computed.position, 'sticky');
    assert.strictEqual(computed.overflow, 'hidden');
    assert.strictEqual(computed.flexShrink, '0');
    assert.strictEqual(px(computed.paddingTop), 0, 'bar padding none');
    assert.strictEqual(px(style(bar, '.euiPageSection').paddingLeft), PADDING.s, 'content padding');
    assert.strictEqual(computed.backgroundColor, rgb(dark.components.bottomBarBackground), 'dark bar');
    const sidebar = el(this.element, '[data-page] .euiPageSidebar').getBoundingClientRect();
    assert.true(bar.getBoundingClientRect().left >= sidebar.right - 0.5, 'never over the sidebar');
  });

  test('light and dark: the nearest provider colors the panelled content', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider @colorMode="dark">
          <EuiPageTemplate @panelled={{true}} data-dark as |T|>
            <T.Section>Dark</T.Section>
          </EuiPageTemplate>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiPageTemplate @panelled={{true}} data-light as |T|>
            <T.Section>Light</T.Section>
          </EuiPageTemplate>
        </EuiEmotionProvider>
      </template>
    );
    assert.strictEqual(style(this.element, '[data-dark] main').backgroundColor, rgb(dark.colors.backgroundBasePlain));
    assert.strictEqual(style(this.element, '[data-dark] .euiPageSection').backgroundColor, rgb(dark.colors.backgroundBasePlain));
    assert.strictEqual(style(this.element, '[data-light] main').backgroundColor, rgb(light.colors.backgroundBasePlain));
    assert.notStrictEqual(rgb(dark.colors.backgroundBasePlain), rgb(light.colors.backgroundBasePlain));
  });

  test('composable args alone switch to the composable layout', async function (assert) {
    await render(
      <template>
        <EuiPageTemplate @panelled={{true}} data-page>
          <EuiPageSection>Raw</EuiPageSection>
        </EuiPageTemplate>
      </template>
    );
    assert.dom('[data-page] > main > .euiPageSection').hasText('Raw');
    assert.dom('[data-page] .euiPage').doesNotExist('not the legacy EuiPage layout');
    assert.strictEqual(legacyDeprecations().length, 0, 'no legacy deprecation');
  });

  test('T.Sidebar in the default block asserts', function (assert) {
    // Constructed directly: a render error would leave the renderer broken.
    assert.throws(
      () => new EuiPageTemplateSidebar(this.owner, {}),
      /<:sidebar as \|T\|>/,
      'points to the sidebar block'
    );
  });

  test('the legacy API is deprecated but keeps working; the composable API is not', async function (assert) {
    await render(
      <template>
        <EuiPageTemplate as |T|><T.Section>New</T.Section></EuiPageTemplate>
      </template>
    );
    assert.strictEqual(legacyDeprecations().length, 0);

    await render(
      <template>
        <EuiPageTemplate @template="empty" data-legacy>
          <:default>Old</:default>
        </EuiPageTemplate>
      </template>
    );
    assert.dom('[data-legacy].euiPage').exists('legacy layout');
    const [deprecation] = legacyDeprecations();
    assert.strictEqual(legacyDeprecations().length, 1, 'once');
    assert.deepEqual(
      { for: deprecation?.options.for, since: deprecation?.options.since, until: deprecation?.options.until },
      { for: '@ember-eui/core', since: { available: '15.0.0', enabled: '15.0.0' }, until: '16.0.0' }
    );
    assert.true(deprecation!.message.includes('composable API'));
  });
});
