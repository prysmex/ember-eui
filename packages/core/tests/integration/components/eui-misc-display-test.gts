import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { click, focus, render, settled, triggerKeyEvent, waitUntil } from '@ember/test-helpers';

import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiExpression from '#src/components/eui-expression.gts';
import EuiTextDiff from '#src/components/eui-text-diff.gts';
import EuiTour from '#src/components/eui-tour.gts';
import EuiTourStep from '#src/components/eui-tour-step.gts';
import EuiTourStepIndicator from '#src/components/eui-tour-step-indicator.gts';
import EuiTreeView from '#src/components/eui-tree-view.gts';
import { euiFontSize, euiPaddingSize, transparentize } from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiExpressionColor } from '#src/components/eui-expression.gts';
import type { EuiTreeViewNode } from '#src/components/eui-tree-view.gts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type { EuiBorealisHighContrastMode, EuiBorealisOverrides } from '#src/utils/eui/theme.ts';

const lightContext = resolveBorealisTheme('light');
const light = lightContext.euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;

function el(selector: string, root: ParentNode = document): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function css(selector: string | Element, root: ParentNode = document) {
  return getComputedStyle(typeof selector === 'string' ? el(selector, root) : selector);
}

/** Normalize any CSS color to the browser's computed form. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

const rootFontSize = () => parseFloat(getComputedStyle(document.documentElement).fontSize);
const canAnimate = () => matchMedia('(prefers-reduced-motion: no-preference)').matches;
const panelM = euiPaddingSize(lightContext, 'm')!;
const px = (rem: string) => `${parseFloat(rem) * rootFontSize()}px`;

const COLORS: EuiExpressionColor[] = ['subdued', 'primary', 'success', 'accent', 'warning', 'danger'];
const TEXT_TOKEN = {
  subdued: 'textSubdued',
  primary: 'textPrimary',
  success: 'textSuccess',
  accent: 'textAccent',
  warning: 'textWarning',
  danger: 'textDanger'
} as const;
const BORDER_TOKEN = {
  subdued: 'textSubdued',
  primary: 'primary',
  success: 'success',
  accent: 'accent',
  warning: 'warning',
  danger: 'danger'
} as const;

function treeItems(): EuiTreeViewNode[] {
  return [
    {
      id: 'src',
      label: 'src',
      icon: 'folderClosed',
      iconWhenExpanded: 'folderOpen',
      children: [
        { id: 'index', label: 'index.ts', icon: 'document' },
        { id: 'utils', label: 'utils', children: [{ id: 'dates', label: 'dates.ts' }] }
      ]
    },
    { id: 'empty', label: 'Empty icon', useEmptyIcon: true },
    { id: 'readme', label: 'A very long README file name that does not fit', icon: 'document' }
  ];
}

const tourPanel = () => document.querySelector<HTMLElement>('.euiTour');
const tourOpened = () =>
  waitUntil(
    () => {
      const panel = tourPanel();
      return panel && panel.dataset['popoverOpen'] === 'true' && getComputedStyle(panel).opacity === '1';
    },
    { timeout: 3000 }
  );

module('Integration | Component | Borealis misc display (tree view, text diff, expression, tour)', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiTreeView default and compressed: measured list, items, buttons, icons and labels', async function (assert) {
    const items = treeItems();
    await render(
      <template>
        <EuiEmotionProvider>
          <div style="width: 200px">
            <EuiTreeView @items={{items}} @expandByDefault={{true}} aria-label="Default" data-test="default" />
            <EuiTreeView
              @items={{items}}
              @display="compressed"
              @showExpansionArrows={{true}}
              aria-label="Compressed"
              data-test="compressed"
            />
          </div>
        </EuiEmotionProvider>
      </template>
    );
    const root = this.element;
    const def = el('[data-test="default"]', root);
    const comp = el('[data-test="compressed"]', root);

    assert.strictEqual(css(def).listStyleType, 'none');
    assert.strictEqual(css(def).marginTop, '0px');
    assert.strictEqual(css(def).paddingLeft, '0px', 'root list is not indented');
    assert.strictEqual(css(def).fontSize, px(euiFontSize(lightContext, 'm').fontSize as string), 'default font m');
    assert.strictEqual(css(comp).fontSize, px(euiFontSize(lightContext, 's').fontSize as string), 'compressed font s');
    assert.strictEqual(css('ul.euiTreeView', el('#src', def).parentElement!).paddingLeft, light.size.l, 'nested lists indent by size.l');

    const defNode = el('#readme', def).parentElement!;
    const compNode = el('#readme', comp).parentElement!;
    assert.strictEqual(css(defNode).maxHeight, light.size.xl);
    assert.strictEqual(css(defNode).lineHeight, light.size.xl);
    assert.strictEqual(css(compNode).maxHeight, light.size.l);
    assert.strictEqual(css(compNode).lineHeight, light.size.l);
    assert.strictEqual(css(el('#src', def).parentElement!).maxHeight, 'none', 'expanded nodes grow');
    assert.dom(el('#src', def).parentElement!).hasClass('euiTreeView__node--expanded');

    const defButton = css(el('#readme', def));
    const compButton = css(el('#readme', comp));
    assert.strictEqual(defButton.height, light.size.xl);
    assert.strictEqual(defButton.columnGap, light.size.s);
    assert.strictEqual(defButton.display, 'flex');
    assert.strictEqual(defButton.alignItems, 'center');
    assert.strictEqual(defButton.width, '200px', 'buttons span the row');
    assert.strictEqual(defButton.paddingLeft, light.size.s);
    assert.strictEqual(defButton.paddingRight, light.size.xxs);
    assert.strictEqual(defButton.borderTopLeftRadius, light.border.radius.control);
    assert.strictEqual(defButton.backgroundColor, 'rgba(0, 0, 0, 0)');
    assert.strictEqual(defButton.borderTopStyle, 'none', 'scoped button reset');
    assert.strictEqual(compButton.height, light.size.l);
    assert.strictEqual(compButton.columnGap, light.size.xs);

    const defIcon = css('#readme .euiTreeView__iconWrapper', def);
    assert.strictEqual(defIcon.width, `${parseFloat(light.size.xl) / 2}px`, 'icon wrapper is half the row');
    assert.strictEqual(defIcon.flexShrink, '0');
    assert.strictEqual(css('#readme .euiTreeView__iconWrapper', comp).width, `${parseFloat(light.size.l) / 2}px`);
    assert.dom('#empty .euiTreeView__iconWrapper', def).exists('useEmptyIcon keeps an empty wrapper');
    assert.dom('#empty .euiTreeView__iconWrapper .euiIcon', def).doesNotExist();
    assert.strictEqual(css('#empty .euiTreeView__iconWrapper', def).width, defIcon.width);

    assert.dom('#src .euiTreeView__expansionArrow', comp).exists();
    assert.dom('#readme .euiTreeView__expansionArrow', comp).doesNotExist();
    assert.strictEqual(css('#readme .euiTreeView__arrowPlaceholder', comp).width, `${parseFloat(light.size.l) / 2}px`, 'leaves keep the arrow space');
    assert.dom('.euiTreeView__expansionArrow', def).doesNotExist('no arrows by default');

    const label = css('#readme .euiTreeView__nodeLabel', def);
    assert.dom('#readme .euiTreeView__nodeLabel', def).hasClass('eui-textTruncate');
    assert.strictEqual(label.overflow, 'hidden');
    assert.strictEqual(label.textOverflow, 'ellipsis');
    assert.strictEqual(label.whiteSpace, 'nowrap');

    assert.dom('#src .euiTreeView__iconWrapper .euiIcon', def).hasAttribute('data-icon-type', 'folderOpen', 'iconWhenExpanded while open');
    assert.dom('#src .euiTreeView__iconWrapper .euiIcon', comp).hasAttribute('data-icon-type', 'folderClosed');
    await click(el('#src', comp));
    assert.dom('#src .euiTreeView__iconWrapper .euiIcon', comp).hasAttribute('data-icon-type', 'folderOpen');

    await focus(el('#readme', def));
    assert.strictEqual(css(el('#readme', def)).backgroundColor, rgb(light.components.treeViewItemBackgroundHover), 'focus background');
  });

  test('EuiTreeView expansion, aria, keyboard and reactive display without element replacement', async function (assert) {
    class State {
      @tracked display: 'default' | 'compressed' = 'default';
    }
    const state = new State();
    const items = treeItems();
    let calls = 0;
    items[2]!.callback = () => calls++;
    await render(<template><EuiTreeView @items={{items}} @display={{state.display}} aria-label="Files" /></template>);
    const root = this.element;
    const list = el('ul.euiTreeView', root);

    assert.dom(list).hasAttribute('role', 'list').hasAria('label', 'Files');
    const instructions = el(`#${list.getAttribute('aria-describedby')}`);
    assert.dom(instructions).hasText('You can quickly navigate this list using arrow keys.');
    assert.strictEqual(css(instructions.closest('.euiScreenReaderOnly') ?? instructions).position, 'absolute', 'instructions are screen reader only');
    assert.dom('#src').hasAria('expanded', 'false').hasAttribute('aria-controls');
    assert.dom('#readme').doesNotHaveAttribute('aria-expanded', 'leaves have no aria-expanded (upstream)');
    assert.dom('#readme').doesNotHaveAttribute('aria-controls');
    assert.dom('#readme').hasAttribute('type', 'button');
    assert.dom(`#${el('#src').getAttribute('aria-controls')}`).exists('controlled region exists');

    await click('#src');
    assert.dom('#src').hasAria('expanded', 'true').hasClass('euiTreeView__node--active');
    const nested = el('ul.euiTreeView', el('#src').parentElement!);
    assert.dom(nested).hasAria('labelledby', 'src').doesNotHaveAttribute('aria-describedby', 'only the root has instructions');
    assert.dom('#utils').hasAria('expanded', 'false');

    await click('#readme');
    assert.strictEqual(calls, 1, 'callback');

    el('#src').focus();
    await triggerKeyEvent('#src', 'keydown', 'ArrowDown');
    assert.dom('#index').isFocused();
    await triggerKeyEvent('#index', 'keydown', 'ArrowDown');
    assert.dom('#utils').isFocused();
    await triggerKeyEvent('#utils', 'keydown', 'ArrowRight');
    assert.dom('#dates').exists('arrow right opens');
    await triggerKeyEvent('#utils', 'keydown', 'ArrowUp');
    assert.dom('#index').isFocused();
    await triggerKeyEvent('#index', 'keydown', 'ArrowLeft');
    assert.dom('#src').isFocused('arrow left in children returns to the parent');
    await triggerKeyEvent('#src', 'keydown', 'ArrowLeft');
    assert.dom('#index').doesNotExist('arrow left closes');
    assert.dom('#src').hasAria('expanded', 'false');

    const button = el('#readme');
    assert.strictEqual(css(button).height, light.size.xl);
    state.display = 'compressed';
    await settled();
    assert.strictEqual(el('ul.euiTreeView', root), list, 'same list element');
    assert.strictEqual(el('#readme'), button, 'same button element');
    assert.strictEqual(css(button).height, light.size.l, 'compressed applied reactively');
  });

  test('EuiTextDiff: elements, colors, decorations, granularity and reactive text', async function (assert) {
    class State {
      @tracked after = 'The quick brown dog';
    }
    const state = new State();
    await render(
      <template>
        <EuiTextDiff @beforeText="The slow brown fox" @afterText={{state.after}} data-test="words" />
        <EuiTextDiff @beforeText="cat" @afterText="cut" @granularity="characters" data-test="chars" />
      </template>
    );
    const root = this.element;
    const words = el('[data-test="words"]', root);

    assert.strictEqual(words.tagName, 'SPAN');
    assert.dom(words).hasClass('euiTextDiff');
    assert.dom('del', words).exists({ count: 2 });
    assert.dom('ins', words).exists({ count: 2 });
    assert.strictEqual(css('del', words).color, rgb(light.colors.textDanger), 'deletions use textDanger');
    assert.strictEqual(css('ins', words).color, rgb(light.colors.textSuccess), 'insertions use textSuccess');
    assert.true(css('del', words).textDecorationLine.includes('line-through'));
    assert.true(css('ins', words).textDecorationLine.includes('underline'));
    assert.dom('[data-test="chars"] del').hasText('a');
    assert.dom('[data-test="chars"] ins').hasText('u');

    state.after = 'The slow brown fox';
    await settled();
    assert.strictEqual(el('[data-test="words"]', root), words, 'same root element');
    assert.dom('del, ins', words).doesNotExist('no changes');
    assert.dom(words).hasText('The slow brown fox');
  });

  test('EuiExpression: base, every color, active and focus colors, clickable button', async function (assert) {
    const noop = () => {};
    await render(
      <template>
        <EuiEmotionProvider>
          <div>
            {{#each COLORS as |color|}}
              <EuiExpression @description="when" @value="avg()" @color={{color}} data-color={{color}} />
            {{/each}}
          </div>
          <div>
            {{#each COLORS as |color|}}
              <EuiExpression
                @description="is"
                @value="above"
                @color={{color}}
                @isActive={{true}}
                @onClick={{noop}}
                data-active={{color}}
              />
            {{/each}}
          </div>
        </EuiEmotionProvider>
      </template>
    );
    const root = this.element;
    const base = css('[data-color="success"]', root);

    assert.strictEqual(base.display, 'inline-block');
    assert.strictEqual(base.fontFamily.replace(/"/g, "'"), light.font.familyCode.replace(/"/g, "'"), 'code font');
    assert.strictEqual(base.fontSize, px(euiFontSize(lightContext, 's').fontSize as string), 'font size s');
    assert.strictEqual(base.paddingTop, `${parseFloat(light.size.s) / 2}px`);
    assert.strictEqual(base.paddingLeft, '0px');
    assert.strictEqual(base.color, rgb(light.colors.textParagraph));
    assert.strictEqual(base.textAlign, 'start', 'logical start alignment');
    assert.strictEqual(base.overflowWrap, 'break-word', 'break-word text wrap by default');
    assert.strictEqual(css('[data-color="primary"]', root).marginLeft, light.size.s, 'adjacent expressions are spaced');
    assert.strictEqual(css('[data-color="subdued"]', root).marginLeft, '0px', 'the first one is not');
    assert.strictEqual(css('[data-color="success"] .euiExpression__description', root).textTransform, 'uppercase');
    assert.strictEqual(css('[data-color="success"] .euiExpression__value', root).color, rgb(light.colors.textParagraph));
    assert.dom('[data-color="success"]', root).doesNotHaveAttribute('type');

    for (const color of COLORS) {
      assert.strictEqual(
        css(`[data-color="${color}"] .euiExpression__description`, root).color,
        rgb(light.colors[TEXT_TOKEN[color]]),
        `${color} description`
      );
      const active = el(`[data-active="${color}"]`, root);
      assert.strictEqual(active.tagName, 'BUTTON');
      assert.dom(active).hasAttribute('type', 'button');
      assert.strictEqual(css(active).cursor, 'pointer');
      assert.strictEqual(css(active).borderBottomStyle, 'solid', `${color} active underline is solid`);
      assert.strictEqual(css(active).borderBottomColor, rgb(light.colors[BORDER_TOKEN[color]]), `${color} active border`);
      assert.strictEqual(css(active).borderTopStyle, 'none', 'button reset');
      await focus(active);
      assert.strictEqual(css(active).backgroundColor, rgb(transparentize(light.colors[TEXT_TOKEN[color]], 0.1)), `${color} focus background`);
    }
  });

  test('EuiExpression: clickable dashed border, invalid, columns, truncate, uppercase and reactive args', async function (assert) {
    class State {
      @tracked color: EuiExpressionColor = 'success';
      @tracked isActive = false;
      @tracked isInvalid = false;
      @tracked display: 'inline' | 'columns' = 'inline';
      @tracked textWrap: 'break-word' | 'truncate' = 'break-word';
      @tracked descriptionWidth: string | number | undefined = undefined;
      clicks = 0;
      onClick = () => this.clicks++;
    }
    const state = new State();
    await render(
      <template>
        <div style="width: 300px">
          <EuiExpression
            @description="when"
            @value="a very long value that will not fit in the space"
            @color={{state.color}}
            @isActive={{state.isActive}}
            @isInvalid={{state.isInvalid}}
            @display={{state.display}}
            @textWrap={{state.textWrap}}
            @descriptionWidth={{state.descriptionWidth}}
            @onClick={{state.onClick}}
            data-test="expr"
          />
          <EuiExpression @description="lower" @value="x" @uppercase={{false}} data-test="lower" />
        </div>
      </template>
    );
    const root = this.element;
    const expr = el('[data-test="expr"]', root);
    const description = () => css('.euiExpression__description', expr);
    const value = () => css('.euiExpression__value', expr);
    const [width, style] = light.border.editable.split(' ');

    assert.strictEqual(css(expr).borderBottomStyle, style, 'editable (dashed) border');
    assert.strictEqual(css(expr).borderBottomWidth, width);
    await click(expr);
    assert.strictEqual(state.clicks, 1);
    expr.blur();
    assert.strictEqual(css('[data-test="lower"] .euiExpression__description', root).textTransform, 'none');

    state.isActive = true;
    state.color = 'primary';
    await settled();
    assert.strictEqual(el('[data-test="expr"]', root), expr, 'same element');
    assert.strictEqual(css(expr).borderBottomStyle, 'solid');
    assert.strictEqual(css(expr).borderBottomColor, rgb(light.colors.primary));
    assert.strictEqual(description().color, rgb(light.colors.textPrimary));

    state.isInvalid = true;
    await settled();
    assert.strictEqual(description().color, rgb(light.colors.textDanger), 'invalid description is danger');
    assert.strictEqual(css(expr).borderBottomColor, rgb(light.colors.primary), 'the root keeps its color (upstream)');
    const icon = el('.euiExpression__icon', expr);
    assert.dom(icon).hasClass('euiIcon');
    assert.strictEqual(css(icon).marginLeft, light.size.xs, 'icon spacing through @css');
    assert.strictEqual(css(icon).marginTop, '0px');

    state.display = 'columns';
    await settled();
    assert.strictEqual(el('[data-test="expr"]', root), expr, 'same element in columns');
    assert.strictEqual(css(expr).display, 'flex');
    assert.strictEqual(css(expr).width, '300px');
    assert.strictEqual(css(expr).paddingTop, light.size.xs);
    assert.strictEqual(css(expr).paddingLeft, light.size.xs);
    assert.strictEqual(css(expr).marginBottom, light.size.xs);
    assert.strictEqual(css(expr).backgroundColor, rgb(light.colors.lightestShade), 'clickable columns background');
    assert.strictEqual(css(expr).borderBottomColor, 'rgba(0, 0, 0, 0)', 'columns hide the border outside high contrast');
    assert.strictEqual(css(expr).borderTopLeftRadius, light.size.xs);
    assert.strictEqual(description().textAlign, 'end');
    assert.strictEqual(description().marginRight, light.size.s);
    assert.strictEqual(description().flexShrink, '0');
    assert.strictEqual(description().flexBasis, '20%', 'default description width');
    assert.strictEqual(value().flexGrow, '1');
    assert.strictEqual(css(icon).marginTop, light.size.xs, 'columns icon offset');

    state.descriptionWidth = 120;
    await settled();
    assert.strictEqual(description().flexBasis, '120px', 'numbers are px');
    state.descriptionWidth = '30%';
    await settled();
    assert.strictEqual(description().flexBasis, '30%');

    await focus(expr);
    assert.strictEqual(value().textDecorationLine, 'underline', 'focused clickable columns underline the value');

    state.display = 'inline';
    state.textWrap = 'truncate';
    await settled();
    assert.strictEqual(css(expr).maxWidth, '100%');
    assert.strictEqual(value().overflow, 'hidden');
    assert.strictEqual(value().textOverflow, 'ellipsis');
    assert.strictEqual(value().whiteSpace, 'nowrap');
    assert.strictEqual(value().display, 'inline-block');
    assert.strictEqual(description().textOverflow, 'ellipsis');
    assert.strictEqual(description().flexBasis, 'auto', 'no width outside columns');
  });

  test('EuiTourStep: popover panel, header, content, footer, width and beacon', async function (assert) {
    class State {
      @tracked minWidth = 300;
      @tracked maxWidth = 600;
    }
    const state = new State();
    let finished = 0;
    const onFinish = () => finished++;
    await render(
      <template>
        <div style="padding: 320px 0 0 360px">
          <EuiTourStep
            @isStepOpen={{true}}
            @step={{2}}
            @stepsTotal={{3}}
            @title="Welcome"
            @subtitle="Tour"
            @content="This is the search."
            @anchorPosition="upCenter"
            @minWidth={{state.minWidth}}
            @maxWidth={{state.maxWidth}}
            @onFinish={{onFinish}}
            data-test="step"
          >
            <button type="button" class="anchor">Search</button>
          </EuiTourStep>
        </div>
      </template>
    );
    await tourOpened();
    const panel = tourPanel()!;

    assert.dom('[data-test="step"]').hasClass('euiTourAnchor').hasClass('euiPopover');
    assert.dom(panel).hasClass('euiPopover__panel').hasAttribute('role', 'dialog');
    const header = el('.euiTourHeader', panel);
    assert.dom(panel).hasAria('labelledby', header.id);
    assert.dom(header).hasClass('euiPopoverTitle');
    assert.strictEqual(css(header).borderBottomStyle, 'none', 'tour header has no border');
    assert.strictEqual(css(header).marginBottom, light.size.s);
    assert.strictEqual(css(header).paddingTop, panelM, 'panel padding m');
    assert.strictEqual(css(header).marginTop, `-${panelM}`, 'covers the panel padding');
    const subtitle = el('.euiTourHeader__subtitle', panel);
    const title = el('.euiTourHeader__title', panel);
    assert.strictEqual(subtitle.tagName, 'H2');
    assert.strictEqual(title.tagName, 'H3', 'title is h3 under a subtitle');
    assert.strictEqual(css(subtitle).color, rgb(light.colors.textSubdued));
    assert.strictEqual(css(subtitle).paddingBottom, light.size.xs);
    assert.strictEqual(css(title).marginTop, '0px');
    assert.strictEqual(css(title).color, rgb(light.colors.textHeading));
    assert.true(parseFloat(css(subtitle).fontSize) < parseFloat(css(title).fontSize), 'xxxs subtitle, xxs title');
    assert.dom('.euiTour__content', panel).hasText('This is the search.');

    const widths = el('.euiTourHeader', panel).parentElement!;
    assert.strictEqual(css(widths).minWidth, '300px');
    assert.strictEqual(css(widths).maxWidth, '600px');
    state.minWidth = 360;
    state.maxWidth = 400;
    await settled();
    assert.strictEqual(tourPanel(), panel, 'same panel');
    assert.strictEqual(css(widths).minWidth, '360px');
    assert.strictEqual(css(widths).maxWidth, '400px');

    const footer = el('.euiTourFooter', panel);
    assert.dom(footer).hasClass('euiPopoverFooter');
    assert.strictEqual(css(footer).backgroundColor, rgb(light.components.tourFooterBackground));
    assert.strictEqual(css(footer).borderBottomLeftRadius, light.border.radius.panel);
    assert.strictEqual(css(footer).borderBottomRightRadius, light.border.radius.panel);
    assert.strictEqual(css(footer).paddingTop, panelM);
    assert.strictEqual(css(footer).marginBottom, `-${panelM}`);
    const list = el('.euiTourFooter__stepList', panel);
    assert.strictEqual(css(list).listStyleType, 'none');
    assert.strictEqual(css(list).paddingLeft, '0px');
    const indicators = [...list.querySelectorAll<HTMLElement>('.euiTourStepIndicator')];
    assert.deepEqual(
      indicators.map((li) => li.getAttribute('aria-label')),
      ['Step 1 complete', 'Step 2 active', 'Step 3 incomplete']
    );
    assert.strictEqual(css(indicators[0]!).display, 'inline-block');
    assert.strictEqual(css(el('.euiIcon', indicators[1]!)).color, rgb(light.components.tourStepIndicatorActiveColor), 'active dot');
    assert.strictEqual(css(el('.euiIcon', indicators[2]!)).color, rgb(light.components.tourStepIndicatorInactiveColor), 'inactive dot');
    assert.dom(el('.euiIcon', indicators[1]!)).hasAttribute('aria-current', 'step');
    const finish = el('.euiButtonEmpty', footer);
    assert.dom(finish).hasText('Skip tour');
    await click(finish);
    assert.strictEqual(finished, 1);

    const arrow = el('[data-popover-arrow]', panel);
    assert.strictEqual(arrow.dataset['popoverArrow'], 'top', 'the popover opened above');
    assert.strictEqual(css(arrow).backgroundColor, rgb(light.components.tourFooterBackground), 'arrow matches the footer below it');
    const beaconWrapper = el('.euiTour__beaconWrapper', panel);
    assert.dom('.euiTour__beacon.euiBeacon', beaconWrapper).exists();
    assert.strictEqual(beaconWrapper.previousElementSibling, arrow);
    const beacon = css(beaconWrapper);
    assert.strictEqual(beacon.position, 'absolute');
    assert.strictEqual(beacon.pointerEvents, 'none');
    assert.strictEqual(beacon.zIndex, '1');
    assert.strictEqual(beacon.marginLeft, `-${parseFloat(light.size.m) / 2}px`, 'top: centered horizontally');
    assert.strictEqual(beacon.marginTop, '0px');
    assert.strictEqual(beacon.opacity, '1', 'visible while open');
    if (canAnimate()) {
      assert.strictEqual(beacon.transitionProperty, 'opacity', 'fades in after the panel (euiCanAnimate)');
      assert.notStrictEqual(beacon.transitionDelay, '0s');
    } else {
      assert.strictEqual(beacon.transitionDuration, '0s', 'reduced motion: no transition');
    }
  });

  test('EuiTourStep beacon positions, decoration none and single-step footer', async function (assert) {
    const noop = () => {};
    await render(
      <template>
        <div style="padding: 120px 0 0 420px">
          <EuiTourStep @isStepOpen={{true}} @title="Left" @content="c" @closePopover={{noop}} data-test="left">
            <button type="button">Left</button>
          </EuiTourStep>
        </div>
      </template>
    );
    await tourOpened();
    let panel = tourPanel()!;
    assert.strictEqual(el('[data-popover-arrow]', panel).dataset['popoverArrow'], 'left', 'default anchorPosition leftUp');
    const beacon = css(el('.euiTour__beaconWrapper', panel));
    assert.strictEqual(beacon.marginTop, `-${parseFloat(light.size.m) / 2}px`, 'left: centered vertically');
    assert.strictEqual(beacon.marginLeft, '0px');
    assert.notStrictEqual(css(el('[data-popover-arrow]', panel)).backgroundColor, rgb(light.components.tourFooterBackground), 'only the top arrow takes the footer color');
    assert.dom('.euiTourFooter__stepList', panel).doesNotExist('one step has no progress');
    assert.dom('.euiTourFooter .euiButtonEmpty', panel).hasText('Close tour');
    assert.strictEqual(el('.euiTourHeader__title', panel).tagName, 'H2', 'title is h2 without a subtitle');
    assert.dom('.euiTourHeader__subtitle', panel).doesNotExist();

    await render(
      <template>
        <div style="padding: 120px 0 0 420px">
          <EuiTourStep @isStepOpen={{true}} @title="Plain" @content="c" @decoration="none" @closePopover={{noop}}>
            <button type="button">Plain</button>
          </EuiTourStep>
        </div>
      </template>
    );
    await tourOpened();
    panel = tourPanel()!;
    assert.dom('.euiTour__beacon', panel).doesNotExist('no beacon');
    assert.dom('.euiPopover__arrow', panel).doesNotExist('no arrow without the beacon');
  });

  test('EuiTour drives the steps; footer actions, i18n labels and indicators', async function (assert) {
    const initialState = { currentTourStep: 1, isTourActive: true, tourPopoverWidth: 320, tourSubtitle: 'Demo' };
    const steps = [
      { step: 1, title: 'First', content: 'One' },
      { step: 2, title: 'Second', content: 'Two' }
    ];
    await render(
      <template>
        <div style="padding: 120px 0 0 420px">
          <EuiTour @initialState={{initialState}} @steps={{steps}} as |tour|>
            <tour.Step @step={{1}}><button type="button">A</button></tour.Step>
            <tour.Step @step={{2}}><button type="button">B</button></tour.Step>
            <button type="button" class="go" {{on "click" (fn tour.actions.goToStep 2)}}>go</button>
          </EuiTour>
        </div>
      </template>
    );
    await tourOpened();
    let panel = tourPanel()!;
    assert.dom('.euiTourHeader__title', panel).hasText('First');
    assert.strictEqual(css(el('.euiTourHeader', panel).parentElement!).minWidth, '320px', 'tourPopoverWidth');
    assert.dom('.euiTourFooter .euiButtonEmpty', panel).hasText('Skip tour');
    assert.dom('.euiTourStepIndicator', panel).exists({ count: 2 });

    await click('.go');
    await waitUntil(() => tourPanel()?.querySelector('.euiTourHeader__title')?.textContent?.includes('Second'));
    panel = tourPanel()!;
    assert.dom('.euiTourFooter .euiButtonEmpty', panel).hasText('End tour');
    assert.dom('.euiTourStepIndicator', panel).hasAria('label', 'Step 1 complete');
  });

  test('light/dark nearest provider and sibling isolation', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'dark';
    }
    const state = new State();
    const items = treeItems();
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}}>
          <EuiTextDiff @beforeText="a b" @afterText="a c" data-test="dark-diff" />
          <EuiExpression @description="when" @value="x" @color="primary" data-test="dark-expr" />
          <EuiTreeView @items={{items}} aria-label="Dark" data-test="dark-tree" />
          <ul><EuiTourStepIndicator @number={{1}} @status="active" data-test="dark-dot" /></ul>
          <EuiEmotionProvider @colorMode="light">
            <EuiExpression @description="when" @value="x" @color="primary" data-test="nested-expr" />
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiTextDiff @beforeText="a b" @afterText="a c" data-test="sibling-diff" />
        </EuiEmotionProvider>
      </template>
    );
    const root = this.element;
    assert.strictEqual(css('[data-test="dark-diff"] del', root).color, rgb(dark.colors.textDanger));
    assert.strictEqual(css('[data-test="dark-diff"] ins', root).color, rgb(dark.colors.textSuccess));
    assert.strictEqual(css('[data-test="dark-expr"] .euiExpression__description', root).color, rgb(dark.colors.textPrimary));
    assert.strictEqual(css('[data-test="dark-expr"]', root).color, rgb(dark.colors.textParagraph));
    assert.strictEqual(css('[data-test="dark-dot"] .euiIcon', root).color, rgb(dark.components.tourStepIndicatorActiveColor));
    assert.strictEqual(css('[data-test="nested-expr"] .euiExpression__description', root).color, rgb(light.colors.textPrimary), 'nested light');
    assert.strictEqual(css('[data-test="sibling-diff"] del', root).color, rgb(light.colors.textDanger), 'sibling light');
    assert.notStrictEqual(rgb(dark.colors.textDanger), rgb(light.colors.textDanger));

    await focus(el('#readme', root));
    assert.strictEqual(css(el('#readme', root)).backgroundColor, rgb(dark.components.treeViewItemBackgroundHover));

    state.mode = 'light';
    await settled();
    assert.strictEqual(css('[data-test="dark-diff"] del', root).color, rgb(light.colors.textDanger), 'switched to light');
    assert.strictEqual(css('[data-test="dark-expr"] .euiExpression__description', root).color, rgb(light.colors.textPrimary));
  });

  test('dark tour footer and arrow', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider @colorMode="dark">
          <div style="padding: 320px 0 0 360px">
            <EuiTourStep @isStepOpen={{true}} @title="Dark" @content="c" @anchorPosition="upCenter">
              <button type="button">Dark</button>
            </EuiTourStep>
          </div>
        </EuiEmotionProvider>
      </template>
    );
    await tourOpened();
    const panel = tourPanel()!;
    assert.strictEqual(css(el('.euiTourFooter', panel)).backgroundColor, rgb(dark.components.tourFooterBackground));
    assert.strictEqual(css(el('.euiTourHeader__title', panel)).color, rgb(dark.colors.textHeading));
    assert.strictEqual(css(el('[data-popover-arrow="top"]', panel)).backgroundColor, rgb(dark.components.tourFooterBackground));
  });

  test('native token overrides (JS objects) and high contrast', async function (assert) {
    class State {
      @tracked overrides: EuiBorealisOverrides = {};
      @tracked contrast: EuiBorealisHighContrastMode = false;
    }
    const state = new State();
    const items = treeItems();
    const noop = () => {};
    await render(
      <template>
        <EuiEmotionProvider @borealisOverrides={{state.overrides}} @highContrastMode={{state.contrast}}>
          <EuiTextDiff @beforeText="a b" @afterText="a c" data-test="diff" />
          <EuiExpression @description="when" @value="x" @display="columns" @onClick={{noop}} data-test="columns" />
          <EuiTreeView @items={{items}} aria-label="Tree" data-test="tree" />
        </EuiEmotionProvider>
        <EuiTextDiff @beforeText="a b" @afterText="a c" data-test="outside" />
      </template>
    );
    const root = this.element;
    state.overrides = {
      colors: { LIGHT: { textDanger: '#663399' } },
      size: { s: '10px' }
    };
    await settled();
    const overridden = resolveBorealisTheme('light', state.overrides).euiTheme;
    assert.strictEqual(css('[data-test="diff"] del', root).color, rgb(overridden.colors.textDanger), 'color override');
    assert.notStrictEqual(rgb(overridden.colors.textDanger), rgb(light.colors.textDanger));
    assert.strictEqual(css(el('#readme', root)).columnGap, '10px', 'size override reaches the tree');
    assert.strictEqual(css(el('#readme', root)).paddingLeft, '10px');
    assert.strictEqual(css('[data-test="outside"] del', root).color, rgb(light.colors.textDanger), 'outside is isolated');

    assert.strictEqual(css('[data-test="columns"]', root).borderBottomColor, 'rgba(0, 0, 0, 0)');
    state.overrides = {};
    state.contrast = 'preferred';
    await settled();
    const hc = resolveBorealisTheme('light', {}, 'preferred').euiTheme;
    const columns = css('[data-test="columns"]', root);
    assert.notStrictEqual(columns.borderBottomColor, 'rgba(0, 0, 0, 0)', 'high contrast shows the columns border');
    assert.strictEqual(columns.borderBottomColor, rgb(hc.border.editable.split(' ').slice(2).join(' ')));
    assert.strictEqual(columns.borderTopLeftRadius, '0px');
  });

  test('RTL: tree indentation, expression spacing and columns are logical', async function (assert) {
    const items = treeItems();
    await render(
      <template>
        <div dir="rtl">
          <EuiTreeView @items={{items}} @expandByDefault={{true}} aria-label="עץ" data-test="tree" />
          <EuiExpression @description="a" @value="b" />
          <EuiExpression @description="c" @value="d" data-test="second" />
          <EuiExpression @description="e" @value="f" @display="columns" @isInvalid={{true}} data-test="columns" />
        </div>
      </template>
    );
    const root = this.element;
    const nested = css('ul.euiTreeView', el('#src', root).parentElement!);
    assert.strictEqual(nested.paddingRight, light.size.l, 'nested indent at the inline start');
    assert.strictEqual(nested.paddingLeft, '0px');
    const button = css(el('#readme', root));
    assert.strictEqual(button.paddingRight, light.size.s);
    assert.strictEqual(button.paddingLeft, light.size.xxs);
    assert.strictEqual(css('[data-test="second"]', root).marginRight, light.size.s, 'sibling spacing flips');
    const description = css('[data-test="columns"] .euiExpression__description', root);
    assert.strictEqual(description.marginLeft, light.size.s);
    assert.strictEqual(description.textAlign, 'end');
    assert.strictEqual(css('[data-test="columns"] .euiExpression__icon', root).marginRight, light.size.xs);
  });
});
