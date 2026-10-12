import { tracked } from '@glimmer/tracking';
import { array } from '@ember/helper';
import { on } from '@ember/modifier';
import {
  click,
  clearRender,
  render,
  rerender,
  settled,
  triggerEvent
} from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import EuiCollapsibleNav from '#src/components/eui-collapsible-nav.gts';
import EuiCollapsibleNavGroup from '#src/components/eui-collapsible-nav-group.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiHeader from '#src/components/eui-header.gts';
import EuiHeaderAlert from '#src/components/eui-header-alert.gts';
import EuiHeaderBreadcrumbs from '#src/components/eui-header-breadcrumbs.gts';
import EuiHeaderLink from '#src/components/eui-header-link.gts';
import EuiHeaderLinks from '#src/components/eui-header-links.gts';
import EuiHeaderLogo from '#src/components/eui-header-logo.gts';
import EuiHeaderSection from '#src/components/eui-header-section.gts';
import EuiHeaderSectionItem from '#src/components/eui-header-section-item.gts';
import EuiHeaderSectionItemButton from '#src/components/eui-header-section-item-button.gts';
import EuiIcon from '#src/components/eui-icon.gts';
import EuiLink from '#src/components/eui-link.gts';
import { makeHighContrastColor } from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiHeaderLinksGutterSize } from '#src/components/eui-header-links.gts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type {
  EuiBorealisHighContrastMode,
  EuiBorealisOverrides
} from '#src/utils/eui/theme.ts';

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;

function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

function el(selector: string, root: ParentNode = document): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function css(selector: string, root: ParentNode = document) {
  return getComputedStyle(el(selector, root));
}

/** ember-qunit may scale #ember-testing; measure in layout pixels. */
function box(selector: string) {
  const element = el(selector);
  const container = element.closest<HTMLElement>('#ember-testing');
  const factor =
    container && container.offsetWidth
      ? container.getBoundingClientRect().width / container.offsetWidth
      : 1;
  const rect = element.getBoundingClientRect();
  return {
    left: rect.left / factor,
    right: rect.right / factor,
    width: rect.width / factor,
    height: rect.height / factor
  };
}

/** Border color of a `1px solid <color>` token. */
function borderColor(border: string) {
  return rgb(border.replace(/^\S+\s+\S+\s+/, ''));
}

/**
 * Copies the rendered markup and every stylesheet rule (including Emotion's
 * inserted rules) into an iframe of the given width, so media queries are
 * evaluated against a real narrow viewport (see eui-flex-family-test).
 */
function inViewport(width: number, html: string) {
  const iframe = document.createElement('iframe');
  iframe.style.cssText = `position:fixed;top:0;left:0;width:${width}px;height:600px;border:0;visibility:hidden`;
  document.body.appendChild(iframe);
  const sheets = Array.from(document.styleSheets)
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
    `<!doctype html><html><head><style>${sheets}</style></head><body style="margin:0">${html}</body></html>`
  );
  doc.close();
  const win = iframe.contentWindow!;
  return {
    style: (selector: string) => win.getComputedStyle(el(selector, doc)),
    remove: () => iframe.remove()
  };
}

module('Integration | Component | Borealis header family', function (hooks) {
  setupRenderingTest(hooks);

  hooks.afterEach(function () {
    // A failing fixed-header test must not leak into the next one.
    document.body.classList.remove('euiBody--headerIsFixed');
  });

  test('EuiHeader: upstream bar, static position, default theme and no legacy classes', async function (assert) {
    await render(
      <template>
        <EuiHeader data-test-header aria-label="Main">
          <EuiHeaderSection><EuiHeaderSectionItem>A</EuiHeaderSectionItem></EuiHeaderSection>
        </EuiHeader>
        <EuiHeader data-test-second>B</EuiHeader>
      </template>
    );

    const header = css('[data-test-header]');
    assert.dom('[data-test-header]').hasClass('euiHeader').hasAttribute('aria-label', 'Main');
    assert.strictEqual(header.display, 'flex');
    assert.strictEqual(header.justifyContent, 'space-between');
    assert.strictEqual(header.boxSizing, 'border-box');
    assert.strictEqual(header.height, light.size.xxxl, 'height is size.xxxl (48px)');
    assert.strictEqual(header.paddingLeft, light.size.s);
    assert.strictEqual(header.paddingRight, light.size.s);
    assert.strictEqual(header.borderBottomWidth, '1px');
    assert.strictEqual(header.borderBottomStyle, 'solid');
    assert.strictEqual(header.borderBottomColor, borderColor(light.border.thin));
    assert.notStrictEqual(header.boxShadow, 'none', 'upstream xSmall shadow');
    assert.strictEqual(header.position, 'relative');
    assert.strictEqual(header.zIndex, String(Number(light.levels.header) - 1));
    assert.strictEqual(header.backgroundColor, rgb(light.components.headerBackground));
    assert.dom('[data-test-header]').doesNotHaveAttribute('data-fixed-header');
    assert.dom('[data-test-header]').doesNotHaveAttribute('style');
    for (const legacy of ['euiHeader--default', 'euiHeader--static', 'euiHeader--dark', 'euiHeader--fixed']) {
      assert.dom(`.${legacy}`).doesNotExist(`no legacy ${legacy}`);
    }
    assert.false(document.body.classList.contains('euiBody--headerIsFixed'));
    // Upstream clips the shadow of a header stacked under another one.
    assert.notStrictEqual(css('[data-test-second]').clipPath, 'none');
    assert.strictEqual(header.clipPath, 'none');
  });

  test('EuiHeader @theme="dark": upstream pseudo dark theme in light and dark providers', async function (assert) {
    await render(
      <template>
        {{#each (array "light" "dark") as |mode|}}
          <EuiEmotionProvider @colorMode={{mode}}>
            <EuiHeader @theme="dark" data-test-dark={{mode}}>
              <EuiHeaderSection>
                <EuiHeaderSectionItem>
                  <EuiHeaderLogo @href="#" data-test-logo={{mode}}>Brand</EuiHeaderLogo>
                </EuiHeaderSectionItem>
              </EuiHeaderSection>
              <EuiHeaderSection @side="right">
                <EuiHeaderSectionItem>
                  <EuiHeaderLinks @popoverBreakpoints="none">
                    <EuiHeaderLink data-test-link={{mode}}>Docs</EuiHeaderLink>
                    <EuiHeaderLink @isActive={{true}} data-test-active={{mode}}>Active</EuiHeaderLink>
                  </EuiHeaderLinks>
                </EuiHeaderSectionItem>
                <EuiHeaderSectionItem>
                  <EuiHeaderSectionItemButton @notification={{4}} aria-label="News" data-test-button={{mode}}>N</EuiHeaderSectionItemButton>
                </EuiHeaderSectionItem>
                <EuiHeaderSectionItem>
                  <EuiHeaderSectionItemButton @notification={{true}} aria-label="Alerts" data-test-dot-button={{mode}}>A</EuiHeaderSectionItemButton>
                </EuiHeaderSectionItem>
              </EuiHeaderSection>
            </EuiHeader>
            <EuiHeader data-test-default={{mode}}>Default</EuiHeader>
          </EuiEmotionProvider>
        {{/each}}
      </template>
    );

    for (const [mode, theme] of [['light', light], ['dark', dark]] as const) {
      const background = theme.components.headerDarkBackground;
      const ghost = rgb(theme.colors.textGhost);
      assert.strictEqual(css(`[data-test-dark="${mode}"]`).backgroundColor, rgb(background), `${mode}: dark header background`);
      assert.strictEqual(css(`[data-test-default="${mode}"]`).backgroundColor, rgb(theme.components.headerBackground), `${mode}: default header follows the mode`);
      assert.strictEqual(css(`[data-test-logo="${mode}"]`).color, ghost, `${mode}: logo`);
      assert.strictEqual(css(`[data-test-logo="${mode}"] .euiHeaderLogo__text`).color, ghost, `${mode}: logo text`);
      assert.strictEqual(css(`[data-test-link="${mode}"]`).color, ghost, `${mode}: link`);
      assert.strictEqual(
        css(`[data-test-active="${mode}"]`).color,
        rgb(makeHighContrastColor(theme.colors.primary)(background)),
        `${mode}: active link is high-contrast primary on the dark background`
      );
      assert.strictEqual(css(`[data-test-button="${mode}"]`).color, ghost, `${mode}: item button`);
      assert.strictEqual(
        css(`[data-test-button="${mode}"] .euiHeaderSectionItemButton__notification--badge`).boxShadow,
        `${rgb(background)} 0px 0px 0px 1px`,
        `${mode}: badge ring uses the header background`
      );
      assert.strictEqual(
        css(`[data-test-dot-button="${mode}"] .euiHeaderSectionItemButton__notification--dot`).stroke,
        rgb(background),
        `${mode}: dot stroke uses the header background`
      );
    }

    // Upstream focus background on dark header buttons.
    el('[data-test-link="light"]').focus();
    assert.strictEqual(
      css('[data-test-link="light"]').backgroundColor,
      rgb(light.components.headerDarkSectionItemBackgroundFocus)
    );
  });

  test('EuiHeader @position="fixed": stacking, offset variable, body class and padding with cleanup', async function (assert) {
    class State {
      @tracked first = true;
      @tracked second = true;
      @tracked position = 'fixed';
    }
    const state = new State();
    const root = document.documentElement;
    const body = document.body;
    body.style.paddingTop = '3px';
    const height = parseFloat(light.size.xxxl);

    await render(
      <template>
        {{#if state.first}}<EuiHeader @position={{state.position}} data-test-first>First</EuiHeader>{{/if}}
        {{#if state.second}}<EuiHeader @position="fixed" data-test-second>Second</EuiHeader>{{/if}}
      </template>
    );

    const first = el('[data-test-first]');
    assert.strictEqual(css('[data-test-first]').position, 'fixed');
    assert.strictEqual(css('[data-test-first]').zIndex, String(Number(light.levels.header) + 1));
    assert.strictEqual(css('[data-test-first]').left, '0px');
    assert.strictEqual(css('[data-test-first]').right, '0px');
    assert.dom('[data-test-first]').hasAttribute('data-fixed-header');
    assert.strictEqual(first.style.top, '0px', 'first header at the top');
    assert.strictEqual(el('[data-test-second]').style.top, `${height}px`, 'second header stacks below the first');
    assert.strictEqual(root.style.getPropertyValue('--euiFixedHeadersOffset'), `${height * 2}px`);
    assert.true(body.classList.contains('euiBody--headerIsFixed'));
    assert.strictEqual(getComputedStyle(body).paddingTop, `${height * 2}px`, 'body padded by both headers');

    state.second = false;
    await settled();
    assert.strictEqual(root.style.getPropertyValue('--euiFixedHeadersOffset'), `${height}px`);
    assert.true(body.classList.contains('euiBody--headerIsFixed'), 'one fixed header left');
    assert.strictEqual(getComputedStyle(body).paddingTop, `${height}px`);

    // Reactive position: same element, static styles, cleanup.
    state.position = 'static';
    await settled();
    assert.strictEqual(el('[data-test-first]'), first, 'element kept');
    assert.strictEqual(css('[data-test-first]').position, 'relative');
    assert.strictEqual(first.style.top, '');
    assert.dom('[data-test-first]').doesNotHaveAttribute('data-fixed-header');
    assert.false(body.classList.contains('euiBody--headerIsFixed'));
    assert.strictEqual(root.style.getPropertyValue('--euiFixedHeadersOffset'), '');
    assert.strictEqual(body.style.paddingTop, '3px', 'own body padding restored');

    state.position = 'fixed';
    await settled();
    assert.true(body.classList.contains('euiBody--headerIsFixed'));
    assert.strictEqual(css('[data-test-first]').position, 'fixed');

    state.first = false;
    await settled();
    assert.false(body.classList.contains('euiBody--headerIsFixed'), 'removed with the last fixed header');
    assert.strictEqual(root.style.getPropertyValue('--euiFixedHeadersOffset'), '');
    assert.strictEqual(body.style.paddingTop, '3px');
    body.style.paddingTop = '';

    // A caller `style` top wins, as upstream spreads `style` after `top`.
    state.first = true;
    await render(<template><EuiHeader @position="fixed" style="top: 10px" data-test-styled>S</EuiHeader></template>);
    assert.strictEqual(el('[data-test-styled]').style.top, '10px');
    await clearRender();
    assert.false(body.classList.contains('euiBody--headerIsFixed'));
    assert.strictEqual(body.style.paddingTop, '');
  });

  test('EuiHeaderSection / EuiHeaderSectionItem: flex layout, grow, right side, RTL and @sections', async function (assert) {
    const sections = [
      { items: [{ text: 'One' }, { text: 'Two' }], breadcrumbs: [{ text: 'Home', href: '#' }, { text: 'Page' }], border: 'right' as const },
      { items: [{ text: 'Three' }] }
    ];
    await render(
      <template>
        <div style="width: 800px">
          <EuiHeader data-test-ltr>
            <EuiHeaderSection data-test-left>
              <EuiHeaderSectionItem @border="right" data-test-item>Left</EuiHeaderSectionItem>
              <EuiHeaderSectionItem data-test-empty />
            </EuiHeaderSection>
            <EuiHeaderSection @side="right" data-test-right>
              <EuiHeaderSectionItem>Right</EuiHeaderSectionItem>
            </EuiHeaderSection>
          </EuiHeader>
          <EuiHeader>
            <EuiHeaderSection @grow={{true}} data-test-grow><EuiHeaderSectionItem>Grow</EuiHeaderSectionItem></EuiHeaderSection>
            <EuiHeaderSection data-test-nogrow><EuiHeaderSectionItem>Fixed</EuiHeaderSectionItem></EuiHeaderSection>
          </EuiHeader>
          <div dir="rtl">
            <EuiHeader>
              <EuiHeaderSection data-test-rtl-left><EuiHeaderSectionItem>L</EuiHeaderSectionItem></EuiHeaderSection>
              <EuiHeaderSection @side="right" data-test-rtl-right><EuiHeaderSectionItem>R</EuiHeaderSectionItem></EuiHeaderSection>
            </EuiHeader>
          </div>
          <EuiHeader @sections={{sections}} data-test-sections />
        </div>
      </template>
    );

    const section = css('[data-test-left]');
    assert.strictEqual(section.display, 'flex');
    assert.strictEqual(section.flexGrow, '0');
    assert.strictEqual(section.flexShrink, '0');
    assert.strictEqual(css('[data-test-grow]').flexGrow, '1');
    assert.strictEqual(css('[data-test-nogrow]').flexGrow, '0');
    assert.true(box('[data-test-grow]').width > 600, 'grow section takes the remaining space');

    const header = box('[data-test-ltr]');
    assert.true(Math.abs(box('[data-test-right]').right - (header.right - 8)) < 1, 'right section ends at the padding');
    assert.true(box('[data-test-left]').left < header.left + 10, 'left section at the start');
    const rtlRight = box('[data-test-rtl-right]');
    const rtlLeft = box('[data-test-rtl-left]');
    assert.true(rtlRight.left < rtlLeft.left, 'in RTL the end ("right") section is on the left');
    assert.true(box('[data-test-rtl-right]').left < box('[data-test-rtl-left]').right, 'logical margin-inline-start flips');

    const item = css('[data-test-item]');
    assert.strictEqual(item.display, 'flex');
    assert.strictEqual(item.alignItems, 'center');
    assert.strictEqual(item.position, 'relative');
    assert.strictEqual(item.borderRightWidth, '0px', 'latest EUI has no item dividers; @border is ignored');
    assert.strictEqual(item.borderLeftWidth, '0px');
    assert.dom('[data-test-empty]').doesNotExist('an item without content renders nothing, as upstream');
    assert.dom('.euiHeaderSectionItem--borderRight').doesNotExist();

    // @sections: one section per entry, items wrapped in items, breadcrumbs after.
    assert.dom('[data-test-sections] > .euiHeaderSection').exists({ count: 2 });
    assert.dom('[data-test-sections] > .euiHeaderSection:first-child .euiHeaderSectionItem').exists({ count: 2 });
    assert.dom('[data-test-sections] .euiHeaderSectionItem').hasText('One');
    assert.dom('[data-test-sections] > .euiHeaderBreadcrumbs').exists({ count: 1 });
    assert.dom('[data-test-sections] .euiHeaderBreadcrumbs .euiBreadcrumb').exists({ count: 2 });
  });

  test('EuiHeaderSectionItemButton: size, content, notification badge/dot, colors, events and euiAnimate', async function (assert) {
    let clicks = 0;
    let api: { euiAnimate: () => void } | undefined;
    const onClick = () => clicks++;
    const ref = (value: { euiAnimate: () => void }) => (api = value);

    await render(
      <template>
        <EuiHeaderSectionItemButton @onClick={{onClick}} @ref={{ref}} aria-label="Plain" data-test-plain>
          <span data-test-child>P</span>
        </EuiHeaderSectionItemButton>
        <EuiHeaderSectionItemButton @notification={{true}} aria-label="Dot" data-test-dot>D</EuiHeaderSectionItemButton>
        <EuiHeaderSectionItemButton @notification={{12}} aria-label="Count" data-test-count>C</EuiHeaderSectionItemButton>
        <EuiHeaderSectionItemButton @notification={{3}} @notificationColor="subdued" aria-label="Subdued" data-test-subdued>S</EuiHeaderSectionItemButton>
        <EuiHeaderSectionItemButton @href="#help" aria-label="Help" data-test-link>H</EuiHeaderSectionItemButton>
        <EuiHeaderSectionItemButton @disabled={{true}} @onClick={{onClick}} aria-label="Off" data-test-disabled>O</EuiHeaderSectionItemButton>
        <EuiIcon @type="dot" @color="accent" data-test-accent-icon />
      </template>
    );

    const button = css('[data-test-plain]');
    assert.dom('[data-test-plain]').hasTagName('button').hasClass('euiHeaderSectionItemButton').hasClass('euiButtonEmpty').hasAttribute('aria-label', 'Plain');
    assert.strictEqual(button.height, light.size.xxl, 'childHeight (40px) beats the empty button height');
    assert.strictEqual(button.minWidth, light.size.xxl);
    assert.strictEqual(button.paddingLeft, light.size.s);
    assert.strictEqual(button.paddingRight, light.size.s);
    assert.strictEqual(button.position, 'relative');
    assert.strictEqual(button.textAlign, 'center');
    assert.strictEqual(button.fontSize, '0px');
    assert.strictEqual(button.color, rgb(light.components.buttons.textColorText), 'text-colored empty button');
    assert.strictEqual(css('[data-test-plain] .euiHeaderSectionItemButton__content').display, 'inline-block');
    assert.dom('[data-test-plain] .euiHeaderSectionItemButton__content [data-test-child]').exists();
    assert.dom('[data-test-plain] .euiHeaderSectionItemButton__notification').doesNotExist();

    // Boolean: a dot only.
    const dot = css('[data-test-dot] .euiHeaderSectionItemButton__notification--dot');
    assert.dom('[data-test-dot] .euiHeaderSectionItemButton__notification--dot').exists({ count: 1 }).hasAttribute('data-icon-type', 'dot');
    assert.dom('[data-test-dot] .euiHeaderSectionItemButton__notification--badge').doesNotExist();
    assert.strictEqual(dot.position, 'absolute');
    assert.strictEqual(dot.top, '0px');
    assert.strictEqual(dot.right, `${-parseFloat(light.size.base) / 2}px`, 'dot offset is half of size.base');
    assert.strictEqual(dot.stroke, rgb(light.colors.emptyShade));
    assert.strictEqual(dot.color, css('[data-test-accent-icon]').color, 'accent by default (EuiIcon accent)');

    // Count: badge on large screens, dot hidden.
    const badge = css('[data-test-count] .euiHeaderSectionItemButton__notification--badge');
    assert.dom('[data-test-count] .euiHeaderSectionItemButton__notification--badge').hasText('12').hasClass('euiNotificationBadge');
    assert.strictEqual(badge.position, 'absolute');
    assert.strictEqual(badge.right, `${-parseFloat(light.size.s) / 2}px`);
    assert.strictEqual(badge.boxShadow, `${rgb(light.colors.emptyShade)} 0px 0px 0px 1px`);
    assert.notStrictEqual(badge.backgroundColor, 'rgba(0, 0, 0, 0)', 'accent badge is filled');
    assert.strictEqual(css('[data-test-count] .euiHeaderSectionItemButton__notification--dot').display, 'none', 'small-screen dot hidden on large screens');
    assert.notStrictEqual(
      css('[data-test-subdued] .euiHeaderSectionItemButton__notification--badge').backgroundColor,
      badge.backgroundColor,
      'notificationColor changes the badge'
    );

    // Link and disabled.
    assert.dom('[data-test-link]').hasTagName('a').hasAttribute('href', '#help');
    assert.dom('[data-test-disabled]').hasTagName('button').isDisabled();
    await click('[data-test-plain]');
    assert.strictEqual(clicks, 1);

    // euiAnimate wiggles the content span.
    assert.strictEqual(typeof api?.euiAnimate, 'function');
    api!.euiAnimate();
    const animations = el('[data-test-plain] .euiHeaderSectionItemButton__content').getAnimations();
    assert.strictEqual(animations.length, 1);
    assert.strictEqual((animations[0]!.effect as KeyframeEffect).getTiming().duration, 5000);
    animations[0]!.cancel();
  });

  test('EuiHeaderSectionItemButton: count badge becomes a dot below the m breakpoint (iframe viewports)', async function (assert) {
    await render(
      <template>
        <div data-test-wrap>
          <EuiHeaderSectionItemButton @notification={{5}} aria-label="Count" data-test-count>C</EuiHeaderSectionItemButton>
        </div>
      </template>
    );
    const html = el('[data-test-wrap]').outerHTML;
    const m = light.breakpoint.m as number;
    const s = light.breakpoint.s as number;

    const narrow = inViewport(m - 1, html);
    assert.strictEqual(narrow.style('.euiHeaderSectionItemButton__notification--badge').display, 'none', `${m - 1}px: badge hidden`);
    assert.notStrictEqual(narrow.style('.euiHeaderSectionItemButton__notification--dot').display, 'none', `${m - 1}px: dot shown`);
    assert.strictEqual(narrow.style('.euiHeaderSectionItemButton__notification--dot').width, '24px', 'dot keeps the l icon size above xs');
    narrow.remove();

    const wide = inViewport(m, html);
    assert.notStrictEqual(wide.style('.euiHeaderSectionItemButton__notification--badge').display, 'none', `${m}px: badge shown`);
    assert.strictEqual(wide.style('.euiHeaderSectionItemButton__notification--dot').display, 'none', `${m}px: dot hidden`);
    wide.remove();

    const phone = inViewport(s - 1, html);
    const dot = phone.style('.euiHeaderSectionItemButton__notification--dot');
    assert.strictEqual(dot.width, light.size.base, 'upstream shrinks the dot below s');
    assert.strictEqual(dot.height, light.size.base);
    assert.true(Math.abs(parseFloat(dot.top) - 0.09 * parseFloat(light.size.xxl)) < 0.05, `dot moves to 9% (${dot.top})`);
    assert.strictEqual(phone.style('.euiHeaderSectionItemButton').minWidth, `${0.75 * parseFloat(light.size.xxl)}px`);
    phone.remove();
  });

  test('EuiHeaderLogo: upstream box, colors, secure rel, href validation, icon and text', async function (assert) {
    await render(
      <template>
        <EuiHeaderLogo @href="#home" @iconTitle="Home" data-test-logo>Brand</EuiHeaderLogo>
        <EuiHeaderLogo @href="https://elastic.co" @target="_blank" @rel="author" @iconType="logoKibana" data-test-custom />
        <EuiHeaderLogo @href="javascript:alert(1)" data-test-js />
      </template>
    );

    const logo = css('[data-test-logo]');
    assert.dom('[data-test-logo]').hasTagName('a').hasClass('euiHeaderLogo').hasAttribute('href', '#home').hasAttribute('rel', 'noreferrer');
    assert.strictEqual(logo.display, 'inline-flex');
    assert.strictEqual(logo.alignItems, 'center');
    assert.strictEqual(logo.position, 'relative');
    assert.strictEqual(logo.height, light.size.xxl);
    assert.strictEqual(logo.lineHeight, light.size.xxl);
    assert.strictEqual(logo.minWidth, light.size.xxl);
    assert.strictEqual(logo.paddingLeft, light.size.s);
    assert.strictEqual(logo.paddingRight, light.size.s);
    assert.strictEqual(logo.borderTopLeftRadius, light.border.radius.control);
    assert.strictEqual(logo.whiteSpace, 'nowrap');
    assert.strictEqual(logo.textDecorationLine, 'none');
    assert.strictEqual(logo.color, rgb(light.components.buttons.textColorText), 'empty-button text color');

    assert.dom('[data-test-logo] svg.euiHeaderLogo__icon').hasAttribute('aria-label', 'Home').hasAttribute('role', 'img').hasAttribute('data-icon-type', 'logoElastic');
    const text = css('[data-test-logo] .euiHeaderLogo__text');
    assert.strictEqual(text.paddingLeft, light.size.s);
    assert.strictEqual(text.fontWeight, String(light.font.weight.bold), 'xxs title weight');
    assert.strictEqual(text.color, logo.color, 'text follows the logo color');

    assert.dom('[data-test-custom]').hasAttribute('rel', 'author noopener noreferrer').hasAttribute('target', '_blank');
    assert.dom('[data-test-custom] .euiHeaderLogo__icon').hasAttribute('data-icon-type', 'logoKibana').hasAttribute('role', 'presentation');
    assert.dom('[data-test-custom] .euiHeaderLogo__text').doesNotExist();
    assert.dom('[data-test-js]').hasAttribute('href', '', 'javascript: URL dropped, as upstream');

    // Upstream reduces the start padding on xs screens.
    const phone = inViewport(320, el('[data-test-logo]').outerHTML);
    assert.strictEqual(phone.style('.euiHeaderLogo').paddingLeft, light.size.xs);
    assert.strictEqual(phone.style('.euiHeaderLogo').paddingRight, light.size.s);
    phone.remove();
  });

  test('EuiHeaderLinks / EuiHeaderLink: gutters, link defaults and responsive collapse at the theme breakpoint', async function (assert) {
    const GAPS: Record<EuiHeaderLinksGutterSize, string> = {
      none: '0px',
      xxs: light.size.xs,
      xs: light.size.s,
      s: light.size.m,
      m: light.size.base,
      l: light.size.l
    };
    await render(
      <template>
        <div data-test-wrap>
          <EuiHeaderLinks data-test-links>
            <EuiHeaderLink @href="#a" data-test-link>A</EuiHeaderLink>
            <EuiHeaderLink @isActive={{true}} data-test-active>B</EuiHeaderLink>
            <EuiHeaderLink @color="danger" data-test-danger>C</EuiHeaderLink>
          </EuiHeaderLinks>
        </div>
        {{#each-in GAPS as |gutter|}}
          <EuiHeaderLinks @gutterSize={{gutter}} @popoverBreakpoints="none" data-gutter={{gutter}}>
            <EuiHeaderLink>x</EuiHeaderLink>
          </EuiHeaderLinks>
        {{/each-in}}
        <EuiHeaderLinks @popoverBreakpoints={{array}} data-test-never><EuiHeaderLink>x</EuiHeaderLink></EuiHeaderLinks>
      </template>
    );

    assert.dom('[data-test-links]').hasTagName('nav').hasAttribute('aria-label', 'App menu');
    assert.strictEqual(css('[data-test-links]').display, 'flex');
    const list = css('[data-test-links] .euiHeaderLinks__list');
    assert.strictEqual(list.display, 'flex');
    assert.strictEqual(list.alignItems, 'center');
    assert.strictEqual(list.whiteSpace, 'nowrap');
    assert.strictEqual(list.columnGap, light.size.m, "default gutter is upstream 's'");
    for (const [gutter, gap] of Object.entries(GAPS)) {
      assert.strictEqual(css(`[data-gutter="${gutter}"] .euiHeaderLinks__list`).columnGap, gap, `gutter ${gutter}`);
      assert.dom(`[data-gutter="${gutter}"] .euiPopover`).doesNotExist('"none" never collapses');
    }
    assert.dom('[data-test-never] .euiPopover').doesNotExist('[] never collapses');
    assert.dom('.euiHeaderLinks__list--gutterS').doesNotExist('no legacy gutter classes');

    // On this (wide) window the list shows and the popover button is hidden.
    assert.strictEqual(css('[data-test-links] .euiPopover').display, 'none');

    // Header link: an empty button, size s, text or primary color, override.
    assert.dom('[data-test-link]').hasTagName('a').hasClass('euiHeaderLink').hasClass('euiButtonEmpty');
    assert.strictEqual(css('[data-test-link]').height, light.size.xl, "upstream size 's' (32px)");
    assert.strictEqual(css('[data-test-link]').color, rgb(light.components.buttons.textColorText));
    assert.dom('[data-test-active]').hasClass('euiHeaderLink-isActive');
    assert.strictEqual(css('[data-test-active]').color, rgb(light.components.buttons.textColorPrimary));
    assert.strictEqual(css('[data-test-danger]').color, rgb(light.components.buttons.textColorDanger), '@color overrides the default');

    const html = el('[data-test-wrap]').outerHTML;
    const m = light.breakpoint.m as number;
    const narrow = inViewport(m - 1, html);
    assert.strictEqual(narrow.style('.euiHeaderLinks__list').display, 'none', `${m - 1}px: list collapses`);
    assert.notStrictEqual(narrow.style('.euiPopover').display, 'none', `${m - 1}px: menu button shows`);
    narrow.remove();
    const wide = inViewport(m, html);
    assert.strictEqual(wide.style('.euiHeaderLinks__list').display, 'flex', `${m}px: list shows`);
    assert.strictEqual(wide.style('.euiPopover').display, 'none', `${m}px: menu button hidden`);
    wide.remove();
  });

  test('EuiHeaderLinks: mobile popover menu toggles, closes on resize and through the yielded closeMenu', async function (assert) {
    await render(
      <template>
        <EuiHeaderLinks @popoverBreakpoints="all" data-test-links as |closeMenu|>
          <EuiHeaderLink data-test-a>A</EuiHeaderLink>
          <EuiHeaderLink data-test-close {{on "click" closeMenu}}>Close</EuiHeaderLink>
        </EuiHeaderLinks>
      </template>
    );

    assert.dom('[data-test-links] .euiHeaderLinks__list').doesNotExist('"all" always collapses');
    assert.dom('[data-test-links] .euiHeaderSectionItemButton').hasAttribute('aria-label', 'Open menu');
    assert.dom('[data-test-links] .euiHeaderSectionItemButton svg').hasAttribute('data-icon-type', 'apps');
    assert.notStrictEqual(css('[data-test-links] .euiPopover').display, 'none');

    await click('[data-test-links] .euiHeaderSectionItemButton');
    assert.dom('.euiHeaderLinks__mobileList', document.body).exists();
    const link = css('.euiHeaderLinks__mobileList [data-test-a]');
    assert.strictEqual(link.display, 'block', 'mobile links are full-width blocks');
    assert.strictEqual(css('.euiHeaderLinks__mobileList [data-test-a] > .euiButtonEmpty__content').justifyContent, 'flex-start');
    assert.true(
      Math.abs(box('.euiHeaderLinks__mobileList [data-test-a]').width - box('.euiHeaderLinks__mobileList').width) < 1,
      'link spans the list'
    );

    await triggerEvent(window, 'resize');
    assert.dom('.euiHeaderLinks__mobileList', document.body).doesNotExist('resize closes the menu');

    await click('[data-test-links] .euiHeaderSectionItemButton');
    assert.dom('.euiHeaderLinks__mobileList', document.body).exists('reopens');
    await click(el('.euiHeaderLinks__mobileList [data-test-close]'));
    assert.dom('.euiHeaderLinks__mobileList', document.body).doesNotExist('yielded closeMenu closes');
  });

  test('EuiHeaderAlert and EuiHeaderBreadcrumbs: upstream styles and semantics', async function (assert) {
    const crumbs = [{ text: 'Home', href: '#' }, { text: 'Section', href: '#s' }, { text: 'Page' }];
    await render(
      <template>
        <div>
          <EuiHeaderAlert data-test-first>
            <:date>Today</:date>
            <:badge><span data-test-badge>New</span></:badge>
            <:title>Release</:title>
            <:text>Version 2 is out</:text>
            <:action><EuiLink @href="#notes">Read more</EuiLink></:action>
          </EuiHeaderAlert>
          <EuiHeaderAlert data-test-last>
            <:date>Yesterday</:date>
            <:title>Older</:title>
            <:text>Text</:text>
          </EuiHeaderAlert>
        </div>
        <EuiHeader style="width: 600px">
          <EuiHeaderBreadcrumbs @breadcrumbs={{crumbs}} data-test-crumbs />
        </EuiHeader>
      </template>
    );

    const alert = css('[data-test-first]');
    assert.dom('[data-test-first]').hasTagName('article');
    assert.dom('[data-test-first]').hasAttribute('aria-labelledby', el('[data-test-first] h3').id);
    assert.strictEqual(alert.minWidth, '300px');
    assert.strictEqual(alert.paddingLeft, light.size.s);
    assert.strictEqual(alert.marginBottom, light.size.l);
    assert.strictEqual(alert.paddingBottom, light.size.l);
    assert.strictEqual(alert.borderBottomColor, borderColor(light.border.thin));
    assert.strictEqual(alert.borderBottomWidth, '1px');
    const last = css('[data-test-last]');
    assert.strictEqual(last.marginBottom, '0px', 'last alert has no separator');
    assert.strictEqual(last.borderBottomWidth, '0px');
    const title = css('[data-test-first] .euiHeaderAlert__title');
    assert.strictEqual(title.marginTop, '0px');
    assert.strictEqual(title.marginBottom, light.size.s);
    assert.strictEqual(title.fontWeight, String(light.font.weight.bold), 'xs title weight');
    assert.strictEqual(title.color, rgb(light.colors.textHeading));
    const date = css('[data-test-first] .euiHeaderAlert__date');
    assert.strictEqual(date.color, rgb(light.colors.darkShade));
    assert.true(parseFloat(date.fontSize) < parseFloat(css('[data-test-first] .euiHeaderAlert__text').fontSize), 'date is xs, text is s');
    assert.strictEqual(css('[data-test-first] .euiHeaderAlert__text').marginBottom, light.size.base);
    assert.dom('[data-test-first] .euiHeaderAlert__action').doesNotHaveClass('euiLink', 'no legacy link class on the wrapper');
    assert.dom('[data-test-first] .euiHeaderAlert__action a.euiLink').hasAttribute('href', '#notes');
    assert.dom('[data-test-first] [data-test-badge]').hasText('New');
    assert.dom('[data-test-last] [data-test-badge]').doesNotExist();
    assert.dom('[data-test-last] .euiHeaderAlert__action').doesNotExist();

    const crumbsStyle = css('[data-test-crumbs]');
    assert.dom('[data-test-crumbs]').hasClass('euiHeaderBreadcrumbs').hasClass('euiBreadcrumbs');
    assert.strictEqual(crumbsStyle.display, 'flex');
    assert.strictEqual(crumbsStyle.flexGrow, '1');
    assert.strictEqual(crumbsStyle.alignItems, 'center');
    assert.strictEqual(crumbsStyle.marginLeft, light.size.s);
    assert.strictEqual(crumbsStyle.marginRight, light.size.s);
    assert.strictEqual(crumbsStyle.overflow, 'hidden');
    assert.strictEqual(crumbsStyle.whiteSpace, 'nowrap');
    assert.dom('[data-test-crumbs] .euiBreadcrumb').exists({ count: 3 });
  });

  test('EuiCollapsibleNav: overlay vs docked, toggle semantics, button visibility and reactive docking', async function (assert) {
    class State {
      @tracked isOpen = false;
      @tracked isDocked = false;
      @tracked breakpoint: number | 'l' = 0;
      @tracked showButtonIfDocked = false;
      toggle = () => (this.isOpen = !this.isOpen);
      close = () => (this.isOpen = false);
    }
    const state = new State();

    await render(
      <template>
        <EuiCollapsibleNav
          @id="main-nav"
          @isOpen={{state.isOpen}}
          @isDocked={{state.isDocked}}
          @dockedBreakpoint={{state.breakpoint}}
          @showButtonIfDocked={{state.showButtonIfDocked}}
          @onClose={{state.close}}
          data-test-nav
        >
          <:button as |trigger|>
            <EuiHeaderSectionItemButton aria-label="Menu" data-test-toggle {{trigger}} @onClick={{state.toggle}}>M</EuiHeaderSectionItemButton>
          </:button>
          <:content>
            <EuiCollapsibleNavGroup><:content><a href="#l" data-test-content>Links</a></:content></EuiCollapsibleNavGroup>
          </:content>
        </EuiCollapsibleNav>
      </template>
    );

    assert.dom('[data-test-nav]', document.body).doesNotExist('closed overlay nav is not rendered');
    assert.dom('[data-test-toggle]').hasAttribute('aria-controls', 'main-nav').hasAttribute('aria-expanded', 'false').hasAttribute('aria-pressed', 'false');

    await click('[data-test-toggle]');
    assert.dom('[data-test-toggle]').hasAttribute('aria-expanded', 'true').hasAttribute('aria-pressed', 'true');
    assert.dom('#main-nav', document.body).hasTagName('nav').hasClass('euiCollapsibleNav').hasClass('euiFlyout');
    assert.dom('#main-nav [data-test-content]', document.body).hasText('Links');
    assert.strictEqual(css('#main-nav').zIndex, String(light.levels.navigation), 'overlay uses levels.navigation');
    assert.dom('#main-nav [data-test-subj="euiFlyoutCloseButton"]', document.body).exists('overlay keeps the close button');

    await triggerEvent(document.querySelector('#main-nav')!, 'keydown', { key: 'Escape' });
    assert.false(state.isOpen, 'Escape calls @onClose');
    assert.dom('#main-nav', document.body).doesNotExist();
    assert.dom('[data-test-toggle]').hasAttribute('aria-expanded', 'false');

    // Docked at breakpoint 0: always shown, push type, no toggle or close button.
    state.isDocked = true;
    await settled();
    const nav = el('#main-nav');
    assert.dom('[data-test-toggle]').doesNotExist('docked nav hides its toggle');
    assert.dom('#main-nav [data-test-subj="euiFlyoutCloseButton"]').doesNotExist();
    assert.notStrictEqual(css('#main-nav').zIndex, String(light.levels.navigation), 'docked nav has no overlay z-index');

    state.showButtonIfDocked = true;
    await settled();
    assert.dom('[data-test-toggle]').exists('@showButtonIfDocked keeps the toggle');
    assert.strictEqual(el('#main-nav'), nav, 'nav element kept');

    // Above the window width: undocked overlay, closed again.
    state.breakpoint = 99999;
    await settled();
    assert.dom('#main-nav', document.body).doesNotExist('not docked below the breakpoint and closed');

    // Named breakpoint from the theme: the 1440px test window is above `l`.
    state.breakpoint = 'l';
    await settled();
    assert.dom('#main-nav').exists("docked above the theme's l breakpoint");
  });

  test('EuiCollapsibleNavGroup: backgrounds, borders, heading/children padding, collapse and dark provider', async function (assert) {
    class State {
      @tracked background = 'none';
    }
    const state = new State();

    await render(
      <template>
        <EuiEmotionProvider @colorMode="light">
          <div data-test-wrap>
            <EuiCollapsibleNavGroup @background={{state.background}} @iconType="logoKibana" data-test-first>
              <:title>Kibana</:title>
              <:content><span data-test-first-content>links</span></:content>
            </EuiCollapsibleNavGroup>
            <EuiCollapsibleNavGroup @background="light" data-test-light>
              <:content><span>no heading</span></:content>
            </EuiCollapsibleNavGroup>
            <EuiCollapsibleNavGroup @background="dark" @titleElement="h2" data-test-dark>
              <:title>Dark</:title>
              <:content><EuiLink @href="#x" data-test-dark-link>Link</EuiLink></:content>
            </EuiCollapsibleNavGroup>
            <EuiCollapsibleNavGroup @isCollapsible={{true}} @initialIsOpen={{false}} data-test-collapsible>
              <:title>Settings</:title>
              <:content><span data-test-collapsible-content>more</span></:content>
            </EuiCollapsibleNavGroup>
          </div>
        </EuiEmotionProvider>
      </template>
    );

    const first = css('[data-test-first]');
    assert.dom('[data-test-first]').hasClass('euiCollapsibleNavGroup');
    assert.strictEqual(first.backgroundColor, 'rgba(0, 0, 0, 0)', "'none' is transparent");
    assert.strictEqual(first.borderTopWidth, '0px', 'first group has no top border');
    assert.strictEqual(css('[data-test-first] .euiCollapsibleNavGroup__heading').paddingTop, light.size.base);
    assert.strictEqual(css('[data-test-first] .euiCollapsibleNavGroup__heading').paddingLeft, light.size.base);
    const firstChildren = css('[data-test-first] .euiCollapsibleNavGroup__children');
    assert.strictEqual(firstChildren.paddingTop, '0px', 'children under a heading have no top padding');
    assert.strictEqual(firstChildren.paddingLeft, light.size.s);
    assert.dom('[data-test-first] h3.euiTitle.euiCollapsibleNavGroup__title').hasText('Kibana');
    assert.strictEqual(css('[data-test-first] .euiCollapsibleNavGroup__title').marginTop, '0px');
    assert.strictEqual(css('[data-test-first] .euiCollapsibleNavGroup__title').fontWeight, String(light.font.weight.bold), 'xxs title');
    assert.dom('[data-test-first] .euiCollapsibleNavGroup__heading svg[data-icon-type="logoKibana"]').exists();

    const lightGroup = css('[data-test-light]');
    assert.strictEqual(lightGroup.backgroundColor, rgb(light.components.collapsibleNavGroupBackground));
    assert.strictEqual(lightGroup.borderTopColor, borderColor(light.border.thin));
    assert.strictEqual(lightGroup.borderTopWidth, '1px');
    assert.strictEqual(css('[data-test-light] .euiCollapsibleNavGroup__children').paddingTop, light.size.s, 'no heading: full padding');

    // Dark: dark provider tokens, ghost title, content in dark mode.
    assert.dom('[data-test-dark] h2.euiCollapsibleNavGroup__title').hasText('Dark');
    assert.strictEqual(css('[data-test-dark]').backgroundColor, rgb(dark.components.collapsibleNavGroupBackgroundDark));
    assert.strictEqual(css('[data-test-dark]').color, rgb(dark.colors.textParagraph));
    assert.strictEqual(css('[data-test-dark] .euiCollapsibleNavGroup__title').color, rgb(dark.colors.textGhost));
    assert.strictEqual(css('[data-test-dark]').borderTopColor, borderColor(dark.border.thin), 'border from the dark theme');
    assert.strictEqual(css('[data-test-dark-link]').color, rgb(dark.colors.textParagraph), 'content resolves the dark theme');
    assert.dom('[data-test-dark]').doesNotHaveClass('euiThemeProvider', 'no wrapper element');
    assert.strictEqual(el('[data-test-dark]').parentElement, el('[data-test-wrap]'));

    // Collapsible: accordion with padded trigger, closed initially.
    assert.dom('[data-test-collapsible]').hasClass('euiAccordion').hasClass('euiCollapsibleNavGroup');
    assert.strictEqual(css('[data-test-collapsible] .euiAccordion__triggerWrapper').paddingTop, light.size.base);
    assert.dom('[data-test-collapsible]').doesNotHaveClass('euiAccordion-isOpen');
    await click('[data-test-collapsible] .euiCollapsibleNavGroup__heading');
    assert.dom('[data-test-collapsible]').hasClass('euiAccordion-isOpen');
    assert.dom('[data-test-collapsible] [data-test-collapsible-content]').hasText('more');
    assert.strictEqual(css('[data-test-collapsible] .euiCollapsibleNavGroup__children').paddingTop, '0px');

    // Reactive background: same element, dark tokens in and out.
    const element = el('[data-test-first]');
    for (const legacy of ['euiCollapsibleNavGroup--light', 'euiCollapsibleNavGroup--dark', 'euiCollapsibleNavGroup--withHeading']) {
      assert.dom(`.${legacy}`).doesNotExist(`no legacy ${legacy}`);
    }
    state.background = 'dark';
    await settled();
    assert.strictEqual(el('[data-test-first]'), element, 'element kept');
    assert.strictEqual(css('[data-test-first]').backgroundColor, rgb(dark.components.collapsibleNavGroupBackgroundDark));
    assert.strictEqual(css('[data-test-first] .euiCollapsibleNavGroup__title').color, rgb(dark.colors.textGhost));
    state.background = 'light';
    await settled();
    assert.strictEqual(el('[data-test-first]'), element);
    assert.strictEqual(css('[data-test-first]').backgroundColor, rgb(light.components.collapsibleNavGroupBackground));
    assert.strictEqual(css('[data-test-first] .euiCollapsibleNavGroup__title').color, rgb(light.colors.textHeading));
  });

  test('reactive args update styles without replacing elements', async function (assert) {
    class State {
      @tracked theme = 'default';
      @tracked side: 'left' | 'right' = 'left';
      @tracked grow = false;
      @tracked gutter: EuiHeaderLinksGutterSize = 'xs';
      @tracked notification: boolean | number = true;
      @tracked color: 'accent' | 'subdued' = 'accent';
      @tracked iconType = 'logoElastic';
      @tracked isActive = false;
    }
    const state = new State();

    await render(
      <template>
        <EuiHeader @theme={{state.theme}} data-test-header>
          <EuiHeaderSection @side={{state.side}} @grow={{state.grow}} data-test-section>
            <EuiHeaderSectionItem>
              <EuiHeaderLogo @iconType={{state.iconType}} data-test-logo>Brand</EuiHeaderLogo>
            </EuiHeaderSectionItem>
            <EuiHeaderSectionItem>
              <EuiHeaderLinks @gutterSize={{state.gutter}} @popoverBreakpoints="none">
                <EuiHeaderLink @isActive={{state.isActive}} data-test-link>A</EuiHeaderLink>
              </EuiHeaderLinks>
            </EuiHeaderSectionItem>
            <EuiHeaderSectionItem>
              <EuiHeaderSectionItemButton @notification={{state.notification}} @notificationColor={{state.color}} aria-label="N" data-test-button>N</EuiHeaderSectionItemButton>
            </EuiHeaderSectionItem>
          </EuiHeaderSection>
        </EuiHeader>
        <EuiIcon @type="dot" @color="subdued" data-test-subdued-icon />
      </template>
    );

    const header = el('[data-test-header]');
    const section = el('[data-test-section]');
    const logo = el('[data-test-logo]');
    const list = el('.euiHeaderLinks__list');
    const button = el('[data-test-button]');
    const link = el('[data-test-link]');

    state.theme = 'dark';
    state.side = 'right';
    state.grow = true;
    state.gutter = 'l';
    state.color = 'subdued';
    state.iconType = 'logoKibana';
    state.isActive = true;
    await settled();

    assert.strictEqual(el('[data-test-header]'), header);
    assert.strictEqual(el('[data-test-section]'), section);
    assert.strictEqual(el('[data-test-logo]'), logo);
    assert.strictEqual(el('.euiHeaderLinks__list'), list);
    assert.strictEqual(el('[data-test-button]'), button);
    assert.strictEqual(el('[data-test-link]'), link);

    assert.strictEqual(css('[data-test-header]').backgroundColor, rgb(light.components.headerDarkBackground));
    assert.strictEqual(css('[data-test-section]').flexGrow, '1');
    assert.strictEqual(css('.euiHeaderLinks__list').columnGap, light.size.l);
    assert.dom('[data-test-logo] .euiHeaderLogo__icon').hasAttribute('data-icon-type', 'logoKibana');
    assert.dom('[data-test-link]').hasClass('euiHeaderLink-isActive');
    assert.strictEqual(css('[data-test-logo]').color, rgb(light.colors.textGhost));
    assert.strictEqual(
      css('[data-test-button] .euiHeaderSectionItemButton__notification--dot').color,
      css('[data-test-subdued-icon]').color,
      'subdued dot'
    );

    state.notification = 7;
    await settled();
    assert.strictEqual(el('[data-test-button]'), button);
    assert.dom('[data-test-button] .euiHeaderSectionItemButton__notification--badge').hasText('7');
    state.notification = false;
    await settled();
    assert.dom('[data-test-button] .euiHeaderSectionItemButton__notification').doesNotExist();

    state.theme = 'default';
    await settled();
    assert.strictEqual(css('[data-test-header]').backgroundColor, rgb(light.components.headerBackground));
    assert.strictEqual(css('[data-test-logo]').color, rgb(light.components.buttons.textColorText));
  });

  test('light/dark follow the nearest provider with sibling isolation', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
    }
    const state = new State();

    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}}>
          <EuiHeader data-test-outer>
            <EuiHeaderSectionItem><EuiHeaderLogo data-test-outer-logo>O</EuiHeaderLogo></EuiHeaderSectionItem>
            <EuiHeaderSectionItem><EuiHeaderSectionItemButton @notification={{true}} aria-label="n" data-test-outer-button>B</EuiHeaderSectionItemButton></EuiHeaderSectionItem>
          </EuiHeader>
          <EuiEmotionProvider @colorMode="dark">
            <EuiHeader data-test-nested>
              <EuiHeaderLogo data-test-nested-logo>N</EuiHeaderLogo>
            </EuiHeader>
            <EuiCollapsibleNavGroup @background="light" data-test-nested-group><:content>x</:content></EuiCollapsibleNavGroup>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiHeader data-test-sibling>S</EuiHeader>
        </EuiEmotionProvider>
      </template>
    );

    const check = (mode: EuiColorMode) => {
      const theme = mode === 'light' ? light : dark;
      assert.strictEqual(css('[data-test-outer]').backgroundColor, rgb(theme.components.headerBackground), `outer ${mode}`);
      assert.strictEqual(css('[data-test-outer]').borderBottomColor, borderColor(theme.border.thin), `outer border ${mode}`);
      assert.strictEqual(css('[data-test-outer-logo]').color, rgb(theme.components.buttons.textColorText), `outer logo ${mode}`);
      assert.strictEqual(
        css('[data-test-outer-button] .euiHeaderSectionItemButton__notification--dot').stroke,
        rgb(theme.colors.emptyShade),
        `dot stroke ${mode}`
      );
    };
    check('light');
    assert.strictEqual(css('[data-test-nested]').backgroundColor, rgb(dark.components.headerBackground));
    assert.strictEqual(css('[data-test-nested-logo]').color, rgb(dark.components.buttons.textColorText));
    assert.strictEqual(css('[data-test-nested-group]').backgroundColor, rgb(dark.components.collapsibleNavGroupBackground));
    assert.strictEqual(css('[data-test-sibling]').backgroundColor, rgb(light.components.headerBackground));

    const outer = el('[data-test-outer]');
    state.mode = 'dark';
    await settled();
    assert.strictEqual(el('[data-test-outer]'), outer);
    check('dark');
    assert.strictEqual(css('[data-test-sibling]').backgroundColor, rgb(light.components.headerBackground), 'sibling stays light');
    assert.strictEqual(css('[data-test-nested]').backgroundColor, rgb(dark.components.headerBackground));
  });

  test('JS-object Borealis overrides and high contrast reach the header family', async function (assert) {
    class State {
      @tracked overrides: EuiBorealisOverrides | undefined = {
        size: { xxxl: '60px', xxl: '44px', s: '10px' },
        colors: { LIGHT: { emptyShade: '#fafafa', primary: '#663399' } }
      };
      @tracked contrast: EuiBorealisHighContrastMode = false;
    }
    const state = new State();

    await render(
      <template>
        <EuiEmotionProvider @colorMode="light" @borealisOverrides={{state.overrides}} @highContrastMode={{state.contrast}}>
          <EuiHeader @position="fixed" data-test-header>
            <EuiHeaderSectionItem>
              <EuiHeaderSectionItemButton @notification={{true}} aria-label="n" data-test-button>B</EuiHeaderSectionItemButton>
            </EuiHeaderSectionItem>
          </EuiHeader>
          <EuiHeader @theme="dark" data-test-dark>
            <EuiHeaderLinks @popoverBreakpoints="none"><EuiHeaderLink @isActive={{true}} data-test-active>A</EuiHeaderLink></EuiHeaderLinks>
          </EuiHeader>
          <EuiCollapsibleNavGroup data-test-g1><:content>a</:content></EuiCollapsibleNavGroup>
          <EuiCollapsibleNavGroup data-test-g2><:content>b</:content></EuiCollapsibleNavGroup>
        </EuiEmotionProvider>
        <EuiHeader data-test-outside>outside</EuiHeader>
      </template>
    );

    const overridden = resolveBorealisTheme('light', state.overrides).euiTheme;
    assert.strictEqual(css('[data-test-header]').height, '60px', 'size.xxxl override');
    assert.strictEqual(css('[data-test-header]').paddingLeft, '10px', 'size.s override');
    assert.strictEqual(css('[data-test-button]').height, '44px', 'size.xxl override');
    assert.strictEqual(document.documentElement.style.getPropertyValue('--euiFixedHeadersOffset'), '60px', 'offset follows the overridden height');
    assert.strictEqual(getComputedStyle(document.body).paddingTop, '60px');
    assert.strictEqual(
      css('[data-test-button] .euiHeaderSectionItemButton__notification--dot').stroke,
      rgb(overridden.colors.emptyShade)
    );
    assert.strictEqual(
      css('[data-test-active]').color,
      rgb(makeHighContrastColor(overridden.colors.primary)(overridden.components.headerDarkBackground)),
      'active link uses the overridden primary'
    );
    assert.strictEqual(css('[data-test-outside]').height, light.size.xxxl, 'outside the provider is unaffected');

    for (const contrast of ['preferred', 'forced'] as const) {
      state.contrast = contrast;
      await settled();
      const theme = resolveBorealisTheme('light', state.overrides, contrast).euiTheme;
      assert.strictEqual(css('[data-test-header]').borderBottomColor, borderColor(theme.border.thin), `${contrast}: header border`);
      assert.strictEqual(css('[data-test-g2]').borderTopColor, borderColor(theme.border.thin), `${contrast}: group border`);
      assert.strictEqual(css('[data-test-header]').backgroundColor, rgb(theme.components.headerBackground), `${contrast}: background`);
      assert.strictEqual(
        css('[data-test-active]').color,
        rgb(makeHighContrastColor(theme.colors.primary)(theme.components.headerDarkBackground)),
        `${contrast}: active link`
      );
    }

    state.overrides = undefined;
    state.contrast = false;
    await settled();
    assert.strictEqual(css('[data-test-header]').height, light.size.xxxl, 'override removed');
    assert.strictEqual(document.documentElement.style.getPropertyValue('--euiFixedHeadersOffset'), light.size.xxxl);
    await clearRender();
    assert.strictEqual(document.documentElement.style.getPropertyValue('--euiFixedHeadersOffset'), '');
    await rerender();
  });
});
