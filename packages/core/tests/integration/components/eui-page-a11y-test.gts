import { tracked } from '@glimmer/tracking';
import { click, render, settled, waitUntil } from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import EuiBanner from '#src/components/eui-banner.gts';
import EuiCallOut from '#src/components/eui-call-out.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiLiveAnnouncer from '#src/components/eui-live-announcer.gts';
import EuiPage from '#src/components/eui-page.gts';
import EuiPageSection from '#src/components/eui-page-section.gts';
import EuiPageSideBar from '#src/components/eui-page-side-bar.gts';
import EuiPageSidebar from '#src/components/eui-page-sidebar.gts';
import EuiScreenReaderLive from '#src/components/eui-screen-reader-live.gts';
import EuiTitle from '#src/components/eui-title.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type {
  EuiPageBreakpoint,
  EuiPagePaddingSize
} from '#src/utils/eui/page-layout.ts';
import type { EuiCss } from '#src/utils/eui/styles.ts';
import type {
  EuiPageSectionAlignment,
  EuiPageSectionColor
} from '#src/components/eui-page-section.gts';
import type { EuiBannerSize } from '#src/components/eui-banner.gts';

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;
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
const COLORS: EuiPageSectionColor[] = [
  'plain',
  'subdued',
  'highlighted',
  'accent',
  'accentSecondary',
  'primary',
  'success',
  'warning',
  'danger',
  'neutral',
  'risk'
];
const ALL_BREAKPOINTS: EuiPageBreakpoint[] = ['xs', 's', 'm', 'l', 'xl'];

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

function token(theme: typeof light, name: string) {
  return (theme.colors as unknown as Record<string, string>)[name]!;
}

/** `subdued` -> `backgroundBaseSubdued` (upstream `getTokenName`). */
function backgroundToken(theme: typeof light, color: string) {
  return rgb(
    token(theme, `backgroundBase${color[0]!.toUpperCase()}${color.slice(1)}`)
  );
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
    rect: (selector: string) => el(doc, selector).getBoundingClientRect(),
    style: (selector: string) => win.getComputedStyle(el(doc, selector)),
    remove: () => iframe.remove()
  };
}

function wait(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/** Text of a live region, whitespace-normalized. */
function text(element: Element) {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim();
}

module('Integration | Component | Borealis page sections, banner and live regions', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiPageSection: padding split, default padding, tag, grow and colors', async function (assert) {
    await render(
      <template>
        {{#each SIZES as |size|}}
          <EuiPageSection @paddingSize={{size}} data-padding={{size}}>
            <span>{{size}}</span>
          </EuiPageSection>
        {{/each}}
        <EuiPageSection data-default>x</EuiPageSection>
        <EuiPageSection @component="main" data-main>x</EuiPageSection>
        <div style="display: flex; flex-direction: column; height: 400px" data-column>
          <EuiPageSection data-fixed>fixed</EuiPageSection>
          <EuiPageSection @grow={{true}} data-grow>grows</EuiPageSection>
        </div>
        {{#each COLORS as |color|}}
          <EuiPageSection @color={{color}} data-color={{color}}>{{color}}</EuiPageSection>
        {{/each}}
      </template>
    );

    for (const size of SIZES) {
      const section = style(this.element, `[data-padding="${size}"]`);
      const content = style(
        this.element,
        `[data-padding="${size}"] > .euiPageSection__content`
      );
      const value = `${PADDING[size]}px`;
      assert.deepEqual(
        [section.paddingLeft, section.paddingRight, section.paddingTop, section.paddingBottom],
        [value, value, '0px', '0px'],
        `${size}: inline padding on the section`
      );
      assert.deepEqual(
        [content.paddingLeft, content.paddingRight, content.paddingTop, content.paddingBottom],
        ['0px', '0px', value, value],
        `${size}: block padding on the content`
      );
    }

    assert
      .dom('[data-default]')
      .hasTagName('section')
      .hasClass('euiPageSection')
      .hasStyle({
        display: 'flex',
        flexDirection: 'column',
        minWidth: '0px',
        paddingLeft: `${PADDING.l}px`,
        backgroundColor: 'rgba(0, 0, 0, 0)',
        boxSizing: 'border-box',
        borderBottomStyle: 'none'
      });
    assert
      .dom('[data-default] > .euiPageSection__content')
      .hasStyle({ paddingTop: `${PADDING.l}px`, boxSizing: 'border-box' });
    close(
      assert,
      box(this.element, '[data-default] > .euiPageSection__content').width,
      box(this.element, '[data-default]').width - 2 * PADDING.l,
      'content fills the section'
    );
    assert.dom('[data-main]').hasTagName('main');

    assert.dom('[data-fixed]').hasStyle({ flexGrow: '0' });
    assert.dom('[data-grow]').hasStyle({ flexGrow: '1' });
    close(
      assert,
      box(this.element, '[data-grow]').bottom,
      box(this.element, '[data-column]').bottom,
      'grow fills the flex column'
    );

    for (const color of COLORS) {
      assert.strictEqual(
        style(this.element, `[data-color="${color}"]`).backgroundColor,
        backgroundToken(light, color),
        `${color} background is the backgroundBase token`
      );
    }
  });

  test('EuiPageSection: bottom borders, restricted width, alignment, contentProps and @css', async function (assert) {
    const contentProps = {
      className: 'extraContent',
      css: { color: 'rgb(1, 2, 3)' },
      style: { outline: '1px solid rgb(4, 5, 6)' },
      'aria-label': 'Section content',
      'data-test-subj': 'sectionContent'
    };
    const sectionCss: EuiCss = { backgroundColor: 'rgb(7, 8, 9)' };
    const alignments: EuiPageSectionAlignment[] = ['top', 'center', 'horizontalCenter'];

    await render(
      <template>
        <div style="width: 1500px">
          <EuiPageSection @bottomBorder={{true}} data-border>x</EuiPageSection>
          <EuiPageSection @bottomBorder="extended" data-extended>x</EuiPageSection>
          <EuiPageSection @restrictWidth={{true}} data-default-width>x</EuiPageSection>
          <EuiPageSection @restrictWidth={{600}} data-number-width>x</EuiPageSection>
          <EuiPageSection @restrictWidth="40rem" data-string-width>x</EuiPageSection>
        </div>
        <div style="display: flex; width: 1000px; height: 300px" data-row>
          {{#each alignments as |alignment|}}
            <EuiPageSection @alignment={{alignment}} data-alignment={{alignment}}>
              <span style="display: inline-block; width: 100px; height: 20px">{{alignment}}</span>
            </EuiPageSection>
          {{/each}}
        </div>
        <div style="width: 1000px; height: 300px; display: flex">
          <EuiPageSection @alignment="center" @grow={{true}} data-centered>
            <span style="display: inline-block; width: 100px; height: 20px">x</span>
          </EuiPageSection>
        </div>
        <EuiPageSection
          @contentProps={{contentProps}}
          @css={{sectionCss}}
          @color="subdued"
          data-props
        >x</EuiPageSection>
      </template>
    );

    const thin = borderColor(light.border.thin);
    assert.dom('[data-border]').hasStyle({ borderBottomStyle: 'none' });
    assert.dom('[data-border] > .euiPageSection__content').hasStyle({
      borderBottomStyle: 'solid',
      borderBottomWidth: '1px',
      borderBottomColor: thin
    });
    assert.dom('[data-extended]').hasStyle({
      borderBottomStyle: 'solid',
      borderBottomColor: thin
    });
    assert
      .dom('[data-extended] > .euiPageSection__content')
      .hasStyle({ borderBottomStyle: 'none' });
    close(
      assert,
      box(this.element, '[data-extended]').width,
      1500,
      'extended border spans the section (padding included)'
    );

    for (const [selector, width] of [
      ['[data-default-width]', 1200],
      ['[data-number-width]', 600],
      ['[data-string-width]', 40 * px(getComputedStyle(document.documentElement).fontSize)]
    ] as const) {
      const content = box(this.element, `${selector} > .euiPageSection__content`);
      const section = box(this.element, selector);
      close(assert, content.width, width, `${selector} max width`);
      close(
        assert,
        content.left - section.left,
        section.right - content.right,
        `${selector} centered`
      );
    }

    // Alignment, side by side in a 1000px row.
    assert.dom('[data-alignment="top"]').hasStyle({ alignItems: 'normal' });
    assert
      .dom('[data-alignment="center"]')
      .hasStyle({ alignItems: 'center', justifyContent: 'center' });
    assert
      .dom('[data-alignment="horizontalCenter"]')
      .hasStyle({ alignItems: 'center', justifyContent: 'normal' });
    assert
      .dom('[data-alignment="center"] > .euiPageSection__content')
      .hasStyle({ marginLeft: '0px' });

    // Centered on both axes inside a growing section.
    const centered = box(this.element, '[data-centered]');
    const content = box(this.element, '[data-centered] > .euiPageSection__content');
    close(assert, content.width, 100, 'centered content shrinks to fit');
    close(
      assert,
      content.left - centered.left,
      centered.right - content.right,
      'horizontally centered'
    );
    close(
      assert,
      content.top - centered.top,
      centered.bottom - content.bottom,
      'vertically centered'
    );

    assert
      .dom('[data-props] > .euiPageSection__content')
      .hasClass('extraContent')
      .hasAttribute('aria-label', 'Section content')
      .hasAttribute('data-test-subj', 'sectionContent')
      .hasStyle({ color: 'rgb(1, 2, 3)', outlineColor: 'rgb(4, 5, 6)' });
    assert
      .dom('[data-props]')
      .hasStyle({ backgroundColor: 'rgb(7, 8, 9)' }, '@css is composed after @color');
  });

  test('EuiPageSection and EuiPageSidebar: reactive args keep the elements', async function (assert) {
    class State {
      @tracked paddingSize: EuiPagePaddingSize = 's';
      @tracked color: EuiPageSectionColor = 'plain';
      @tracked restrictWidth: boolean | number = false;
      @tracked bottomBorder: boolean | 'extended' = false;
      @tracked minWidth: number | string = 248;
      @tracked hasEmbellish = false;
      @tracked sidebarPadding: EuiPagePaddingSize = 'none';
    }
    const state = new State();

    await render(
      <template>
        <div style="width: 1500px">
          <EuiPageSection
            @paddingSize={{state.paddingSize}}
            @color={{state.color}}
            @restrictWidth={{state.restrictWidth}}
            @bottomBorder={{state.bottomBorder}}
            data-section
          >x</EuiPageSection>
          <div style="display: flex">
            <EuiPageSidebar
              @minWidth={{state.minWidth}}
              @hasEmbellish={{state.hasEmbellish}}
              @paddingSize={{state.sidebarPadding}}
              data-sidebar
            >side</EuiPageSidebar>
          </div>
        </div>
      </template>
    );

    const section = el(this.element, '[data-section]');
    const content = el(section, '.euiPageSection__content');
    const sidebar = el(this.element, '[data-sidebar]');
    assert.dom(section).hasStyle({
      paddingLeft: `${PADDING.s}px`,
      backgroundColor: backgroundToken(light, 'plain')
    });
    assert.dom(sidebar).hasStyle({ minWidth: '248px', backgroundImage: 'none' });

    state.paddingSize = 'xl';
    state.color = 'primary';
    state.restrictWidth = 700;
    state.bottomBorder = true;
    state.minWidth = '20rem';
    state.hasEmbellish = true;
    state.sidebarPadding = 'm';
    await settled();

    assert.strictEqual(el(this.element, '[data-section]'), section, 'same section');
    assert.strictEqual(el(section, '.euiPageSection__content'), content, 'same content');
    assert.strictEqual(el(this.element, '[data-sidebar]'), sidebar, 'same sidebar');
    assert.dom(section).hasStyle({
      paddingLeft: `${PADDING.xl}px`,
      backgroundColor: backgroundToken(light, 'primary')
    });
    assert.dom(content).hasStyle({
      paddingTop: `${PADDING.xl}px`,
      borderBottomStyle: 'solid',
      maxWidth: '700px'
    });
    assert.dom(sidebar).hasStyle({ padding: `${PADDING.m}px` });
    close(
      assert,
      px(getComputedStyle(sidebar).minWidth),
      20 * px(getComputedStyle(document.documentElement).fontSize),
      'rem min width'
    );
    assert.true(
      getComputedStyle(sidebar).backgroundImage.includes('linear-gradient'),
      'embellish gradient'
    );

    state.restrictWidth = false;
    state.bottomBorder = 'extended';
    await settled();
    assert.dom(content).hasStyle({ borderBottomStyle: 'none' });
    assert.dom(section).hasStyle({ borderBottomStyle: 'solid' });
    close(assert, box(this.element, '[data-section] > .euiPageSection__content').width, 1500 - 2 * PADDING.xl, 'unrestricted again');
  });

  test('EuiPageSidebar: sticky offsets, responsive collapse, @css and parity with EuiPageSideBar', async function (assert) {
    class State {
      @tracked sticky: boolean | { offset: number } = true;
    }
    const state = new State();
    const sidebarCss: EuiCss = { color: 'rgb(9, 8, 7)' };

    await render(
      <template>
        <div style="--euiFixedHeadersOffset: 20px; height: 300px; overflow: auto" data-scroller>
          <div style="height: 120px">spacer</div>
          <div style="display: flex; align-items: flex-start">
            <EuiPageSidebar @sticky={{state.sticky}} data-sticky>Side</EuiPageSidebar>
            <div style="height: 2000px">long</div>
          </div>
        </div>
        <EuiPageSidebar @sticky={{true}} @responsive={{false}} data-always>x</EuiPageSidebar>
        <EuiPageSidebar @sticky={{true}} @responsive={{ALL_BREAKPOINTS}} data-never>x</EuiPageSidebar>
        <EuiPageSidebar @css={{sidebarCss}} @paddingSize="l" data-css>x</EuiPageSidebar>
        <EuiPageSidebar @sticky={{true}} @paddingSize="m" @hasEmbellish={{true}} data-new>x</EuiPageSidebar>
        <EuiPageSideBar @sticky={{true}} @paddingSize="m" @hasEmbellish={{true}} data-old>x</EuiPageSideBar>
        <EuiPage @direction="row" data-page>
          <EuiPageSidebar @sticky={{true}} data-in-page>side</EuiPageSidebar>
          <div data-page-body style="flex-grow: 1">body</div>
        </EuiPage>
      </template>
    );

    assert.dom('[data-always]').hasStyle({ position: 'sticky' });
    assert.dom('[data-never]').hasStyle({ position: 'static' });
    assert.dom('[data-css]').hasClass('euiPageSidebar').hasStyle({
      color: 'rgb(9, 8, 7)',
      padding: `${PADDING.l}px`,
      minWidth: '248px',
      boxSizing: 'border-box'
    });

    // The older EuiPageSideBar renders the very same Emotion class.
    const emotion = (selector: string) =>
      Array.from(el(this.element, selector).classList)
        .filter((name) => !name.startsWith('euiPageSide'))
        .join(' ');
    assert.strictEqual(emotion('[data-old]'), emotion('[data-new]'), 'shared class');
    assert.dom('[data-old]').hasClass('euiPageSideBar').doesNotHaveClass('euiPageSidebar');

    const sticky = el(this.element, '[data-sticky]');
    const scroller = el(this.element, '[data-scroller]');
    assert.dom(sticky).hasStyle({ position: 'sticky', top: '20px', overflowY: 'auto' });
    scroller.scrollTop = 600;
    await settled();
    close(assert, box(this.element, '[data-sticky]').top - box(this.element, '[data-scroller]').top, 20, 'sticks below the fixed headers offset', 1);

    state.sticky = { offset: 48 };
    await settled();
    assert.strictEqual(el(this.element, '[data-sticky]'), sticky, 'same element');
    assert.dom(sticky).hasStyle({ top: '48px' });
    close(assert, px(getComputedStyle(sticky).maxHeight), window.innerHeight - 48, 'max height leaves the offset');
    close(assert, box(this.element, '[data-sticky]').top - box(this.element, '[data-scroller]').top, 48, 'sticks at the pixel offset', 1);

    state.sticky = false;
    await settled();
    assert.dom(sticky).hasStyle({ position: 'static', maxHeight: 'none' });

    // Responsive collapse: full width and never sticky below `m`.
    const html = el(this.element, '[data-page]').outerHTML;
    const narrow = inViewport(BREAKPOINT - 1, html);
    const wide = inViewport(BREAKPOINT, html);
    try {
      assert.strictEqual(narrow.style('[data-in-page]').position, 'static', 'not sticky while responding');
      assert.strictEqual(narrow.style('[data-page]').flexDirection, 'column', 'page stacks');
      close(assert, narrow.rect('[data-in-page]').width, BREAKPOINT - 1, 'full width when responding', 1);
      assert.strictEqual(wide.style('[data-in-page]').position, 'sticky');
      assert.strictEqual(wide.style('[data-in-page]').minWidth, '248px', 'min width on desktop');
      assert.true(wide.rect('[data-in-page]').width < BREAKPOINT / 2, 'beside the body on desktop');
    } finally {
      narrow.remove();
      wide.remove();
    }
  });

  test('EuiBanner: structure, colors, sizes, title, text and media', async function (assert) {
    const sizes: EuiBannerSize[] = ['s', 'm'];
    await render(
      <template>
        <div style="width: 700px">
          {{#each sizes as |size|}}
            <EuiBanner
              @title="New dashboards"
              @text="Build them faster."
              @size={{size}}
              data-banner={{size}}
            >
              <:media><svg viewBox="0 0 10 10" data-svg={{size}}></svg></:media>
              <:default><p data-extra={{size}}>Extra content</p></:default>
            </EuiBanner>
          {{/each}}
          <EuiBanner
            @title="Plain"
            @color="plain"
            @headingElement="h3"
            data-test-subj="custom"
            data-plain
          />
          <EuiTitle @size="xs" data-ref-xs>ref</EuiTitle>
          <EuiTitle @size="xxs" data-ref-xxs>ref</EuiTitle>
        </div>
      </template>
    );

    assert
      .dom('[data-banner="m"]')
      .hasClass('euiBanner')
      .hasAttribute('data-size', 'm')
      .hasAttribute('data-color', 'highlighted')
      .hasAttribute('data-test-subj', 'euiBanner')
      .hasStyle({
        position: 'relative',
        backgroundColor: backgroundToken(light, 'highlighted'),
        borderTopStyle: 'solid',
        borderTopColor: borderColor(light.border.thin),
        borderTopLeftRadius: (light.border.radius as unknown as Record<string, string>).panel,
        containerType: 'inline-size'
      });
    assert
      .dom('[data-plain]')
      .hasAttribute('data-test-subj', 'custom', 'data-test-subj is overridable')
      .hasAttribute('data-color', 'plain')
      .hasStyle({ backgroundColor: backgroundToken(light, 'plain') });
    assert.dom('[data-plain] .euiBanner__media').doesNotExist('no media block, no slot');
    assert.dom('[data-plain] [data-test-subj="euiBanner-title"]').hasTagName('h3');
    assert.dom('[data-plain] [data-test-subj="euiBanner-text"]').doesNotExist();
    assert.dom('[data-plain] .euiBanner__actions').doesNotExist();

    const title = el(this.element, '[data-banner="m"] [data-test-subj="euiBanner-title"]');
    assert.dom(title).hasTagName('h2').hasText('New dashboards');
    assert.strictEqual(
      getComputedStyle(title).fontSize,
      style(this.element, '[data-ref-xs]').fontSize,
      'm: title size xs'
    );
    assert.strictEqual(
      style(this.element, '[data-banner="s"] [data-test-subj="euiBanner-title"]').fontSize,
      style(this.element, '[data-ref-xxs]').fontSize,
      's: title size xxs'
    );
    assert
      .dom('[data-banner="m"] [data-test-subj="euiBanner-text"]')
      .hasClass('euiText')
      .hasText('Build them faster.')
      .hasStyle({ color: rgb(light.colors.textSubdued), display: 'block' });

    // Media: a square slot, 5x base (m) / 2x base (s); the svg fills it.
    const base = px(light.size.base);
    assert.dom('[data-banner="m"] .euiBanner__media').hasAttribute('data-test-subj', 'euiBanner-media');
    close(assert, box(this.element, '[data-banner="m"] .euiBanner__media').width, base * 5, 'm media');
    close(assert, box(this.element, '[data-banner="m"] .euiBanner__media').height, base * 5, 'm media square');
    close(assert, box(this.element, '[data-banner="s"] .euiBanner__media').width, base * 2, 's media');
    close(assert, box(this.element, '[data-svg="m"]').width, base * 5, 'svg fills the media');

    // Padding: inline base, block base (m) / m (s).
    assert.dom('[data-banner="m"] .euiBanner__container').hasStyle({
      paddingLeft: light.size.base,
      paddingTop: light.size.base
    });
    assert.dom('[data-banner="s"] .euiBanner__container').hasStyle({ paddingTop: light.size.m });

    // Size s: title and text flow inline, with a middle dot before the text.
    assert.dom('[data-banner="s"] .euiBanner__content').hasStyle({ display: 'block' });
    assert.dom('[data-banner="s"] [data-test-subj="euiBanner-title"]').hasStyle({ display: 'inline' });
    assert.dom('[data-banner="s"] [data-test-subj="euiBanner-text"]').hasStyle({ display: 'inline' });
    assert.strictEqual(
      getComputedStyle(el(this.element, '[data-banner="s"] [data-test-subj="euiBanner-text"]'), '::before').content,
      '"·"'
    );
    assert.dom('[data-banner="s"] [data-extra]').hasStyle({ marginTop: light.size.s });
    assert.dom('[data-banner="m"] .euiBanner__content').hasStyle({ display: 'flex', flexDirection: 'column' });
    assert.dom('[data-banner="m"] [data-extra]').hasStyle({ marginTop: light.size.s });
  });

  test('EuiBanner: container-query layouts, actions, dismiss and RTL', async function (assert) {
    const calls: string[] = [];
    const actionProps = {
      primary: {
        children: 'Try it',
        onClick: () => calls.push('primary'),
        iconType: 'plus'
      },
      secondary: {
        children: 'Learn more',
        onClick: () => calls.push('secondary')
      }
    };
    const onDismiss = () => calls.push('dismiss');
    const dismissButtonProps = { 'data-test-subj': 'closeIt' };

    await render(
      <template>
        <div style="width: 1200px" data-wide>
          <EuiBanner
            @title="Wide"
            @text="Text"
            @actionProps={{actionProps}}
            @onDismiss={{onDismiss}}
          ><:media><svg viewBox="0 0 10 10"></svg></:media></EuiBanner>
        </div>
        <div style="width: 300px" data-narrow>
          <EuiBanner @title="Narrow" @actionProps={{actionProps}} @onDismiss={{onDismiss}}>
            <:media><svg viewBox="0 0 10 10"></svg></:media>
          </EuiBanner>
        </div>
        <div style="width: 700px" dir="rtl" data-rtl>
          <EuiBanner
            @title="RTL"
            @onDismiss={{onDismiss}}
            @dismissButtonProps={{dismissButtonProps}}
          />
        </div>
      </template>
    );

    // Wide (>= 1000px container): one row, actions reversed (primary last).
    assert.dom('[data-wide] .euiBanner__container').hasStyle({ flexDirection: 'row' });
    assert.dom('[data-wide] .euiBanner__body').hasStyle({ flexDirection: 'row' });
    assert
      .dom('[data-wide] .euiBanner__actions')
      .hasAttribute('data-test-subj', 'euiBanner-actions')
      .hasStyle({ flexDirection: 'row-reverse' });
    assert.true(
      box(this.element, '[data-wide] [data-test-subj="euiBanner-primaryAction"]').left >
        box(this.element, '[data-wide] [data-test-subj="euiBanner-secondaryAction"]').left,
      'primary is rightmost'
    );
    assert.dom('[data-wide] .euiBanner__container').hasStyle({
      paddingRight: `${px(light.size.s) * 5}px`
    }, 'room for the dismiss button');

    // Narrow (<= 400px container): stacked, full-width wrapping actions.
    assert.dom('[data-narrow] .euiBanner__container').hasStyle({
      flexDirection: 'column',
      paddingRight: light.size.base
    });
    assert.dom('[data-narrow] .euiBanner__actions').hasStyle({ flexWrap: 'wrap', flexDirection: 'row' });
    const narrowBody = box(this.element, '[data-narrow] .euiBanner__actions');
    close(
      assert,
      box(this.element, '[data-narrow] [data-test-subj="euiBanner-primaryAction"]').width,
      narrowBody.width,
      'full-width primary action'
    );

    // Actions: EuiButton (filled? no: base) and EuiButtonEmpty, size s.
    assert.dom('[data-wide] [data-test-subj="euiBanner-primaryAction"]').hasClass('euiButton').hasText('Try it');
    assert.dom('[data-wide] [data-test-subj="euiBanner-secondaryAction"]').hasClass('euiButtonEmpty').hasText('Learn more');
    await click('[data-wide] [data-test-subj="euiBanner-primaryAction"]');
    await click('[data-wide] [data-test-subj="euiBanner-secondaryAction"]');

    // Dismiss: labelled with the title, absolute at the top end corner.
    const dismiss = '[data-wide] [data-test-subj="euiBanner-dismiss"]';
    assert.dom(dismiss).hasAttribute('aria-label', 'Dismiss "Wide" announcement').hasStyle({
      position: 'absolute',
      top: light.size.s,
      color: rgb(light.colors.textSubdued)
    });
    const banner = box(this.element, '[data-wide] .euiBanner');
    close(assert, banner.right - box(this.element, dismiss).right, px(light.size.s) + 1, 'end corner (LTR right, inside the border)', 1);
    await click(dismiss);
    assert.deepEqual(calls, ['primary', 'secondary', 'dismiss']);

    const rtlDismiss = '[data-rtl] [data-test-subj="closeIt"]';
    assert.dom(rtlDismiss).exists('dismissButtonProps data-test-subj');
    const rtl = box(this.element, '[data-rtl] .euiBanner');
    close(assert, box(this.element, rtlDismiss).left - rtl.left, px(light.size.s) + 1, 'RTL: end corner is the left', 1);
  });

  test('EuiBanner and EuiCallOut: announceOnMount', async function (assert) {
    await render(
      <template>
        <EuiBanner @title="Saved" @text="Your changes are live." @announceOnMount={{true}} data-banner>
          <:default>Undo within 5 minutes.</:default>
        </EuiBanner>
        <EuiBanner @title="Quiet" data-quiet />
        <EuiCallOut @title="Copied" @text="The link is on your clipboard." @announceOnMount={{true}} data-callout>
          Share it.
        </EuiCallOut>
        <EuiCallOut @title="Plain" data-plain-callout>Body</EuiCallOut>
      </template>
    );

    assert.dom('[data-quiet] [aria-live]').doesNotExist('no live region unless opted in');
    assert.dom('[data-plain-callout] [aria-live]').doesNotExist('callout DOM unchanged by default');
    assert.dom('[data-plain-callout] [hidden]').doesNotExist();

    await waitUntil(() => text(el(this.element, '[data-banner] [role="status"]')) !== '');
    assert.strictEqual(
      text(el(this.element, '[data-banner] [role="status"]')),
      'Saved, Your changes are live., Undo within 5 minutes.',
      'banner: title, text and content'
    );
    assert.dom('[data-banner] [role="status"]').hasAttribute('aria-live', 'polite');
    await waitUntil(() => text(el(this.element, '[data-callout] [role="status"]')) !== '');
    assert.strictEqual(
      text(el(this.element, '[data-callout] [role="status"]')),
      'Copied, The link is on your clipboard., Share it.',
      'callout: title, text and body'
    );
  });

  test('EuiLiveAnnouncer: defaults, mount delay, clearAfterMs and re-announcing', async function (assert) {
    class State {
      @tracked message = 'Saved';
      @tracked isActive = true;
      @tracked clearAfterMs: number | false = 300;
    }
    const state = new State();

    await render(
      <template>
        <EuiLiveAnnouncer
          @clearAfterMs={{state.clearAfterMs}}
          @isActive={{state.isActive}}
          data-announcer
        >{{state.message}}</EuiLiveAnnouncer>
        <EuiLiveAnnouncer @role="alert" @ariaLive="assertive" @clearAfterMs={{false}} data-alert>
          <strong>Failed</strong> to save
        </EuiLiveAnnouncer>
      </template>
    );

    const region = el(this.element, '[data-announcer]');
    assert.dom(region).hasAttribute('role', 'status').hasAttribute('aria-live', 'polite').hasAttribute('aria-atomic', 'true');
    assert.dom(region).hasClass('euiScreenReaderOnly').hasStyle({ position: 'absolute', clipPath: 'inset(50%)' });
    assert.dom('[data-alert]').hasAttribute('role', 'alert').hasAttribute('aria-live', 'assertive');
    assert.dom(region.nextElementSibling as HTMLElement).hasAttribute('hidden', '', 'the block renders in a hidden source');

    const inserted = performance.now();
    await waitUntil(() => text(region) === 'Saved', { timeout: 1000 });
    assert.true(performance.now() - inserted >= 40, 'content appears after the mount delay');
    await waitUntil(() => text(region) === '', { timeout: 1500 });
    assert.true(performance.now() - inserted >= 280, 'cleared after clearAfterMs');

    // Markup in the block is announced as text; clearAfterMs=false keeps it.
    await wait(400);
    assert.strictEqual(text(el(this.element, '[data-alert]')), 'Failed to save', 'kept without clearAfterMs');

    // A new message is announced (and cleared) again, in the same element.
    state.message = 'Saved again';
    await settled();
    await waitUntil(() => text(region) === 'Saved again', { timeout: 500 });
    assert.strictEqual(el(this.element, '[data-announcer]'), region, 'same region');
    await waitUntil(() => text(region) === '', { timeout: 1500 });

    state.clearAfterMs = false;
    state.message = 'Stays';
    await settled();
    await waitUntil(() => text(region) === 'Stays', { timeout: 500 });
    await wait(400);
    assert.strictEqual(text(region), 'Stays', 'not cleared with clearAfterMs=false');

    state.isActive = false;
    await settled();
    assert.dom(region).hasAttribute('aria-live', 'off', 'inactive regions are not live');
  });

  test('EuiScreenReaderLive: alternating regions, isActive, focus and roles', async function (assert) {
    class State {
      @tracked message = '3 results';
      @tracked isActive = true;
    }
    const state = new State();

    await render(
      <template>
        <button type="button" data-elsewhere>elsewhere</button>
        <EuiScreenReaderLive @isActive={{state.isActive}} data-live>{{state.message}}</EuiScreenReaderLive>
        <EuiScreenReaderLive @role="alert" @ariaLive="assertive" data-alert>Error</EuiScreenReaderLive>
      </template>
    );
    await settled();

    const live = el(this.element, '[data-live]');
    const [first, second] = Array.from(live.querySelectorAll<HTMLElement>('[role]'));
    assert.dom(live).hasClass('euiScreenReaderOnly').doesNotHaveAttribute('tabindex');
    assert.dom(first!).hasAttribute('role', 'status').hasAttribute('aria-atomic', 'true');
    // Mounted: the first region holds the text and is live.
    assert.strictEqual(text(first!), '3 results');
    assert.dom(first!).hasAttribute('aria-live', 'polite').doesNotHaveAttribute('aria-hidden');
    assert.strictEqual(text(second!), '');
    assert.dom(second!).hasAttribute('aria-live', 'off').hasAttribute('aria-hidden', 'true');
    assert.dom(live.querySelector('[hidden]') as HTMLElement).exists('hidden source');

    // A change moves the text to the other region.
    state.message = '5 results';
    await settled();
    await waitUntil(() => text(second!) === '5 results');
    assert.strictEqual(text(first!), '', 'first region emptied');
    assert.dom(first!).hasAttribute('aria-live', 'off').hasAttribute('aria-hidden', 'true');
    assert.dom(second!).hasAttribute('aria-live', 'polite').doesNotHaveAttribute('aria-hidden');

    // ...and back on the next change, even to a previous message.
    state.message = '3 results';
    await settled();
    await waitUntil(() => text(first!) === '3 results');
    assert.strictEqual(text(second!), '');
    assert.strictEqual(el(this.element, '[data-live]'), live, 'same element');

    state.isActive = false;
    await settled();
    assert.strictEqual(text(first!) + text(second!), '', 'inactive: nothing to read');

    const alert = el(this.element, '[data-alert]');
    const alertRegions = alert.querySelectorAll('[role="alert"]');
    assert.strictEqual(alertRegions.length, 2);
    assert.dom(alertRegions[0] as HTMLElement).hasAttribute('aria-live', 'assertive');
  });

  test('EuiScreenReaderLive: focusRegionOnTextChange', async function (assert) {
    class State {
      @tracked message = 'Page 1';
    }
    const state = new State();

    await render(
      <template>
        <button type="button" data-elsewhere>elsewhere</button>
        <EuiScreenReaderLive @focusRegionOnTextChange={{true}} data-live>{{state.message}}</EuiScreenReaderLive>
      </template>
    );
    await settled();

    const live = el(this.element, '[data-live]');
    assert.dom(live).hasAttribute('tabindex', '-1');
    assert.strictEqual(document.activeElement, live, 'focused on insert');
    for (const region of live.querySelectorAll('[role]'))
      assert.dom(region as HTMLElement).hasAttribute('aria-live', 'off', 'focus reads it, not the live region');

    el(this.element, '[data-elsewhere]').focus();
    state.message = 'Page 2';
    await settled();
    await waitUntil(() => document.activeElement === live);
    assert.strictEqual(text(live.querySelectorAll('[role]')[1]!), 'Page 2');
    assert.strictEqual(document.activeElement, live, 'focused again on change');
  });

  test('themes: nearest provider and sibling isolation', async function (assert) {
    const modes: EuiColorMode[] = ['light', 'dark'];
    await render(
      <template>
        {{#each modes as |mode|}}
          <EuiEmotionProvider @colorMode={{mode}} @globalStyles={{false}}>
            <EuiPageSection @color="subdued" @bottomBorder={{true}} data-section={{mode}}>x</EuiPageSection>
            <EuiBanner @title="Theme" data-banner={{mode}} />
            <EuiPageSidebar @hasEmbellish={{true}} data-sidebar={{mode}}>x</EuiPageSidebar>
          </EuiEmotionProvider>
        {{/each}}
      </template>
    );

    for (const [mode, theme] of [
      ['light', light],
      ['dark', dark]
    ] as const) {
      assert.strictEqual(
        style(this.element, `[data-section="${mode}"]`).backgroundColor,
        backgroundToken(theme, 'subdued'),
        `${mode} section background`
      );
      assert.strictEqual(
        style(this.element, `[data-section="${mode}"] > .euiPageSection__content`).borderBottomColor,
        borderColor(theme.border.thin),
        `${mode} border`
      );
      assert.strictEqual(
        style(this.element, `[data-banner="${mode}"]`).backgroundColor,
        backgroundToken(theme, 'highlighted'),
        `${mode} banner background`
      );
      assert.strictEqual(
        style(this.element, `[data-banner="${mode}"] [data-test-subj="euiBanner-title"]`).color,
        rgb(theme.colors.textHeading),
        `${mode} banner title`
      );
    }
    assert.notStrictEqual(
      style(this.element, '[data-section="light"]').backgroundColor,
      style(this.element, '[data-section="dark"]').backgroundColor,
      'siblings differ'
    );
    assert.notStrictEqual(
      style(this.element, '[data-sidebar="light"]').backgroundImage,
      style(this.element, '[data-sidebar="dark"]').backgroundImage,
      'embellish follows the mode'
    );
  });

  test('RTL: logical padding and centering', async function (assert) {
    await render(
      <template>
        <div dir="rtl" style="width: 1500px">
          <EuiPageSection @restrictWidth={{600}} data-rtl-section>x</EuiPageSection>
          <div style="display: flex">
            <EuiPageSidebar @paddingSize="m" data-rtl-sidebar>s</EuiPageSidebar>
            <div style="flex-grow: 1" data-rtl-body>b</div>
          </div>
        </div>
      </template>
    );

    const section = box(this.element, '[data-rtl-section]');
    const content = box(this.element, '[data-rtl-section] > .euiPageSection__content');
    close(assert, content.left - section.left, section.right - content.right, 'centered in RTL');
    assert.true(
      box(this.element, '[data-rtl-sidebar]').left > box(this.element, '[data-rtl-body]').left,
      'the sidebar starts on the right in RTL'
    );
  });
});
