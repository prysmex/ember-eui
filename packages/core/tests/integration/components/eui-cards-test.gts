import { tracked } from '@glimmer/tracking';
import { array, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import {
  clearRender,
  click,
  focus,
  render,
  settled
} from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import EuiBetaBadge from '#src/components/eui-beta-badge.gts';
import EuiButton from '#src/components/eui-button.gts';
import EuiCard from '#src/components/eui-card.gts';
import EuiCardSelect from '#src/components/eui-card-select.gts';
import EuiCheckableCard from '#src/components/eui-checkable-card.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiPanel from '#src/components/eui-panel.gts';
import EuiSplitPanelInner from '#src/components/eui-split-panel/inner.gts';
import EuiSplitPanelOuter from '#src/components/eui-split-panel/outer.gts';
import EuiTitle from '#src/components/eui-title.gts';
import {
  euiBackgroundColor,
  euiPaddingSize
} from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiCardSignature } from '#src/components/eui-card.gts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type {
  EuiBorealisHighContrastMode,
  EuiBorealisOverrides
} from '#src/utils/eui/theme.ts';

const lightContext = resolveBorealisTheme('light');
const darkContext = resolveBorealisTheme('dark');
const light = lightContext.euiTheme;

type Padding = NonNullable<EuiCardSignature['Args']['paddingSize']>;
type Display = NonNullable<EuiCardSignature['Args']['display']>;

const PADDINGS: Padding[] = ['none', 's', 'm', 'l'];
const DISPLAYS: Display[] = [
  'plain',
  'subdued',
  'transparent',
  'accent',
  'primary',
  'success',
  'warning',
  'danger'
];

function el<T extends HTMLElement = HTMLElement>(
  root: Element | Document,
  selector: string
): T {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function style(root: Element, selector: string, pseudo?: string) {
  return getComputedStyle(el(root, selector), pseudo);
}

/** Normalize any CSS color to the browser's computed `rgb()` form. */
function rgb(color: string): string {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

function px(value: string): number {
  return parseFloat(value);
}

function padding(size: Padding): string {
  return euiPaddingSize(lightContext, size) ?? '0px';
}

/** CSS text of every rule (including Emotion's inserted ones). */
function allCss(): string {
  return Array.from(document.styleSheets)
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
}

/**
 * Copies the rendered markup and every stylesheet rule into an iframe of the
 * given width, so media queries are evaluated against a real narrow
 * viewport (the testem window is 1440px and cannot be resized).
 */
function inViewport(width: number, html: string) {
  const iframe = document.createElement('iframe');
  iframe.style.cssText = `position:fixed;top:0;left:0;width:${width}px;height:800px;border:0;visibility:hidden`;
  document.body.appendChild(iframe);
  const doc = iframe.contentDocument!;
  doc.open();
  doc.write(
    `<!doctype html><html><head><style>${allCss()}</style></head><body style="margin:0">${html}</body></html>`
  );
  doc.close();
  const win = iframe.contentWindow!;
  return {
    style: (selector: string) => win.getComputedStyle(el(doc, selector)),
    remove: () => iframe.remove()
  };
}

const noop = () => {};

/** The checkable card animates its border color; jump to the end state. */
function finishTransitions(): void {
  for (const animation of document.getAnimations()) animation.finish();
}

/**
 * Upstream's clickable panel slot only sets `cursor`/shadow on hover and
 * focus, which synthetic events cannot trigger; its Emotion label is in the
 * generated class name.
 */
function isClickableSlot(element: Element): boolean {
  return element.className.includes('-isClickable');
}

module('Integration | Component | Borealis cards', function (hooks) {
  setupRenderingTest(hooks);

  // ------------------------------------------------------------------ Card

  test('card defaults: plain panel with shadow and no border, centered vertical layout', async function (assert) {
    await render(
      <template>
        <EuiCard
          @title="Title"
          @description="Description"
          data-card
          aria-label="Card"
          class="custom"
        />
        <EuiTitle @size="s" @tagName="p" data-reference>Ref</EuiTitle>
      </template>
    );
    const card = el(this.element, '[data-card]');
    const computed = getComputedStyle(card);
    assert
      .dom(card)
      .hasClass('euiCard')
      .hasClass('euiPanelBorealis')
      .hasClass('custom')
      .hasAttribute('aria-label', 'Card')
      .doesNotHaveAttribute('role', 'the card is not a control itself')
      .doesNotHaveAttribute('tabindex');
    assert.strictEqual(
      computed.backgroundColor,
      rgb(euiBackgroundColor(lightContext, 'plain'))
    );
    assert.notStrictEqual(computed.boxShadow, 'none', 'upstream hasShadow');
    assert.strictEqual(
      getComputedStyle(card, '::after').content,
      'none',
      'hasBorder=false: no pseudo border'
    );
    assert.strictEqual(computed.paddingTop, padding('m'));
    assert.strictEqual(computed.borderRadius, light.border.radius.panel);
    assert.strictEqual(computed.display, 'flex');
    assert.strictEqual(computed.flexDirection, 'column');
    assert.strictEqual(computed.alignItems, 'center');
    assert.strictEqual(computed.textAlign, 'center');

    const main = style(card, '.euiCard__main');
    assert.strictEqual(main.display, 'flex');
    assert.strictEqual(main.flexDirection, 'column');

    // Upstream title: `<p class="euiTitle euiCard__title">` with title size s.
    assert.dom('.euiCard__title', card).hasTagName('p').hasClass('euiTitle');
    const title = style(card, '.euiCard__title');
    const reference = style(this.element, '[data-reference]');
    assert.strictEqual(title.fontSize, reference.fontSize);
    assert.strictEqual(title.fontWeight, reference.fontWeight);
    assert.strictEqual(title.marginTop, '0px');
    assert
      .dom('.euiCard__title span', card)
      .hasText('Title', 'non-interactive title text');

    const description = el(card, '.euiCard__description');
    assert.dom(description).hasClass('euiText').hasText('Description');
    assert.strictEqual(
      getComputedStyle(description).marginTop,
      padding('s'),
      'upstream half spacing above the description'
    );
    assert.strictEqual(
      el(card, '.euiCard__title').id.replace(/Title$/, 'Description'),
      description.id,
      'title and description share the card id'
    );
    assert.dom('.euiCard__footer, .euiCard__top, .euiCardSelect', card).doesNotExist();
  });

  test('card text alignment, RTL logical alignment and the horizontal layout', async function (assert) {
    await render(
      <template>
        <div dir="ltr">
          <EuiCard @title="L" @textAlign="left" data-left />
          <EuiCard @title="C" @textAlign="center" data-center />
          <EuiCard @title="R" @textAlign="right" data-right />
        </div>
        <div dir="rtl" style="width: 600px">
          <EuiCard @title="RTL start" @textAlign="left" data-rtl />
        </div>
        <EuiCard
          @title="Horizontal"
          @description="d"
          @layout="horizontal"
          @icon="logoElastic"
          @image="data:image/gif;base64,R0lGODlhAQABAAAAACw="
          @footer="ignored"
          @textAlign="center"
          data-horizontal
        />
      </template>
    );
    const cases: [string, string, string][] = [
      ['[data-left]', 'start', 'flex-start'],
      ['[data-center]', 'center', 'center'],
      ['[data-right]', 'end', 'flex-end']
    ];
    for (const [selector, textAlign, alignItems] of cases) {
      const computed = style(this.element, selector);
      assert.strictEqual(computed.textAlign, textAlign, `${selector} text`);
      assert.strictEqual(computed.alignItems, alignItems, `${selector} items`);
      assert.strictEqual(
        style(this.element, `${selector} .euiCard__title span`).textAlign,
        textAlign,
        `${selector} title text`
      );
    }

    const rtl = el(this.element, '[data-rtl]');
    const rtlTitle = el(rtl, '.euiCard__title span');
    assert.strictEqual(getComputedStyle(rtl).textAlign, 'start');
    assert.true(
      rtlTitle.getBoundingClientRect().right >
        el(rtl, '.euiCard__content').getBoundingClientRect().right - 2,
      '`left` is logical: the title hugs the right edge in RTL'
    );

    const horizontal = el(this.element, '[data-horizontal]');
    assert.strictEqual(
      getComputedStyle(horizontal).textAlign,
      'start',
      'horizontal cards ignore textAlign'
    );
    assert.strictEqual(style(horizontal, '.euiCard__main').flexDirection, 'row');
    assert.strictEqual(style(horizontal, '.euiCard__main').alignItems, 'flex-start');
    assert.dom('.euiCard__image', horizontal).doesNotExist('no image');
    assert.dom('.euiCard__footer', horizontal).doesNotExist('no footer');
    const icon = style(horizontal, '.euiCard__icon');
    assert.strictEqual(icon.marginInlineEnd, padding('m'), 'icon gap');
    assert.strictEqual(icon.marginTop, '0px');
    const top = el(horizontal, '.euiCard__top');
    const content = el(horizontal, '.euiCard__content');
    assert.true(
      top.getBoundingClientRect().right <= content.getBoundingClientRect().left + 1,
      'icon sits before the content'
    );
  });

  test('card padding sizes drive padding, image bleed, footer spacing and beta badge offset', async function (assert) {
    const image =
      'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="20" height="10"/>';
    await render(
      <template>
        {{#each PADDINGS as |size|}}
          <div style="width: 300px">
            <EuiCard
              @title="T"
              @image={{image}}
              @icon="logoElastic"
              @footer="F"
              @paddingSize={{size}}
              @betaBadgeProps={{hash label="Beta"}}
              data-padding={{size}}
            />
          </div>
        {{/each}}
      </template>
    );
    for (const size of PADDINGS) {
      const card = el(this.element, `[data-padding="${size}"]`);
      const amount = padding(size);
      const computed = getComputedStyle(card);
      assert.strictEqual(computed.paddingInlineStart, amount, `${size} padding`);
      // Upstream computes `calc(<padding> + size.s)`; for `none` the
      // padding is null, so the declaration is invalid and drops out.
      assert.strictEqual(
        computed.paddingTop,
        size === 'none' ? '0px' : `${px(amount) + px(light.size.s)}px`,
        `${size}: beta badge adds size.s above the content`
      );
      const imageBox = el(card, '.euiCard__image');
      assert.strictEqual(
        imageBox.offsetWidth,
        card.clientWidth,
        `${size}: image bleeds to the card edges`
      );
      assert.strictEqual(
        getComputedStyle(imageBox).insetInlineStart,
        `${-px(amount)}px`
      );
      assert.strictEqual(
        style(card, '.euiCard__top').marginBottom,
        padding('m'),
        'top spacing is always m'
      );
      assert.strictEqual(
        style(card, '.euiCard__footer').marginTop,
        padding('m'),
        'footer spacing is always m'
      );
      assert.strictEqual(
        style(card, '.euiCard__icon').position,
        'absolute',
        'icon overlays the image'
      );
    }
  });

  test('card display colors: background, no shadow, no border; transparent image radius', async function (assert) {
    const image =
      'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="20" height="10"/>';
    await render(
      <template>
        {{#each DISPLAYS as |display|}}
          <EuiCard @title="T" @display={{display}} data-display={{display}} />
          <EuiPanel @color={{display}} data-panel={{display}} />
        {{/each}}
        <EuiCard @title="T" @display="transparent" @image={{image}} data-image />
      </template>
    );
    for (const display of DISPLAYS) {
      const card = style(this.element, `[data-display="${display}"]`);
      assert.strictEqual(
        card.backgroundColor,
        style(this.element, `[data-panel="${display}"]`).backgroundColor,
        `${display}: panel background`
      );
      assert.strictEqual(
        card.backgroundColor,
        rgb(euiBackgroundColor(lightContext, display)),
        `${display}: Borealis token`
      );
      assert.strictEqual(card.boxShadow, 'none', `${display}: no shadow`);
      assert.strictEqual(
        style(this.element, `[data-display="${display}"]`, '::after').content,
        'none',
        `${display}: no border`
      );
    }
    assert.strictEqual(
      style(this.element, '[data-image] .euiCard__image').borderTopLeftRadius,
      light.border.radius.panel,
      'transparent cards round the whole image'
    );
  });

  test('disabled card: subdued disabled surface, disabled button title, grayscale top, subdued badge', async function (assert) {
    let calls = 0;
    const onClick = () => calls++;
    await render(
      <template>
        <EuiCard
          @title="Off"
          @description="d"
          @icon="logoElastic"
          @isDisabled={{true}}
          @href="https://example.com"
          @onClick={{onClick}}
          @betaBadgeProps={{hash label="Beta"}}
          data-disabled
        />
        {{! upstream validateHref: javascript: links disable the card }}
        <EuiCard @title="JS" @href="javascript:alert(1)" data-js />
        <EuiButton @isDisabled={{true}} data-disabled-button>x</EuiButton>
      </template>
    );
    const card = el(this.element, '[data-disabled]');
    const computed = getComputedStyle(card);
    const button = style(this.element, '[data-disabled-button]');
    assert.strictEqual(computed.backgroundColor, button.backgroundColor);
    assert.strictEqual(computed.cursor, 'not-allowed');
    assert.strictEqual(computed.boxShadow, 'none');
    assert.dom('a', card).doesNotExist('no link while disabled');
    assert
      .dom('button.euiCard__titleButton', card)
      .isDisabled()
      .hasText('Off');
    assert.strictEqual(
      style(card, '.euiCard__titleButton').color,
      rgb(light.colors.disabledText)
    );
    assert.strictEqual(style(card, '.euiCard__top').filter, 'grayscale(1)');
    const badge = el(card, '.euiCard__betaBadge');
    assert.strictEqual(
      el(card, '.euiCard__titleButton').getAttribute('aria-describedby'),
      `${badge.id} ${el(card, '.euiCard__description').id}`,
      'button described by the badge and description'
    );
    assert.notStrictEqual(
      getComputedStyle(badge).backgroundColor,
      'rgba(0, 0, 0, 0)',
      'subdued (filled) badge instead of hollow'
    );
    await click(card);
    assert.strictEqual(calls, 0, 'no forwarded click');

    assert.dom('[data-js] a').doesNotExist();
    assert.dom('[data-js] button.euiCard__titleButton').isDisabled();
  });

  test('clickable card: surface clicks forward to the title link/button, nested controls keep theirs', async function (assert) {
    const events: string[] = [];
    const onClick = (event: MouseEvent) => {
      events.push(`title:${(event.target as Element).tagName}`);
    };
    const nested = () => events.push('nested');
    const preventNavigation = (event: Event) => {
      event.preventDefault();
      events.push('link');
    };
    await render(
      <template>
        <EuiCard @title="Button" @onClick={{onClick}} data-button-card>
          <:body>
            <p data-text>Plain text</p>
            <button type="button" data-nested {{on "click" nested}}>Nested</button>
          </:body>
        </EuiCard>
        <EuiCard
          @title="Link"
          @href="#card-link"
          @target="_blank"
          @rel="external"
          @description="desc"
          data-link-card
          {{on "click" preventNavigation}}
        />
        <EuiCard @title="Static" data-static />
      </template>
    );
    const buttonCard = el(this.element, '[data-button-card]');
    assert.true(isClickableSlot(buttonCard), 'clickable panel slot (hover cursor/shadow)');
    assert.dom('button.euiCard__titleButton', buttonCard).hasAttribute('type', 'button');

    await click(el(buttonCard, '.euiCard__main'));
    assert.deepEqual(events, ['title:BUTTON'], 'surface click forwarded once');
    events.length = 0;

    await click(el(buttonCard, '.euiCard__titleButton'));
    assert.deepEqual(events, ['title:BUTTON'], 'direct click is not doubled');
    events.length = 0;

    await click(el(buttonCard, '[data-text]'));
    assert.deepEqual(events, ['title:BUTTON'], 'non-interactive content forwards');
    events.length = 0;

    await click(el(buttonCard, '[data-nested]'));
    assert.deepEqual(events, ['nested'], 'nested controls are not forwarded');
    events.length = 0;

    (document.activeElement as HTMLElement | null)?.blur();
    assert.strictEqual(
      style(buttonCard, '.euiCard__titleButton').textDecorationLine,
      'none',
      'no underline at rest'
    );
    // Keyboard: the title button is the focusable control.
    await focus(el(buttonCard, '.euiCard__titleButton'));
    assert.strictEqual(document.activeElement, el(buttonCard, '.euiCard__titleButton'));
    assert.strictEqual(
      style(buttonCard, '.euiCard__titleButton').textDecorationLine,
      'underline',
      'interactive title underlines on focus (upstream)'
    );
    assert.true(
      allCss().includes("[class*=\"euiCard__text\"][class*=\"-interactive\"]:focus:focus-visible"),
      'focus-visible title rings the card (upstream :has rule)'
    );
    assert.true(
      el(buttonCard, '.euiCard__titleButton').className.includes('-interactive'),
      'interactive title class carries the upstream label the rule matches'
    );

    const linkCard = el(this.element, '[data-link-card]');
    const anchor = el<HTMLAnchorElement>(linkCard, 'a.euiCard__titleAnchor');
    assert
      .dom(anchor)
      .hasAttribute('href', '#card-link')
      .hasAttribute('target', '_blank')
      .hasAttribute('rel', 'external noopener noreferrer')
      .hasAttribute('aria-describedby', el(linkCard, '.euiCard__description').id);
    await click(el(linkCard, '.euiCard__description'));
    assert.deepEqual(events, ['link', 'link'], 'link click bubbles once through the card');

    const staticCard = el(this.element, '[data-static]');
    assert.dom('a, button', staticCard).doesNotExist();
    assert.false(isClickableSlot(staticCard));
  });

  test('selectable card: full-width switch, states, aria and surface toggle', async function (assert) {
    class State {
      @tracked isSelected = false;
      @tracked isDisabled = false;
    }
    const state = new State();
    const toggle = () => (state.isSelected = !state.isSelected);
    await render(
      <template>
        <EuiCard
          @title="Pick"
          @description="d"
          @paddingSize="l"
          @selectable={{hash
            onClick=toggle
            isSelected=state.isSelected
            isDisabled=state.isDisabled
          }}
          data-card
        />
        <EuiButton @color="success" data-success>x</EuiButton>
        <EuiButton @color="text" data-text>x</EuiButton>
        <EuiCard @title="Off" @isDisabled={{true}} @selectable={{hash onClick=noop}} data-disabled />
      </template>
    );
    const card = el(this.element, '[data-card]');
    const select = el<HTMLButtonElement>(card, '.euiCardSelect');
    const titleId = el(card, '.euiCard__title').id;
    const descId = el(card, '.euiCard__description').id;
    assert
      .dom(select)
      .hasTagName('button')
      .hasAttribute('role', 'switch')
      .hasAttribute('aria-checked', 'false')
      .hasAttribute('aria-describedby', `${titleId} ${descId}`)
      .hasText('Select');
    assert.strictEqual(select.offsetWidth, el(card, '.euiCard__main').offsetWidth, 'full width');
    assert.strictEqual(
      getComputedStyle(select).backgroundColor,
      style(this.element, '[data-text]').backgroundColor,
      'text color when idle'
    );
    const spacer = select.previousElementSibling as HTMLElement;
    assert.dom(spacer).hasClass('euiBorealisSpacer');
    assert.strictEqual(spacer.offsetHeight, px(padding('l')), 'spacer matches padding');
    assert.true(isClickableSlot(card));

    await click(el(card, '.euiCard__content'));
    assert.true(state.isSelected, 'surface click toggles');
    assert.strictEqual(el(card, '.euiCardSelect'), select, 'same button element');
    assert
      .dom(select)
      .hasAttribute('aria-checked', 'true')
      .hasText('Selected');
    assert.dom('svg, [data-icon-type="check"], .euiButton__content > :first-child', select).exists('check icon');
    assert.strictEqual(
      getComputedStyle(select).backgroundColor,
      style(this.element, '[data-success]').backgroundColor,
      'success color when selected'
    );

    await click(select);
    assert.false(state.isSelected, 'direct click toggles once');

    state.isDisabled = true;
    await settled();
    assert.dom(select).isDisabled().hasText('Unavailable');
    assert.false(isClickableSlot(card), 'not clickable');
    await click(el(card, '.euiCard__content'));
    assert.false(state.isSelected);

    assert
      .dom('[data-disabled] .euiCardSelect')
      .isDisabled('a disabled card disables its select button')
      .hasText('Unavailable');
  });

  test('beta badge sits centered on the top edge', async function (assert) {
    await render(
      <template>
        <div style="width: 400px; padding: 40px">
          <EuiCard
            @title="T"
            @onClick={{noop}}
            @betaBadgeProps={{hash label="Beta" title="Beta feature"}}
            data-card
          />
        </div>
        <EuiBetaBadge @label="Beta" @color="hollow" data-hollow />
      </template>
    );
    const card = el(this.element, '[data-card]');
    const anchor = el(card, '.euiCard__betaBadgeAnchor');
    const badge = el(card, '.euiCard__betaBadge');
    const anchorStyle = getComputedStyle(anchor);
    assert.strictEqual(anchorStyle.position, 'absolute');
    assert.strictEqual(anchorStyle.zIndex, '3');
    assert.strictEqual(getComputedStyle(card).position, 'relative');
    assert.strictEqual(getComputedStyle(card).overflow, 'visible');
    const cardRect = card.getBoundingClientRect();
    const anchorRect = anchor.getBoundingClientRect();
    assert.true(
      Math.abs(anchorRect.top + anchorRect.height / 2 - cardRect.top) < 1,
      'vertically centered on the top edge'
    );
    assert.true(
      Math.abs(
        anchorRect.left + anchorRect.width / 2 - (cardRect.left + cardRect.width / 2)
      ) < 1,
      'horizontally centered'
    );
    assert.strictEqual(badge.offsetWidth, anchor.offsetWidth, 'badge fills its anchor');
    assert.dom(badge).hasText('Beta').hasAttribute('title', 'Beta feature');
    assert.strictEqual(
      el(card, '.euiCard__titleButton').getAttribute('aria-describedby'),
      badge.id
    );
    assert.strictEqual(
      getComputedStyle(badge).backgroundColor,
      style(this.element, '[data-hollow]').backgroundColor,
      'hollow badge when enabled'
    );
  });

  test('card blocks: icon, title, description, body and footer', async function (assert) {
    let calls = 0;
    const onCustom = () => calls++;
    await render(
      <template>
        <EuiCard
          @onClick={{noop}}
          @titleElement="h3"
          @topClassName="top-x"
          @contentClassName="content-x"
          @footerClassName="footer-x"
          data-card
        >
          <:icon as |iconClass|><span class={{iconClass}} data-custom-icon>i</span></:icon>
          <:title as |register|>
            <button type="button" data-custom-title {{on "click" onCustom}} {{didInsert register}}>Custom</button>
          </:title>
          <:description>Block <b>description</b></:description>
          <:body><span data-body>Body</span></:body>
          <:footer><span data-footer>Footer</span></:footer>
        </EuiCard>
      </template>
    );
    const card = el(this.element, '[data-card]');
    assert.dom('.euiCard__title', card).hasTagName('h3');
    assert.dom('.euiCard__top', card).hasClass('top-x');
    assert.dom('.euiCard__content', card).hasClass('content-x');
    assert.dom('.euiCard__footer', card).hasClass('footer-x').hasText('Footer');
    const icon = el(card, '[data-custom-icon]');
    assert.dom(icon).hasClass('euiCard__icon');
    assert.strictEqual(getComputedStyle(icon).marginTop, padding('s'), 'icon class carries upstream spacing');
    assert.dom('.euiCard__description p', card).hasText('Block description');
    assert.strictEqual(
      el(card, '[data-custom-title]').getAttribute('aria-describedby'),
      null
    );
    assert.dom('.euiCard__children [data-body]', card).exists();
    assert.strictEqual(
      style(card, '.euiCard__children').marginTop,
      padding('s'),
      'children spacing'
    );
    await click(el(card, '[data-body]'));
    assert.strictEqual(calls, 1, 'registered custom title receives surface clicks');
  });

  test('card args update in place without replacing elements', async function (assert) {
    class State {
      @tracked layout: 'vertical' | 'horizontal' = 'vertical';
      @tracked textAlign: 'left' | 'center' | 'right' = 'center';
      @tracked paddingSize: Padding = 'm';
      @tracked display: Display | undefined = undefined;
      @tracked isDisabled = false;
      @tracked href: string | undefined = undefined;
    }
    const state = new State();
    await render(
      <template>
        <EuiCard
          @title="T"
          @layout={{state.layout}}
          @textAlign={{state.textAlign}}
          @paddingSize={{state.paddingSize}}
          @display={{state.display}}
          @isDisabled={{state.isDisabled}}
          @href={{state.href}}
          data-card
        />
      </template>
    );
    const card = el(this.element, '[data-card]');
    const main = el(card, '.euiCard__main');

    state.textAlign = 'right';
    state.paddingSize = 's';
    await settled();
    assert.strictEqual(getComputedStyle(card).textAlign, 'end');
    assert.strictEqual(getComputedStyle(card).paddingTop, padding('s'));

    state.layout = 'horizontal';
    await settled();
    assert.strictEqual(getComputedStyle(main).flexDirection, 'row');
    assert.strictEqual(getComputedStyle(card).textAlign, 'start');

    state.display = 'primary';
    await settled();
    assert.strictEqual(
      getComputedStyle(card).backgroundColor,
      rgb(euiBackgroundColor(lightContext, 'primary'))
    );
    assert.strictEqual(getComputedStyle(card).boxShadow, 'none');

    state.href = '#x';
    await settled();
    assert.dom('a.euiCard__titleAnchor', card).exists();
    assert.true(isClickableSlot(card));

    state.isDisabled = true;
    await settled();
    assert.dom('a', card).doesNotExist();
    assert.strictEqual(getComputedStyle(card).cursor, 'not-allowed');

    assert.strictEqual(el(this.element, '[data-card]'), card, 'root kept');
    assert.strictEqual(el(card, '.euiCard__main'), main, 'main kept');
  });

  // -------------------------------------------------------- Card select

  test('EuiCardSelect standalone: colors, i18n-backed text and custom content', async function (assert) {
    await render(
      <template>
        <EuiCardSelect data-idle />
        <EuiCardSelect @isSelected={{true}} @color="primary" data-custom />
        <EuiCardSelect data-block>Choose me</EuiCardSelect>
        <EuiButton @color="primary" data-primary>x</EuiButton>
      </template>
    );
    assert.dom('[data-idle]').hasText('Select').hasClass('euiButton');
    assert.strictEqual(
      style(this.element, '[data-custom]').backgroundColor,
      style(this.element, '[data-primary]').backgroundColor,
      'explicit color wins over success'
    );
    assert.dom('[data-block]').hasText('Choose me');
  });

  // ------------------------------------------------------ Checkable card

  test('checkable card: structure, label association, checked/disabled states', async function (assert) {
    class State {
      @tracked checked = false;
      @tracked disabled = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiCheckableCard
          @id="cc-radio"
          @label="Radio card"
          @checked={{state.checked}}
          @disabled={{state.disabled}}
          name="group"
          data-input
        >
          <:content>Details</:content>
        </EuiCheckableCard>
        <EuiCheckableCard
          @id="cc-check"
          @checkableType="checkbox"
          @label="Checkbox card"
          @hasBorder={{false}}
          @hasShadow={{true}}
        />
      </template>
    );
    const card = el(this.element, '.euiCheckableCard');
    const [control, body] = Array.from(
      card.querySelectorAll<HTMLElement>(':scope > .euiSplitPanel__inner')
    ) as [HTMLElement, HTMLElement];
    assert.dom('input#cc-radio[type="radio"][name="group"][data-input]').exists('attributes reach the input');
    assert.dom('label[for="cc-radio"]', card).hasText('Radio card').hasAttribute('aria-describedby', 'cc-radio-details');
    assert.dom('#cc-radio-details', card).hasText('Details');
    assert.strictEqual(getComputedStyle(card).flexDirection, 'row');
    assert.strictEqual(getComputedStyle(card).display, 'flex');
    assert.strictEqual(getComputedStyle(card, '::after').borderTopColor, rgb(light.border.color), 'normal border');
    assert.strictEqual(getComputedStyle(control).flexGrow, '0');
    assert.strictEqual(getComputedStyle(body).flexGrow, '1');
    assert.strictEqual(
      getComputedStyle(control).backgroundColor,
      rgb(euiBackgroundColor(lightContext, 'subdued'))
    );
    assert.true(isClickableSlot(control), 'clickable control section');
    const label = el(card, 'label');
    assert.strictEqual(label.offsetWidth, body.clientWidth, 'label covers the section');
    assert.strictEqual(getComputedStyle(label).cursor, 'pointer');
    assert.strictEqual(style(card, '.euiCheckableCard__children').marginTop, light.size.base);

    state.checked = true;
    await settled();
    finishTransitions();
    assert.strictEqual(
      getComputedStyle(card, '::after').borderTopColor,
      rgb(light.colors.primary),
      'checked: primary border'
    );
    assert.strictEqual(
      getComputedStyle(control).backgroundColor,
      rgb(euiBackgroundColor(lightContext, 'primary'))
    );

    state.disabled = true;
    await settled();
    finishTransitions();
    assert.dom('#cc-radio').isDisabled();
    assert.strictEqual(
      getComputedStyle(card, '::after').borderTopColor,
      rgb(light.border.color),
      'disabled cards drop the checked border'
    );
    assert.strictEqual(getComputedStyle(label).color, rgb(light.colors.disabledText));
    assert.strictEqual(getComputedStyle(label).cursor, 'not-allowed');
    assert.false(isClickableSlot(control));
    assert.strictEqual(el(this.element, '.euiCheckableCard'), card, 'root kept');

    const checkboxCard = el(this.element, '.euiCheckableCard:has(#cc-check)');
    assert.dom('input#cc-check[type="checkbox"]').exists();
    assert.strictEqual(getComputedStyle(checkboxCard, '::after').content, 'none', 'hasBorder=false');
    assert.notStrictEqual(getComputedStyle(checkboxCard).boxShadow, 'none', 'hasShadow');
  });

  test('checkable card: control section and details click the label, interactive details do not', async function (assert) {
    class State {
      @tracked a = false;
      @tracked b = false;
    }
    const state = new State();
    const toggleA = (event: Event) => (state.a = (event.target as HTMLInputElement).checked);
    const toggleB = (event: Event) => (state.b = (event.target as HTMLInputElement).checked);
    await render(
      <template>
        <EuiCheckableCard
          @id="a"
          @checkableType="checkbox"
          @label="A"
          @checked={{state.a}}
          {{on "change" toggleA}}
        >
          <:content><span data-a-details>Plain</span></:content>
        </EuiCheckableCard>
        <EuiCheckableCard
          @id="b"
          @checkableType="checkbox"
          @label="B"
          @checked={{state.b}}
          {{on "change" toggleB}}
        >
          <:content><a href="#nowhere" data-b-link>Link</a></:content>
        </EuiCheckableCard>
        <EuiCheckableCard @id="r1" @label="One" name="radios" value="1" />
        <EuiCheckableCard @id="r2" @label="Two" name="radios" value="2" />
      </template>
    );
    const cardA = el(this.element, '.euiCheckableCard:has(#a)');
    await click(el(cardA, '.euiSplitPanel__inner'));
    assert.true(state.a, 'control section toggles');
    await click('#a');
    assert.false(state.a, 'direct input click toggles once');
    await click('[data-a-details]');
    assert.true(state.a, 'plain details toggle');
    await click('label[for="a"]');
    assert.false(state.a, 'label toggles');
    assert.strictEqual(style(cardA, '.euiCheckableCard__children').cursor, 'pointer');

    const cardB = el(this.element, '.euiCheckableCard:has(#b)');
    el(cardB, '[data-b-link]').addEventListener('click', (e) => e.preventDefault());
    await click('[data-b-link]');
    assert.false(state.b, 'interactive details keep their click');
    assert.strictEqual(style(cardB, '.euiCheckableCard__children').cursor, 'auto');

    await click(el(this.element, '.euiCheckableCard:has(#r2) .euiSplitPanel__inner'));
    assert.dom('#r2').isChecked();
    await click('label[for="r1"]');
    assert.dom('#r1').isChecked();
    assert.dom('#r2').isNotChecked('native radio group');
  });

  // -------------------------------------------------------- Split panel

  test('split panel: outer/inner defaults, direction and args', async function (assert) {
    await render(
      <template>
        <EuiSplitPanelOuter data-column>
          <EuiSplitPanelInner data-a>A</EuiSplitPanelInner>
          <EuiSplitPanelInner @color="subdued" @paddingSize="l" data-b>B</EuiSplitPanelInner>
        </EuiSplitPanelOuter>
        <EuiSplitPanelOuter @direction="row" @hasBorder={{false}} @hasShadow={{true}} data-row>
          <EuiSplitPanelInner @grow={{false}} data-c>C</EuiSplitPanelInner>
          <EuiSplitPanelInner data-d>D</EuiSplitPanelInner>
        </EuiSplitPanelOuter>
      </template>
    );
    const outer = el(this.element, '[data-column]');
    const computed = getComputedStyle(outer);
    assert.dom(outer).hasClass('euiSplitPanel').hasClass('euiPanelBorealis');
    assert.strictEqual(computed.display, 'flex');
    assert.strictEqual(computed.flexDirection, 'column');
    assert.strictEqual(computed.overflow, 'hidden');
    assert.strictEqual(computed.minWidth, '0px');
    assert.strictEqual(computed.paddingTop, '0px');
    assert.strictEqual(computed.flexGrow, '0');
    assert.strictEqual(computed.borderRadius, light.border.radius.panel);
    assert.strictEqual(getComputedStyle(outer, '::after').borderTopWidth, '1px', 'panel default border');

    const a = style(this.element, '[data-a]');
    assert.strictEqual(a.flexBasis, '0%');
    assert.strictEqual(a.flexGrow, '1');
    assert.strictEqual(a.backgroundColor, 'rgba(0, 0, 0, 0)');
    assert.strictEqual(a.borderRadius, '0px');
    assert.strictEqual(a.paddingTop, padding('m'));
    assert.strictEqual(a.boxShadow, 'none');
    assert.strictEqual(style(this.element, '[data-a]', '::after').content, 'none');
    const b = style(this.element, '[data-b]');
    assert.strictEqual(b.backgroundColor, rgb(euiBackgroundColor(lightContext, 'subdued')));
    assert.strictEqual(b.paddingTop, padding('l'));

    const row = el(this.element, '[data-row]');
    assert.strictEqual(getComputedStyle(row).flexDirection, 'row', 'row at 1440px');
    assert.notStrictEqual(getComputedStyle(row).boxShadow, 'none');
    assert.strictEqual(style(this.element, '[data-c]').flexGrow, '0');
    const c = el(this.element, '[data-c]').getBoundingClientRect();
    const d = el(this.element, '[data-d]').getBoundingClientRect();
    assert.true(Math.abs(c.top - d.top) < 1 && c.right <= d.left + 1, 'side by side');
  });

  test('split panel responsive collapse through media queries (iframe viewports)', async function (assert) {
    await render(
      <template>
        <EuiSplitPanelOuter @direction="row" data-default>
          <EuiSplitPanelInner>A</EuiSplitPanelInner>
          <EuiSplitPanelInner>B</EuiSplitPanelInner>
        </EuiSplitPanelOuter>
        <EuiSplitPanelOuter @direction="row" @responsive={{false}} data-never>
          <EuiSplitPanelInner>A</EuiSplitPanelInner>
        </EuiSplitPanelOuter>
        <EuiSplitPanelOuter @direction="row" @responsive={{array "m"}} data-medium>
          <EuiSplitPanelInner>A</EuiSplitPanelInner>
        </EuiSplitPanelOuter>
        <EuiSplitPanelOuter data-column>
          <EuiSplitPanelInner>A</EuiSplitPanelInner>
        </EuiSplitPanelOuter>
      </template>
    );
    const html = (this.element as HTMLElement).innerHTML;
    const { s, m, l } = light.breakpoint;
    const expectations: [number, Record<string, string>][] = [
      [s - 1, { default: 'column', never: 'row', medium: 'row', column: 'column' }],
      [m - 1, { default: 'column', never: 'row', medium: 'row', column: 'column' }],
      [m, { default: 'row', never: 'row', medium: 'column', column: 'column' }],
      [l, { default: 'row', never: 'row', medium: 'row', column: 'column' }]
    ];
    for (const [width, expected] of expectations) {
      const viewport = inViewport(width, html);
      for (const [name, direction] of Object.entries(expected))
        assert.strictEqual(
          viewport.style(`[data-${name}]`).flexDirection,
          direction,
          `${name} at ${width}px`
        );
      viewport.remove();
    }
    assert.strictEqual(style(this.element, '[data-medium]').flexDirection, 'row', '1440px host is above m');
  });

  test('split panel high contrast dividers follow the (responsive) direction', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider @highContrastMode="preferred" @globalStyles={{false}}>
          <EuiSplitPanelOuter @direction="row" data-row>
            <EuiSplitPanelInner data-first>A</EuiSplitPanelInner>
            <EuiSplitPanelInner data-last>B</EuiSplitPanelInner>
          </EuiSplitPanelOuter>
          <EuiSplitPanelOuter data-column>
            <EuiSplitPanelInner data-first>A</EuiSplitPanelInner>
            <EuiSplitPanelInner data-last>B</EuiSplitPanelInner>
          </EuiSplitPanelOuter>
          <EuiSplitPanelOuter @color="transparent" @direction="row" data-none>
            <EuiSplitPanelInner data-first>A</EuiSplitPanelInner>
            <EuiSplitPanelInner data-last>B</EuiSplitPanelInner>
          </EuiSplitPanelOuter>
          <EuiCheckableCard @id="hc" @label="HC" @checked={{true}} data-hc-input />
        </EuiEmotionProvider>
        <EuiSplitPanelOuter @direction="row" data-normal>
          <EuiSplitPanelInner data-first>A</EuiSplitPanelInner>
          <EuiSplitPanelInner data-last>B</EuiSplitPanelInner>
        </EuiSplitPanelOuter>
      </template>
    );
    const hc = resolveBorealisTheme('light', {}, 'preferred').euiTheme;
    const outer = style(this.element, '[data-row]');
    assert.strictEqual(outer.borderTopStyle, 'solid', 'outer contrast border');
    assert.strictEqual(outer.borderTopWidth, hc.border.width.thin);

    const first = style(this.element, '[data-row] [data-first]');
    assert.strictEqual(first.borderInlineEndStyle, 'solid', 'row divider');
    assert.strictEqual(first.borderInlineEndColor, outer.borderTopColor, 'divider inherits the outer border color');
    assert.strictEqual(first.borderBottomStyle, 'none');
    assert.strictEqual(style(this.element, '[data-row] [data-last]').borderInlineEndStyle, 'none');

    const columnFirst = style(this.element, '[data-column] [data-first]');
    assert.strictEqual(columnFirst.borderBottomStyle, 'solid', 'column divider');
    assert.strictEqual(columnFirst.borderInlineEndStyle, 'none');

    assert.strictEqual(
      style(this.element, '[data-none] [data-first]').borderInlineEndStyle,
      'none',
      'transparent borderless outer: no dividers'
    );
    assert.strictEqual(
      style(this.element, '[data-normal] [data-first]').borderInlineEndStyle,
      'none',
      'normal contrast: no dividers'
    );

    // A collapsed row (narrow viewport) switches to column dividers.
    const narrow = inViewport(light.breakpoint.s - 1, (this.element as HTMLElement).innerHTML);
    assert.strictEqual(narrow.style('[data-row]').flexDirection, 'column');
    assert.strictEqual(narrow.style('[data-row] [data-first]').borderBottomStyle, 'solid');
    assert.strictEqual(narrow.style('[data-row] [data-first]').borderInlineEndStyle, 'none');
    narrow.remove();

    // Checkable card in preferred contrast: primary border on the card itself.
    const card = el(this.element, '.euiCheckableCard:has([data-hc-input])');
    assert.strictEqual(getComputedStyle(card).borderTopColor, rgb(hc.colors.primary));
  });

  // -------------------------------------------------------- Theming

  test('light/dark nearest provider, sibling isolation and teardown', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'dark';
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}} @globalStyles={{false}}>
          <EuiCard @title="Dark" @description="d" data-dark />
          <EuiCheckableCard @id="dk" @label="Dark" @checked={{true}} data-dark-input />
          <EuiSplitPanelOuter data-dark-split>
            <EuiSplitPanelInner @color="subdued" data-dark-inner>x</EuiSplitPanelInner>
          </EuiSplitPanelOuter>
          <EuiEmotionProvider @colorMode="light">
            <EuiCard @title="Nested light" data-nested />
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light" @globalStyles={{false}}>
          <EuiCard @title="Sibling" data-sibling />
        </EuiEmotionProvider>
      </template>
    );
    const darkTheme = darkContext.euiTheme;
    assert.strictEqual(
      style(this.element, '[data-dark]').backgroundColor,
      rgb(euiBackgroundColor(darkContext, 'plain'))
    );
    assert.strictEqual(
      style(this.element, '[data-dark] .euiCard__title').color,
      rgb(darkTheme.colors.textHeading)
    );
    const darkCard = el(this.element, '.euiCheckableCard:has([data-dark-input])');
    assert.strictEqual(getComputedStyle(darkCard, '::after').borderTopColor, rgb(darkTheme.colors.primary));
    assert.strictEqual(
      style(this.element, '[data-dark-inner]').backgroundColor,
      rgb(euiBackgroundColor(darkContext, 'subdued'))
    );
    assert.strictEqual(
      style(this.element, '[data-nested]').backgroundColor,
      rgb(euiBackgroundColor(lightContext, 'plain')),
      'nearest provider wins'
    );
    assert.strictEqual(
      style(this.element, '[data-sibling]').backgroundColor,
      rgb(euiBackgroundColor(lightContext, 'plain')),
      'sibling isolation'
    );

    const card = el(this.element, '[data-dark]');
    state.mode = 'light';
    await settled();
    assert.strictEqual(el(this.element, '[data-dark]'), card, 'same element');
    assert.strictEqual(
      getComputedStyle(card).backgroundColor,
      rgb(euiBackgroundColor(lightContext, 'plain'))
    );

    await clearRender();
    assert.dom('.euiCard, .euiCheckableCard, .euiSplitPanel').doesNotExist();
  });

  test('native token overrides (JS objects) stay scoped and update in place', async function (assert) {
    class State {
      @tracked overrides: EuiBorealisOverrides = {};
      @tracked contrast: EuiBorealisHighContrastMode = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider
          @borealisOverrides={{state.overrides}}
          @highContrastMode={{state.contrast}}
          @globalStyles={{false}}
        >
          <EuiCard @title="T" @paddingSize="l" data-card />
          <EuiCheckableCard @id="ov" @label="O" @checked={{true}} data-ov-input />
        </EuiEmotionProvider>
        <EuiCard @title="T" @paddingSize="l" data-outside />
      </template>
    );
    state.overrides = {
      size: { l: '30px' },
      colors: { LIGHT: { primary: '#663399', backgroundBasePlain: '#fafaf0' } }
    };
    await settled();
    finishTransitions();
    const card = style(this.element, '[data-card]');
    assert.strictEqual(card.paddingTop, '30px', 'size override');
    assert.strictEqual(card.backgroundColor, rgb('#fafaf0'), 'color override');
    const checkable = el(this.element, '.euiCheckableCard:has([data-ov-input])');
    assert.strictEqual(getComputedStyle(checkable, '::after').borderTopColor, rgb('#663399'));
    const outside = style(this.element, '[data-outside]');
    assert.strictEqual(outside.paddingTop, padding('l'), 'outside unaffected');
    assert.strictEqual(outside.backgroundColor, rgb(euiBackgroundColor(lightContext, 'plain')));

    state.contrast = 'preferred';
    await settled();
    assert.strictEqual(style(this.element, '[data-card]').boxShadow, 'none', 'contrast drops the shadow');
    assert.strictEqual(style(this.element, '[data-card]').borderTopStyle, 'solid', 'contrast border');
  });

  test('@css composes last into the card, split panel and checkable card classes', async function (assert) {
    const cardCss = { outlineStyle: 'dashed', paddingTop: '3px' };
    const outerCss = { gap: '7px' };
    const innerCss = { paddingTop: '5px' };
    await render(
      <template>
        <EuiCard @title="T" @css={{cardCss}} data-card />
        <EuiSplitPanelOuter @css={{outerCss}} data-outer>
          <EuiSplitPanelInner @css={{innerCss}} data-inner>x</EuiSplitPanelInner>
        </EuiSplitPanelOuter>
        <EuiCheckableCard @id="css" @label="C" @css={{outerCss}} data-css-input />
      </template>
    );
    const card = el(this.element, '[data-card]');
    assert.strictEqual(getComputedStyle(card).outlineStyle, 'dashed');
    assert.strictEqual(getComputedStyle(card).paddingTop, '3px', 'caller css wins over panel padding');
    const generated = Array.from(card.classList).filter((name) =>
      name.startsWith('eui-spike-')
    );
    assert.strictEqual(generated.length, 1, 'one Emotion class on the card panel');
    assert.strictEqual(style(this.element, '[data-outer]').rowGap, '7px');
    assert.strictEqual(style(this.element, '[data-inner]').paddingTop, '5px');
    assert.strictEqual(
      getComputedStyle(el(this.element, '.euiCheckableCard:has([data-css-input])')).rowGap,
      '7px'
    );
  });
});
