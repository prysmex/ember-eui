import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { array, hash } from '@ember/helper';
import { render, settled } from '@ember/test-helpers';

import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiIllustration from '#src/components/eui-illustration.gts';
import EuiSkeletonCircle from '#src/components/eui-skeleton-circle.gts';
import EuiSkeletonLoading from '#src/components/eui-skeleton-loading.gts';
import EuiSkeletonRectangle from '#src/components/eui-skeleton-rectangle.gts';
import EuiSkeletonText from '#src/components/eui-skeleton-text.gts';
import EuiSkeletonTitle from '#src/components/eui-skeleton-title.gts';
import {
  euiFontSize,
  euiSkeletonCircleStyles,
  euiSkeletonRectangleStyles,
  euiSkeletonTextStyles,
  euiSkeletonTitleStyles,
  euiTitle
} from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type {
  EuiBorealisHighContrastMode,
  EuiBorealisOverrides
} from '#src/utils/eui/theme.ts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type { EuiIllustrationType } from '#src/components/eui-illustration.gts';
import type { EuiSkeletonTextSize } from '#src/components/eui-skeleton-text.gts';
import type { EuiSkeletonTitleSize } from '#src/components/eui-skeleton-title.gts';
import type { EuiSkeletonCircleSize } from '#src/components/eui-skeleton-circle.gts';
import type { EuiSkeletonRectangleRadius } from '#src/components/eui-skeleton-rectangle.gts';
import type {
  EuiScreenReaderLiveProps,
  EuiSkeletonAriaWrapperProps
} from '#src/components/eui-skeleton-loading.gts';

const lightContext = resolveBorealisTheme('light');
const light = lightContext.euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;

function el(selector: string): HTMLElement {
  const element = document.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function css(selector: string, pseudo?: string) {
  return getComputedStyle(el(selector), pseudo);
}

/** Normalize any CSS color to the browser's computed `rgb()` form. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

/** Resolve a CSS length (rem, calc, …) to computed px in this document. */
function len(value: string) {
  const probe = document.createElement('div');
  probe.style.height = value;
  document.body.appendChild(probe);
  const px = getComputedStyle(probe).height;
  probe.remove();
  return px;
}

const canAnimate = () =>
  matchMedia('(prefers-reduced-motion: no-preference)').matches;

/** The two alternating live regions under `root`, as `[text, aria-live]`. */
function liveRegions(root: Element) {
  return [...root.querySelectorAll('[aria-atomic="true"]')].map((region) => [
    region.textContent ?? '',
    region.getAttribute('aria-live'),
    region.getAttribute('aria-hidden'),
    region.getAttribute('role')
  ]);
}

/** The live text being announced (the region with content). */
function announced(root: Element) {
  return liveRegions(root)
    .map(([text]) => text)
    .join('');
}

const asset: EuiIllustrationType = {
  id: 'sample',
  title: 'Sample illustration',
  light:
    '<svg data-mode="light" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 100" width="200" height="100"><rect width="200" height="100" fill="#eee"/></svg>',
  dark: '<svg data-mode="dark" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 100" width="200" height="100"><rect width="200" height="100" fill="#111"/></svg>'
};

const otherAsset: EuiIllustrationType = {
  id: 'other',
  title: 'Other illustration',
  light: '<svg data-mode="other-light" viewBox="0 0 10 10" width="10" height="10"></svg>',
  dark: '<svg data-mode="other-dark" viewBox="0 0 10 10" width="10" height="10"></svg>'
};

module('Integration | Component | Borealis skeleton family', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiSkeletonText: lines, upstream line sizes, last line width, attributes and @css', async function (assert) {
    await render(
      <template>
        <div style="width: 400px">
          <EuiSkeletonText data-default class="caller" />
          <EuiSkeletonText @lines={{1}} data-one />
          <EuiSkeletonText @lines={{5}} @size="s" data-s />
          <EuiSkeletonText @lines={{2}} @size="xs" data-xs />
          <div style="font-size: 20px"><EuiSkeletonText @size="relative" data-relative /></div>
          <EuiSkeletonText @css={{hash marginTop="7px"}} data-css />
        </div>
      </template>
    );

    assert
      .dom('[data-default]')
      .hasTagName('span')
      .hasClass('euiSkeletonText')
      .hasClass('caller', '...attributes go on the skeleton')
      .hasAttribute('role', 'progressbar');
    assert.dom('[data-default] > span').exists({ count: 3 }, 'three lines by default');
    assert.dom('[data-one] > span').exists({ count: 1 });
    assert.dom('[data-s] > span').exists({ count: 5 });

    const lines = document.querySelectorAll<HTMLElement>('[data-default] > span');
    assert.strictEqual(getComputedStyle(lines[0]!).width, '400px', 'full width');
    assert.strictEqual(getComputedStyle(lines[2]!).width, '300px', 'last line is 75% wide');
    assert.strictEqual(
      css('[data-one] > span').width,
      '400px',
      'an only line stays full width'
    );
    assert.strictEqual(getComputedStyle(lines[0]!).display, 'block');
    assert.strictEqual(getComputedStyle(lines[0]!).borderTopLeftRadius, light.border.radius.inline);
    assert.true(getComputedStyle(lines[0]!).transform.startsWith('matrix(1, 0, 0, 1, 0, -'), 'shifted up 25%');

    for (const size of ['m', 's', 'xs'] as const) {
      const { fontSize, lineHeight } = euiFontSize(lightContext, 'm', { customScale: size });
      const line = css(`[data-${size === 'm' ? 'default' : size}] > span`);
      assert.strictEqual(line.height, len(fontSize), `${size}: line as tall as the font size`);
      // upstream subtracts the rem values (mathWithUnits); Chrome snaps each
      // length to 1/64px, so allow that rounding
      const gap = parseFloat(len(lineHeight)) - parseFloat(len(fontSize));
      assert.true(
        gap > 0 && Math.abs(parseFloat(line.marginTop) - gap) < 0.05,
        `${size}: gap is line height minus font size (${line.marginTop} ≈ ${gap}px)`
      );
    }
    assert.strictEqual(css('[data-relative] > span').height, '20px', 'relative lines are 1em');
    assert.strictEqual(css('[data-relative] > span').marginTop, '10px', 'relative gap is 0.5em');
    assert.strictEqual(css('[data-css]').marginTop, '7px', '@css composes into the skeleton');
  });

  test('EuiSkeletonTitle, EuiSkeletonCircle and EuiSkeletonRectangle sizes', async function (assert) {
    await render(
      <template>
        <div style="width: 400px">
          <EuiSkeletonTitle data-title />
          {{#each (array "xxxs" "xxs" "xs" "s" "m" "l") as |size|}}
            <EuiSkeletonTitle @size={{size}} data-title-size={{size}} />
          {{/each}}
          <EuiSkeletonCircle data-circle />
          {{#each (array "s" "m" "l" "xl") as |size|}}
            <EuiSkeletonCircle @size={{size}} data-circle-size={{size}} />
          {{/each}}
          <EuiSkeletonRectangle data-rect />
          <EuiSkeletonRectangle
            @width={{120}}
            @height="2em"
            @borderRadius="none"
            style="font-size: 10px; margin-left: 3px; width: 999px"
            data-rect-custom
          />
          <EuiSkeletonRectangle @width="50%" @borderRadius="m" data-rect-percent />
        </div>
      </template>
    );

    assert.dom('[data-title]').hasTagName('span').hasClass('euiSkeletonTitle');
    assert.strictEqual(css('[data-title]').width, '180px', 'title is 45% wide');
    assert.strictEqual(css('[data-title]').display, 'block');
    assert.strictEqual(
      css('[data-title]').height,
      len(euiTitle(lightContext, 'm').lineHeight),
      'default size m'
    );
    for (const size of ['xxxs', 'xxs', 'xs', 's', 'm', 'l'] as const) {
      assert.strictEqual(
        css(`[data-title-size="${size}"]`).height,
        len(euiTitle(lightContext, size).lineHeight),
        `title ${size} is as tall as an EuiTitle line`
      );
    }

    assert.dom('[data-circle]').hasTagName('div').hasClass('euiSkeletonCircle');
    assert.strictEqual(css('[data-circle]').borderTopLeftRadius, '50%');
    const circleSizes = {
      s: light.size.l,
      m: light.size.xl,
      l: light.size.xxl,
      xl: `calc(${light.size.base} * 4)`
    };
    assert.strictEqual(css('[data-circle]').width, len(circleSizes.m), 'default size m');
    for (const [size, expected] of Object.entries(circleSizes)) {
      const circle = css(`[data-circle-size="${size}"]`);
      assert.strictEqual(circle.width, len(expected), `circle ${size} width`);
      assert.strictEqual(circle.height, len(expected), `circle ${size} height`);
    }

    assert.dom('[data-rect]').hasTagName('div').hasClass('euiSkeletonRectangle');
    assert.strictEqual(css('[data-rect]').width, '24px', 'default width');
    assert.strictEqual(css('[data-rect]').height, '24px', 'default height');
    assert.strictEqual(css('[data-rect]').borderTopLeftRadius, light.border.radius.inline);
    const custom = css('[data-rect-custom]');
    assert.strictEqual(custom.width, '120px', 'numbers are px and beat the caller width');
    assert.strictEqual(custom.height, '20px', 'CSS lengths are kept');
    assert.strictEqual(custom.borderTopLeftRadius, '0px', 'none radius');
    assert.strictEqual(custom.marginLeft, '3px', 'other caller styles are kept');
    assert.strictEqual(css('[data-rect-percent]').width, '200px');
    assert.strictEqual(css('[data-rect-percent]').borderTopLeftRadius, light.border.radius.inline);
  });

  test('shimmer animates only without reduced motion, with the theme gradient', async function (assert) {
    await render(
      <template>
        <EuiSkeletonText @lines={{1}} data-text />
        <EuiSkeletonTitle data-title />
        <EuiSkeletonCircle data-circle />
        <EuiSkeletonRectangle data-rect />
      </template>
    );
    const guards = ['prefers-reduced-motion: no-preference', 'prefers-reduced-motion: reduce'];
    const factories = [
      euiSkeletonTextStyles(lightContext).euiSkeletonText,
      euiSkeletonTitleStyles(lightContext).euiSkeletonTitle,
      euiSkeletonCircleStyles(lightContext).euiSkeletonCircle,
      euiSkeletonRectangleStyles(lightContext).euiSkeletonRectangle
    ];
    for (const styles of factories)
      for (const guard of guards)
        assert.true(styles.styles.includes(guard), `${guard} guard present`);

    const edge = rgb(light.colors.backgroundBaseSkeletonEdge);
    const middle = rgb(light.colors.backgroundBaseSkeletonMiddle);
    for (const selector of ['[data-text] > span', '[data-title]', '[data-circle]', '[data-rect]']) {
      if (canAnimate()) {
        const after = css(selector, '::after');
        assert.notStrictEqual(after.animationName, 'none', `${selector} shimmers`);
        assert.strictEqual(after.animationDuration, '1.5s');
        assert.strictEqual(after.animationIterationCount, 'infinite');
        assert.true(after.backgroundImage.startsWith('linear-gradient(137deg'), `${selector} gradient`);
        assert.true(after.backgroundImage.includes(edge), 'gradient edge token');
        assert.true(after.backgroundImage.includes(middle), 'gradient middle token');
        assert.strictEqual(css(selector).overflow, 'hidden', 'shine clipped');
      } else {
        assert.strictEqual(css(selector).backgroundColor, edge, `${selector} static edge color`);
        assert.strictEqual(css(selector, '::after').animationName, 'none');
      }
    }
  });

  test('loading to loaded: aria-busy, progressbar label, content swap and live announcements', async function (assert) {
    class State {
      @tracked isLoading = true;
      @tracked label = 'API keys';
    }
    const state = new State();
    await render(
      <template>
        <div data-announce>
          <EuiSkeletonText
            @isLoading={{state.isLoading}}
            @contentAriaLabel={{state.label}}
            @announceLoadingStatus={{true}}
            aria-label="ignored"
            data-skeleton
          >
            <p data-loaded>Loaded content</p>
          </EuiSkeletonText>
        </div>
        <div data-default-announce>
          <EuiSkeletonTitle @isLoading={{state.isLoading}} data-title>
            <h2 data-title-loaded>Title</h2>
          </EuiSkeletonTitle>
        </div>
        <div data-silent>
          <EuiSkeletonCircle
            @isLoading={{state.isLoading}}
            @announceLoadedStatus={{false}}
          >circle</EuiSkeletonCircle>
        </div>
      </template>
    );

    const wrapper = el('[data-announce] [data-test-subj="euiSkeletonLoadingAriaWrapper"]');
    assert.dom(wrapper).hasTagName('div').hasAttribute('aria-busy', 'true');
    assert
      .dom('[data-skeleton]')
      .hasAttribute('role', 'progressbar')
      .hasAria('label', 'Loading API keys', 'upstream label overrides a caller aria-label');
    assert.dom('[data-loaded]').doesNotExist();
    assert.strictEqual(announced(wrapper), 'Loading API keys', 'loading status announced');
    const [first, second] = liveRegions(wrapper);
    assert.deepEqual(first, ['Loading API keys', 'polite', null, 'status'], 'swapped into the first region after insertion');
    assert.deepEqual(second, ['', 'off', 'true', 'status']);
    assert.strictEqual(
      wrapper.querySelector('[aria-atomic]')!.parentElement!.className.includes('euiScreenReaderOnly'),
      true,
      'live regions are visually hidden'
    );
    assert.strictEqual(getComputedStyle(wrapper.querySelector('[aria-atomic]')!.parentElement!).position, 'absolute');

    const titleWrapper = el('[data-default-announce] [data-test-subj="euiSkeletonLoadingAriaWrapper"]');
    assert.strictEqual(liveRegions(titleWrapper).length, 0, 'no loading announcement by default');
    assert.dom('[data-title]').hasAria('label', 'Loading ', 'upstream label without a content label');

    state.isLoading = false;
    await settled();
    assert.dom(wrapper).hasAttribute('aria-busy', 'false');
    assert.dom('[data-skeleton]').doesNotExist('skeleton removed');
    assert.dom('[data-loaded]').hasText('Loaded content', 'block rendered');
    assert.strictEqual(announced(wrapper), 'Loaded API keys', 'loaded status announced');
    assert.deepEqual(liveRegions(wrapper)[0], ['Loaded API keys', 'polite', null, 'status']);
    assert.strictEqual(announced(titleWrapper), 'Loaded ', 'loaded announced by default');
    assert.dom('[data-title-loaded]').exists();
    const silent = el('[data-silent] [data-test-subj="euiSkeletonLoadingAriaWrapper"]');
    assert.strictEqual(liveRegions(silent).length, 0, '@announceLoadedStatus={{false}}');
    assert.dom(silent).hasText('circle');

    state.label = 'secrets';
    await settled();
    const regions = liveRegions(wrapper);
    assert.deepEqual(
      regions.map(([text, live]) => [text, live]),
      [
        ['', 'off'],
        ['Loaded secrets', 'polite']
      ],
      'a text change moves the announcement to the other region'
    );

    state.isLoading = true;
    await settled();
    assert.dom('[data-skeleton]').exists('back to loading');
    assert.strictEqual(announced(wrapper), 'Loading secrets');
  });

  test('ariaLiveProps, ariaWrapperProps and EuiSkeletonLoading blocks', async function (assert) {
    class State {
      @tracked isLoading = true;
      @tracked wrapperProps: EuiSkeletonAriaWrapperProps = {
        className: 'wrapped',
        'data-wrapper': 'yes'
      };
    }
    const state = new State();
    const liveProps: EuiScreenReaderLiveProps = {
      role: 'alert',
      'aria-live': 'assertive',
      focusRegionOnTextChange: true
    };
    const inactive: EuiScreenReaderLiveProps = { isActive: false };
    await render(
      <template>
        <div data-live>
          <EuiSkeletonRectangle
            @isLoading={{state.isLoading}}
            @ariaLiveProps={{liveProps}}
            @ariaWrapperProps={{state.wrapperProps}}
            @contentAriaLabel="chart"
          >chart</EuiSkeletonRectangle>
        </div>
        <div data-inactive>
          <EuiSkeletonCircle @isLoading={{state.isLoading}} @ariaLiveProps={{inactive}} />
        </div>
        <EuiSkeletonLoading
          @isLoading={{state.isLoading}}
          @contentAriaLabel="profile"
          @css={{hash paddingTop="5px"}}
          class="custom-wrapper"
          data-loading
        >
          <:loadingContent as |loading|>
            <div role={{loading.role}} aria-label={{loading.ariaLabel}} data-loading-content>
              <EuiSkeletonCircle />
              <EuiSkeletonText @lines={{2}} />
            </div>
          </:loadingContent>
          <:loadedContent>
            <span data-loaded-content>Profile</span>
          </:loadedContent>
        </EuiSkeletonLoading>
      </template>
    );

    const wrapper = el('[data-live] [data-test-subj="euiSkeletonLoadingAriaWrapper"]');
    assert.dom(wrapper).hasClass('wrapped').hasAttribute('data-wrapper', 'yes');

    assert.dom('[data-loading]').hasClass('custom-wrapper').hasAttribute('aria-busy', 'true');
    assert.strictEqual(css('[data-loading]').paddingTop, '5px', '@css on the wrapper');
    assert
      .dom('[data-loading-content]')
      .hasAttribute('role', 'progressbar')
      .hasAria('label', 'Loading profile');
    assert.dom('[data-loaded-content]').doesNotExist();

    state.isLoading = false;
    await settled();
    assert.deepEqual(liveRegions(wrapper)[0], ['Loaded chart', 'off', null, 'alert'], 'role/aria-live props, off while focusing');
    const region = wrapper.querySelector('[aria-atomic]')!.parentElement!;
    assert.strictEqual(region.getAttribute('tabindex'), '-1');
    assert.strictEqual(document.activeElement, region, 'focusRegionOnTextChange focuses the region');
    assert.strictEqual(
      announced(el('[data-inactive] [data-test-subj="euiSkeletonLoadingAriaWrapper"]')),
      '',
      'isActive false keeps the regions empty'
    );
    assert.dom('[data-loaded-content]').hasText('Profile');
    assert.dom('[data-loading]').hasAttribute('aria-busy', 'false');

    state.wrapperProps = { 'data-other': '1' };
    await settled();
    assert.dom(wrapper).doesNotHaveClass('wrapped', 'previous props removed').doesNotHaveAttribute('data-wrapper').hasAttribute('data-other', '1');
  });

  test('reactive args update the same elements', async function (assert) {
    class State {
      @tracked lines = 2;
      @tracked textSize: EuiSkeletonTextSize = 'm';
      @tracked titleSize: EuiSkeletonTitleSize = 'xs';
      @tracked circleSize: EuiSkeletonCircleSize = 's';
      @tracked width: string | number = 30;
      @tracked radius: EuiSkeletonRectangleRadius = 's';
    }
    const state = new State();
    await render(
      <template>
        <EuiSkeletonText @lines={{state.lines}} @size={{state.textSize}} data-text />
        <EuiSkeletonTitle @size={{state.titleSize}} data-title />
        <EuiSkeletonCircle @size={{state.circleSize}} data-circle />
        <EuiSkeletonRectangle @width={{state.width}} @borderRadius={{state.radius}} data-rect />
      </template>
    );
    const text = el('[data-text]');
    const firstLine = el('[data-text] > span');
    const title = el('[data-title]');
    const circle = el('[data-circle]');
    const rect = el('[data-rect]');

    state.lines = 4;
    state.textSize = 'xs';
    state.titleSize = 'l';
    state.circleSize = 'xl';
    state.width = '3em';
    state.radius = 'none';
    await settled();

    assert.strictEqual(el('[data-text]'), text, 'same text element');
    assert.strictEqual(el('[data-text] > span'), firstLine, 'same first line');
    assert.dom('[data-text] > span').exists({ count: 4 });
    assert.strictEqual(
      getComputedStyle(firstLine).height,
      len(euiFontSize(lightContext, 'm', { customScale: 'xs' }).fontSize)
    );
    assert.strictEqual(el('[data-title]'), title);
    assert.strictEqual(getComputedStyle(title).height, len(euiTitle(lightContext, 'l').lineHeight));
    assert.strictEqual(el('[data-circle]'), circle);
    assert.strictEqual(getComputedStyle(circle).width, len(`calc(${light.size.base} * 4)`));
    assert.strictEqual(el('[data-rect]'), rect);
    assert.strictEqual(getComputedStyle(rect).width, len('3em'));
    assert.strictEqual(getComputedStyle(rect).borderTopLeftRadius, '0px');
  });

  test('light/dark nearest provider, sibling isolation, JS-object overrides and high contrast', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'dark';
      @tracked contrast: EuiBorealisHighContrastMode = false;
      @tracked overrides: EuiBorealisOverrides = {};
    }
    const state = new State();
    const gradient = (selector: string) => css(selector, '::after').backgroundImage;
    const staticColor = (selector: string) => css(selector).backgroundColor;
    // the visible token for the current motion preference
    const shows = (selector: string, color: string) =>
      canAnimate()
        ? gradient(selector).includes(rgb(color))
        : staticColor(selector) === rgb(color);

    await render(
      <template>
        <EuiEmotionProvider @colorMode="light">
          <EuiSkeletonTitle data-light />
          <EuiEmotionProvider @colorMode={{state.mode}}>
            <EuiSkeletonTitle data-nested />
          </EuiEmotionProvider>
          <EuiSkeletonTitle data-light-sibling />
        </EuiEmotionProvider>
        <EuiEmotionProvider
          @colorMode="light"
          @highContrastMode={{state.contrast}}
          @borealisOverrides={{state.overrides}}
        >
          <EuiSkeletonCircle @size="xl" data-themed />
        </EuiEmotionProvider>
      </template>
    );

    assert.true(shows('[data-light]', light.colors.backgroundBaseSkeletonEdge), 'light edge');
    assert.true(shows('[data-nested]', dark.colors.backgroundBaseSkeletonEdge), 'nearest provider is dark');
    assert.true(shows('[data-light-sibling]', light.colors.backgroundBaseSkeletonEdge), 'sibling keeps light');
    assert.notStrictEqual(
      rgb(light.colors.backgroundBaseSkeletonEdge),
      rgb(dark.colors.backgroundBaseSkeletonEdge),
      'modes differ'
    );
    const nested = el('[data-nested]');
    state.mode = 'light';
    await settled();
    assert.strictEqual(el('[data-nested]'), nested, 'same element after a mode switch');
    assert.true(shows('[data-nested]', light.colors.backgroundBaseSkeletonEdge), 'reactive mode');

    state.overrides = {
      size: { base: '20px' },
      colors: { LIGHT: { backgroundBaseSkeletonEdge: '#ff0000' } }
    };
    await settled();
    assert.strictEqual(css('[data-themed]').width, '80px', 'xl circle is 4 × the overridden base');
    assert.true(shows('[data-themed]', '#ff0000'), 'overridden skeleton color');
    assert.true(shows('[data-light]', light.colors.backgroundBaseSkeletonEdge), 'override stays in its provider');

    state.overrides = {};
    state.contrast = 'preferred';
    await settled();
    if (canAnimate()) {
      const highContrast = resolveBorealisTheme('light', {}, 'preferred').euiTheme;
      assert.true(
        gradient('[data-themed]').includes(
          rgb(highContrast.components.skeletonBackgroundSkeletonMiddleHighContrast)
        ),
        'high contrast uses the stronger shine'
      );
    } else {
      assert.true(shows('[data-themed]', light.colors.backgroundBaseSkeletonEdge));
    }
    assert.strictEqual(css('[data-themed]').forcedColorAdjust, 'auto');
    state.contrast = 'forced';
    await settled();
    assert.strictEqual(css('[data-themed]').forcedColorAdjust, 'none', 'forced contrast keeps skeleton colors');
  });

  test('EuiIllustration: color mode markup, a11y, sizing, reactive args and @css', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
      @tracked type = asset;
      @tracked fullWidth = true;
    }
    const state = new State();
    await render(
      <template>
        <div style="width: 400px">
          <EuiEmotionProvider @colorMode={{state.mode}}>
            <EuiIllustration @type={{state.type}} @fullWidth={{state.fullWidth}} data-default />
          </EuiEmotionProvider>
          <EuiEmotionProvider @colorMode="dark">
            <EuiIllustration @type={{asset}} @alt="" data-decorative />
          </EuiEmotionProvider>
          <EuiIllustration @type={{asset}} @alt="Custom alt" @css={{hash marginTop="4px"}} data-alt />
          <EuiIllustration @type={{asset}} aria-label="Caller label" data-caller />
        </div>
      </template>
    );

    assert
      .dom('[data-default]')
      .hasTagName('span')
      .hasClass('euiIllustration')
      .hasAttribute('role', 'img')
      .hasAria('label', 'Sample illustration', 'title is the default label')
      .doesNotHaveAttribute('aria-hidden');
    assert.dom('[data-default] svg[data-mode="light"]').exists('light markup in light mode');
    assert.dom('[data-decorative] svg[data-mode="dark"]').exists('dark markup under a dark provider');
    assert
      .dom('[data-decorative]')
      .hasAttribute('aria-hidden', 'true')
      .doesNotHaveAttribute('role')
      .doesNotHaveAttribute('aria-label');
    assert.dom('[data-alt]').hasAria('label', 'Custom alt');
    assert.dom('[data-caller]').hasAria('label', 'Caller label', 'attributes override, as upstream rest props');
    assert.strictEqual(css('[data-alt]').marginTop, '4px', '@css composes');

    assert.strictEqual(css('[data-default]').display, 'block', 'full width by default');
    assert.strictEqual(css('[data-default]').width, '400px');
    assert.strictEqual(css('[data-default]').lineHeight, '0px');
    assert.strictEqual(css('[data-default] svg').display, 'block');
    assert.strictEqual(css('[data-default] svg').width, '400px', 'svg fills the width');
    assert.strictEqual(css('[data-default] svg').height, '200px', 'keeps its aspect ratio');

    const element = el('[data-default]');
    state.mode = 'dark';
    state.fullWidth = false;
    await settled();
    assert.strictEqual(el('[data-default]'), element, 'same element');
    assert.dom('[data-default] svg[data-mode="dark"]').exists('markup follows the mode');
    assert.strictEqual(css('[data-default]').display, 'inline-block');
    assert.strictEqual(css('[data-default] svg').width, '200px', 'intrinsic width');

    state.type = otherAsset;
    await settled();
    assert.dom('[data-default] svg[data-mode="other-dark"]').exists();
    assert.dom('[data-default]').hasAria('label', 'Other illustration');
  });
});
