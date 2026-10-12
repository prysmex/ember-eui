import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import {
  clearRender,
  click,
  focus,
  render,
  settled,
  triggerEvent,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';

import EuiButton from '#src/components/eui-button.gts';
import EuiConfirmModal from '#src/components/eui-confirm-modal.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiFlyout from '#src/components/eui-flyout.gts';
import EuiFlyoutBody from '#src/components/eui-flyout-body.gts';
import EuiFlyoutFooter from '#src/components/eui-flyout-footer.gts';
import EuiFlyoutHeader from '#src/components/eui-flyout-header.gts';
import EuiModal from '#src/components/eui-modal.gts';
import EuiModalBody from '#src/components/eui-modal-body.gts';
import EuiModalFooter from '#src/components/eui-modal-footer.gts';
import EuiModalHeader from '#src/components/eui-modal-header.gts';
import EuiModalHeaderTitle from '#src/components/eui-modal-header-title.gts';
import EuiTitle from '#src/components/eui-title.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type {
  EuiBorealisHighContrastMode,
  EuiBorealisOverrides
} from '#src/utils/eui/theme.ts';

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;
const noop = () => {};

/** Borealis `size` tokens are px strings. */
const SIZE = (token: keyof typeof light.size) => parseFloat(light.size[token]);
const FORM_MAX_WIDTH = 400;

function el(root: ParentNode, selector: string): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

const $ = (selector: string) => el(document.body, selector);
const css = (element: Element) => getComputedStyle(element);

/** A theme color as computed `rgb()`. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.append(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

function close(
  assert: Assert,
  actual: number,
  expected: number,
  message: string,
  tolerance = 1
) {
  assert.true(
    Math.abs(actual - expected) <= tolerance,
    `${message} (expected ${expected}, got ${actual})`
  );
}

/** `1px solid #abc` -> the color part as `rgb()`. */
function borderColor(border: string) {
  return rgb(border.split(' ').slice(2).join(' '));
}

/** Jumps finite CSS animations (slide-ins, mask fade) to their end state. */
function finishAnimations() {
  for (const animation of document.getAnimations()) {
    try {
      animation.finish();
    } catch {
      // infinite animations (spinners) cannot finish
    }
  }
}

const rem = (value: number) =>
  value * parseFloat(getComputedStyle(document.documentElement).fontSize);

/** Viewport width used by `position: fixed` percentages. */
const viewport = () => document.documentElement.clientWidth;

/** Every stylesheet rule (with its enclosing at-rule text) mentioning a class. */
function rulesFor(element: Element) {
  // Emotion classes: `<cache key>-<hash>-<labels>`
  const classes = Array.from(element.classList).filter(
    (name) => name.split('-').length > 2
  );
  const found: { media: string; text: string }[] = [];
  const visit = (rules: CSSRuleList, media: string) => {
    for (const rule of Array.from(rules)) {
      if (rule instanceof CSSMediaRule)
        visit(rule.cssRules, rule.conditionText);
      else if (classes.some((name) => rule.cssText.includes(name)))
        found.push({ media, text: rule.cssText });
    }
  };
  for (const sheet of Array.from(document.styleSheets)) {
    try {
      visit(sheet.cssRules, '');
    } catch {
      // cross-origin sheet
    }
  }
  return found;
}

function animationGuarded(assert: Assert, element: Element, label: string) {
  const rules = rulesFor(element);
  const animated = rules.filter((rule) =>
    /animation(-name)?:\s*[^;]*animation-/.test(rule.text) ||
    /animation-duration/.test(rule.text)
  );
  assert.true(animated.length > 0, `${label}: has an animation`);
  const motion = rules.filter((rule) =>
    rule.media.includes('prefers-reduced-motion: no-preference')
  );
  assert.true(
    motion.some((rule) => /animation/.test(rule.text)),
    `${label}: the moving animation is guarded by prefers-reduced-motion`
  );
  return rules;
}

module('Integration | Component | Borealis modal and flyout', function (hooks) {
  setupRenderingTest(hooks);

  hooks.afterEach(function () {
    document.documentElement.removeAttribute('dir');
    document.documentElement.style.removeProperty('--euiFixedHeadersOffset');
    document.body.style.paddingInlineEnd = '';
    document.body.style.paddingInlineStart = '';
  });

  test('EuiModal: widths, surface, radius, shadow and part padding', async function (assert) {
    class State {
      @tracked maxWidth: boolean | number | string | undefined = undefined;
      @tracked wide = true;
    }
    const state = new State();
    await render(
      <template>
        <EuiModal @onClose={{noop}} @maxWidth={{state.maxWidth}} data-modal>
          <EuiModalHeader>
            <EuiModalHeaderTitle><h1>Rename</h1></EuiModalHeaderTitle>
          </EuiModalHeader>
          <EuiModalBody>
            {{#if state.wide}}<div style="width: 2000px">wide</div>{{else}}x{{/if}}
          </EuiModalBody>
          <EuiModalFooter><button type="button">A</button><button type="button">B</button></EuiModalFooter>
        </EuiModal>
        <EuiTitle @size="m" data-reference-title>Reference</EuiTitle>
      </template>
    );
    const modal = $('[data-modal]');
    finishAnimations();
    const vw = viewport();

    close(assert, modal.getBoundingClientRect().width, Math.min(light.breakpoint.m as number, vw - 16), 'default max width = m breakpoint');
    assert.dom(modal).hasStyle({
      display: 'flex',
      flexDirection: 'column',
      position: 'relative',
      overflow: 'hidden',
      backgroundColor: rgb(light.colors.backgroundBasePlain),
      color: rgb(light.colors.textParagraph),
      borderTopLeftRadius: light.border.radius.frame,
      borderTopWidth: '1px',
      borderTopColor: rgb(light.colors.borderBaseFloating),
      zIndex: String(light.levels.modal),
      boxSizing: 'border-box',
      minWidth: `${FORM_MAX_WIDTH}px`
    });
    assert.notStrictEqual(css(modal).boxShadow, 'none', 'XL shadow');
    close(assert, parseFloat(css(modal).maxHeight), window.innerHeight * 0.75, 'max block size 75vh');

    state.maxWidth = false;
    await settled();
    assert.strictEqual($('[data-modal]'), modal, 'same element');
    close(assert, modal.getBoundingClientRect().width, vw - 16, 'false: only the window gutter');

    state.maxWidth = 600;
    await settled();
    close(assert, modal.getBoundingClientRect().width, 600, 'number: px');
    state.maxWidth = '35rem';
    await settled();
    close(assert, modal.getBoundingClientRect().width, rem(35), 'CSS width');

    state.maxWidth = true;
    state.wide = false;
    await settled();
    close(assert, modal.getBoundingClientRect().width, FORM_MAX_WIDTH, 'narrow content: form max width minimum');

    const header = el(modal, '.euiModalHeader');
    assert.dom(header).hasStyle({
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      paddingTop: light.size.l,
      paddingRight: light.size.xxl,
      paddingBottom: light.size.base,
      paddingLeft: light.size.l
    });
    const title = el(modal, '.euiModalHeader__title');
    assert.dom(title).hasClass('euiTitle');
    const reference = $('[data-reference-title]');
    for (const key of ['fontSize', 'fontWeight', 'lineHeight', 'fontFamily'] as const)
      assert.strictEqual(css(el(title, 'h1'))[key], css(reference)[key], `nested h1 inherits the EuiTitle m ${key}`);
    assert.dom(el(title, 'h1')).hasStyle({ marginTop: '0px', marginBottom: '0px' });

    const overflow = el(modal, '.euiModalBody__overflow');
    assert.dom('.euiModalBody', modal).hasStyle({ display: 'flex', flexDirection: 'column', flexGrow: '1' });
    assert.dom(overflow).hasStyle({
      paddingLeft: light.size.l,
      paddingRight: light.size.l,
      paddingTop: light.size.s,
      paddingBottom: light.size.s,
      overflowY: 'auto'
    });

    const footer = el(modal, '.euiModalFooter');
    assert.dom(footer).hasStyle({
      display: 'flex',
      justifyContent: 'flex-end',
      paddingTop: light.size.base,
      paddingBottom: light.size.l,
      paddingLeft: light.size.l,
      paddingRight: light.size.l,
      columnGap: light.size.base,
      flexShrink: '0'
    });

    const closeIcon = el(modal, '.euiModal__closeIcon');
    assert.true(modal.lastElementChild!.contains(closeIcon), 'the close button comes after the content (upstream order)');
    assert.dom(closeIcon.parentElement!).hasClass('euiModal__closeIconWrapper').hasStyle({ position: 'absolute', zIndex: '3' });
    const modalRect = modal.getBoundingClientRect();
    const iconRect = closeIcon.getBoundingClientRect();
    close(assert, modalRect.right - 1 - iconRect.right, SIZE('xs'), 'close button inline end inset');
    close(assert, iconRect.top - modalRect.top - 1, SIZE('xs'), 'close button block start inset');
  });

  test('EuiModal: header followed by footer, RTL close button and reduced motion', async function (assert) {
    document.documentElement.setAttribute('dir', 'rtl');
    await render(
      <template>
        <EuiModal @onClose={{noop}} data-modal>
          <EuiModalHeader><EuiModalHeaderTitle>T</EuiModalHeaderTitle></EuiModalHeader>
          <EuiModalFooter>F</EuiModalFooter>
        </EuiModal>
      </template>
    );
    const modal = $('[data-modal]');
    assert.dom('.euiModalFooter', modal).hasStyle({ paddingTop: light.size.s }, 'header + footer');
    const modalRect = modal.getBoundingClientRect();
    const iconRect = $('.euiModal__closeIcon').getBoundingClientRect();
    close(assert, iconRect.left - modalRect.left - 1, SIZE('xs'), 'RTL: close button on the left');
    assert.dom('.euiModalHeader', modal).hasStyle({ paddingLeft: light.size.xxl, paddingRight: light.size.l }, 'logical header padding');
    animationGuarded(assert, modal, 'modal');

    await render(
      <template>
        <EuiModal @onClose={{noop}}><EuiModalBody>Only a body</EuiModalBody></EuiModal>
      </template>
    );
    assert.dom('.euiModalBody__overflow', document.body).hasStyle({ paddingBottom: light.size.l }, 'the last body gets end padding');
  });

  test('EuiModal: Escape, mask clicks and the close button', async function (assert) {
    class State {
      @tracked outside = false;
    }
    const state = new State();
    const calls: string[] = [];
    const onClose = (event: Event) => calls.push(event.type);
    let documentEscapes = 0;
    const listener = (event: KeyboardEvent) => {
      if (event.key === 'Escape') documentEscapes++;
    };
    document.addEventListener('keydown', listener);
    await render(
      <template>
        <EuiModal @onClose={{onClose}} @clickOutsideToClose={{state.outside}} data-modal>
          <EuiModalBody><input data-input /></EuiModalBody>
        </EuiModal>
      </template>
    );

    await triggerKeyEvent($('[data-input]'), 'keydown', 'Escape');
    assert.deepEqual(calls, ['keydown'], 'Escape from inside closes');
    assert.strictEqual(documentEscapes, 0, 'Escape does not propagate past the modal');
    await triggerKeyEvent(document.body, 'keydown', 'Escape');
    assert.deepEqual(calls, ['keydown'], 'Escape from outside the modal is ignored (upstream)');

    await click($('.euiOverlayMask'));
    assert.deepEqual(calls, ['keydown'], 'mask clicks do not close by default');
    await click($('[data-input]'));
    state.outside = true;
    await settled();
    await click($('[data-modal]'));
    assert.deepEqual(calls, ['keydown'], 'clicks inside never close');
    await click($('.euiOverlayMask'));
    assert.deepEqual(calls, ['keydown', 'click'], '@clickOutsideToClose closes on mask clicks');

    await click($('.euiModal__closeIcon'));
    assert.deepEqual(calls, ['keydown', 'click', 'click'], 'close button');
    assert.dom('.euiModal__closeIcon', document.body).hasAttribute('aria-label', 'Close this dialog');
    document.removeEventListener('keydown', listener);

    await render(
      <template>
        <EuiModal @onClose={{onClose}} @outsideClickCloses={{true}} data-modal>x</EuiModal>
      </template>
    );
    await click($('.euiOverlayMask'));
    assert.strictEqual(calls.length, 4, '@outsideClickCloses (upstream name) works too');
  });

  test('EuiModal: dialog semantics, description, labelling and focus', async function (assert) {
    class State {
      @tracked open = true;
    }
    const state = new State();
    await render(
      <template>
        <button type="button" data-opener>Open</button>
        {{#if state.open}}
          <EuiModal @onClose={{noop}} aria-describedby="extra" data-modal>
            <EuiModalHeader><EuiModalHeaderTitle><h1>Rename dashboard</h1></EuiModalHeaderTitle></EuiModalHeader>
            <EuiModalBody><input data-first /><span id="extra">More</span></EuiModalBody>
            <EuiModalFooter><button type="button" data-last>Save</button></EuiModalFooter>
          </EuiModal>
        {{/if}}
      </template>
    );
    const modal = $('[data-modal]');
    assert.dom(modal).hasAttribute('role', 'dialog').hasAttribute('aria-modal', 'true').hasAttribute('tabindex', '0');
    const [descriptionId, extra] = modal.getAttribute('aria-describedby')!.split(' ');
    assert.strictEqual(extra, 'extra', 'caller aria-describedby kept');
    const description = document.getElementById(descriptionId!)!;
    assert.dom(description).hasText(
      'You are in a modal dialog. Press Escape or tap/click outside the dialog on the shadowed overlay to close.'
    );
    assert.true(modal.contains(description), 'description inside the dialog');
    assert.dom(description).hasClass('euiScreenReaderOnly');
    assert.strictEqual(css(description).position, 'absolute', 'visually hidden');
    const title = el(modal, '.euiModalHeader__title');
    assert.dom(modal).hasAttribute('aria-labelledby', title.id, 'labelled by its title');
    assert.ok(title.id);

    await waitUntil(() => document.activeElement === modal, { timeout: 2000 });
    assert.strictEqual(document.activeElement, modal, 'the modal focuses itself');
    await focus($('[data-last]'));
    await triggerKeyEvent($('[data-last]'), 'keydown', 'Tab');
    assert.true(modal.contains(document.activeElement), 'Tab stays inside the trap');

    state.open = false;
    await settled();
    assert.dom('.euiModal', document.body).doesNotExist();
    assert.dom(document.body).doesNotHaveClass('euiBody-hasOverlayMask', 'mask cleanup');

    await render(
      <template>
        <EuiModal @onClose={{noop}} @initialFocus="[data-first]" aria-labelledby="own" role="alertdialog" data-modal>
          <EuiModalHeader><EuiModalHeaderTitle>T</EuiModalHeaderTitle></EuiModalHeader>
          <span id="own">Own label</span><input data-first />
        </EuiModal>
      </template>
    );
    assert.dom('[data-modal]', document.body).hasAttribute('aria-labelledby', 'own').hasAttribute('role', 'alertdialog');
    await waitUntil(() => document.activeElement === $('[data-first]'), { timeout: 2000 });
    assert.strictEqual(document.activeElement, $('[data-first]'), '@initialFocus');
  });

  test('EuiConfirmModal: alertdialog, buttons, colors, default focus and loading', async function (assert) {
    class State {
      @tracked color: string | undefined = undefined;
      @tracked loading = false;
      @tracked disabled = false;
    }
    const state = new State();
    const calls: string[] = [];
    const onConfirm = () => calls.push('confirm');
    const onCancel = () => calls.push('cancel');
    await render(
      <template>
        <EuiConfirmModal
          @title="Delete report?"
          @message="This cannot be undone."
          @cancelButtonText="Keep"
          @confirmButtonText="Delete"
          @buttonColor={{state.color}}
          @isLoading={{state.loading}}
          @confirmButtonDisabled={{state.disabled}}
          @defaultFocusedButton="confirm"
          @onConfirm={{onConfirm}}
          @onCancel={{onCancel}}
          data-confirm
        />
        <div data-references>
          <EuiButton @fill={{true}} data-primary>p</EuiButton>
          <EuiButton @fill={{true}} @color="danger" data-danger>d</EuiButton>
        </div>
      </template>
    );
    const modal = $('[data-confirm]');
    assert.dom(modal).hasClass('euiModal').hasClass('euiModal--confirmation').hasAttribute('role', 'alertdialog').hasAttribute('aria-modal', 'true');
    assert.dom('[data-test-subj="confirmModalTitleText"] h1', modal).hasText('Delete report?');
    assert.strictEqual(modal.getAttribute('aria-labelledby'), el(modal, '.euiModalHeader__title').id);
    assert.dom('[data-test-subj="confirmModalBodyText"] p', modal).hasText('This cannot be undone.');
    assert.dom(modal).hasStyle({ minWidth: `${FORM_MAX_WIDTH}px` });
    const confirm = el(modal, '[data-test-subj="confirmModalConfirmButton"]');
    const cancel = el(modal, '[data-test-subj="confirmModalCancelButton"]');
    assert.dom(cancel).hasClass('euiButtonEmpty').hasText('Keep');
    assert.dom(confirm).hasClass('euiButton').hasText('Delete');
    assert.strictEqual(css(confirm).backgroundColor, css($('[data-primary]')).backgroundColor, 'buttonColor defaults to primary');

    await waitUntil(() => document.activeElement === confirm, { timeout: 2000 });
    assert.strictEqual(document.activeElement, confirm, 'defaultFocusedButton="confirm"');

    state.color = 'danger';
    await settled();
    assert.strictEqual(el(modal, '[data-test-subj="confirmModalConfirmButton"]'), confirm, 'same button');
    assert.strictEqual(css(confirm).backgroundColor, css($('[data-danger]')).backgroundColor, 'danger fill');

    await click(cancel);
    await click(confirm);
    assert.deepEqual(calls, ['cancel', 'confirm']);
    await triggerKeyEvent(confirm, 'keydown', 'Escape');
    assert.deepEqual(calls, ['cancel', 'confirm', 'cancel'], 'Escape cancels');
    await click(el(modal, '.euiModal__closeIcon'));
    assert.deepEqual(calls.at(-1), 'cancel', 'close button cancels');

    state.loading = true;
    await settled();
    assert.dom(confirm).isDisabled().hasAttribute('aria-busy', 'true');
    assert.dom('.euiBorealisLoadingSpinner', confirm).exists('spinner while loading');
    state.loading = false;
    state.disabled = true;
    await settled();
    assert.dom(confirm).isDisabled().doesNotHaveAttribute('aria-busy');

    await render(
      <template>
        <EuiConfirmModal @title="T" @cancelButtonText="No" @confirmButtonText="Yes" @defaultFocusedButton="cancel" @onConfirm={{noop}} @onCancel={{noop}} />
      </template>
    );
    const cancel2 = $('[data-test-subj="confirmModalCancelButton"]');
    await waitUntil(() => document.activeElement === cancel2, { timeout: 2000 });
    assert.strictEqual(document.activeElement, cancel2, 'defaultFocusedButton="cancel"');
    assert.dom('.euiModalBody', document.body).doesNotExist('no body without a message');
  });

  test('EuiFlyout: every size measured, maxWidth and custom widths', async function (assert) {
    class State {
      @tracked size: string | number = 's';
      @tracked maxWidth: boolean | number | string = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiFlyout @onClose={{noop}} @size={{state.size}} @maxWidth={{state.maxWidth}} data-flyout>x</EuiFlyout>
      </template>
    );
    const flyout = $('[data-flyout]');
    const vw = viewport();
    const width = () => {
      finishAnimations();
      return flyout.getBoundingClientRect().width;
    };
    const breakpoint = light.breakpoint as Record<string, number>;
    const expected: Record<string, [number, number]> = {
      // [maxWidth=false, maxWidth=true]
      s: [Math.max(Math.round(breakpoint['m']! * 0.5), vw * 0.25), Math.min(Math.max(Math.round(breakpoint['m']! * 0.5), vw * 0.25), Math.max(Math.round(breakpoint['s']! * 0.7), Math.round(breakpoint['m']! * 0.5)))],
      m: [Math.max(FORM_MAX_WIDTH + 24, vw * 0.5), Math.min(Math.max(FORM_MAX_WIDTH + 24, vw * 0.5), breakpoint['m']!)],
      l: [Math.max(Math.round(breakpoint['m']! * 0.9), vw * 0.75), Math.min(Math.max(Math.round(breakpoint['m']! * 0.9), vw * 0.75), breakpoint['l']!)],
      fill: [vw * 0.9, vw * 0.9]
    };
    for (const size of ['s', 'm', 'l', 'fill']) {
      state.size = size;
      state.maxWidth = false;
      await settled();
      finishAnimations();
      assert.strictEqual($('[data-flyout]'), flyout, `${size}: same element`);
      close(assert, width(), expected[size]![0], `${size} without max width`);
      state.maxWidth = true;
      await settled();
      close(assert, width(), expected[size]![1], `${size} with its max width`);
      close(assert, flyout.getBoundingClientRect().right, vw, `${size}: right edge`);
      close(assert, flyout.getBoundingClientRect().height, window.innerHeight, `${size}: full height`);
    }
    state.size = 'm';
    state.maxWidth = 600;
    await settled();
    close(assert, width(), 600, 'numeric maxWidth');
    state.maxWidth = '30rem';
    await settled();
    close(assert, width(), rem(30), 'CSS maxWidth');
    state.maxWidth = false;
    state.size = 480;
    await settled();
    close(assert, width(), 480, 'numeric size is px');
    state.size = '40vw';
    await settled();
    close(assert, width(), vw * 0.4, 'CSS width');
    assert.dom(flyout).hasStyle({
      position: 'fixed',
      top: '0px',
      display: 'flex',
      flexDirection: 'column',
      backgroundColor: rgb(light.colors.backgroundBasePlain),
      color: rgb(light.colors.textParagraph),
      zIndex: String(light.levels.flyout)
    });
    assert.notStrictEqual(css(flyout).boxShadow, 'none', 'overlay shadow');
  });

  test('EuiFlyout: padding sizes reach header, body, banner and footer', async function (assert) {
    class State {
      @tracked padding: 'none' | 's' | 'm' | 'l' | undefined = undefined;
    }
    const state = new State();
    await render(
      <template>
        <EuiFlyout @onClose={{noop}} @paddingSize={{state.padding}} data-flyout>
          <EuiFlyoutHeader @hasBorder={{true}} data-header>Header</EuiFlyoutHeader>
          <EuiFlyoutBody data-body>
            <:banner><span>Banner</span></:banner>
            <:default><p style="height: 3000px">Body</p></:default>
          </EuiFlyoutBody>
          <EuiFlyoutFooter data-footer>Footer</EuiFlyoutFooter>
        </EuiFlyout>
      </template>
    );
    const sizes = { none: 0, s: SIZE('s'), m: SIZE('base'), l: SIZE('l') };
    const footer = { none: [0, 0], s: [SIZE('s'), SIZE('s')], m: [SIZE('base') * 0.75, SIZE('base')], l: [SIZE('l') / 1.5, SIZE('l')] };
    const header = $('[data-header]');
    for (const size of ['none', 's', 'm', 'l'] as const) {
      state.padding = size === 'l' ? undefined : size;
      await settled();
      const p = `${sizes[size]}px`;
      assert.dom(header).hasStyle({ paddingTop: p, paddingLeft: p, paddingRight: p, paddingBottom: p }, `${size}: header (bordered gets bottom padding)`);
      assert.dom('.euiFlyoutBody__overflowContent', document.body).hasStyle({ padding: p }, `${size}: body`);
      assert.dom('.euiFlyoutBody__banner', document.body).hasStyle({ paddingTop: p, paddingLeft: p, paddingRight: p }, `${size}: banner`);
      assert.dom('[data-footer]', document.body).hasStyle({
        paddingTop: `${footer[size][0]}px`,
        paddingLeft: `${footer[size][1]}px`
      }, `${size}: footer`);
    }
    assert.strictEqual($('[data-header]'), header, 'same header');
    assert.dom(header).hasStyle({ borderBottomWidth: '1px', borderBottomStyle: 'solid', borderBottomColor: borderColor(light.border.thin), flexShrink: '0' });
    assert.dom('[data-footer]', document.body).hasStyle({ backgroundColor: rgb(light.components.flyoutFooterBackground), flexShrink: '0', borderTopWidth: '0px' });
    const overflow = $('.euiFlyoutBody__overflow');
    assert.dom(overflow).hasAttribute('tabindex', '0').hasStyle({ overflowY: 'auto' });
    assert.true(overflow.scrollHeight > overflow.clientHeight, 'long bodies scroll inside the body');
    const content = $('.euiFlyout__content');
    assert.dom(content).hasStyle({ display: 'flex', flexDirection: 'column', overflowY: 'auto' });
    const flyout = $('[data-flyout]');
    close(assert, $('[data-footer]').getBoundingClientRect().bottom, flyout.getBoundingClientRect().bottom, 'footer pinned to the bottom');

    await render(
      <template>
        <EuiFlyout @onClose={{noop}}>
          <EuiFlyoutHeader data-header>H</EuiFlyoutHeader>
          <EuiFlyoutBody @scrollableTabIndex={{-1}}><:content>c</:content></EuiFlyoutBody>
        </EuiFlyout>
      </template>
    );
    assert.dom('[data-header]', document.body).hasStyle({ paddingBottom: '0px', borderBottomWidth: '0px' }, 'no border, no bottom padding');
    assert.dom('.euiFlyoutBody__overflow', document.body).hasAttribute('tabindex', '-1');
    assert.dom('.euiFlyoutBody__overflowContent', document.body).hasText('c', '<:content> block');
  });

  test('EuiFlyout: sides, RTL mirroring, close button positions and animations', async function (assert) {
    class State {
      @tracked side: 'left' | 'right' = 'right';
      @tracked position: 'inside' | 'outside' = 'inside';
    }
    const state = new State();
    let extra = 0;
    const closeButtonProps = { className: 'my-close', onClick: () => extra++ };
    let closed = 0;
    const onClose = () => closed++;
    await render(
      <template>
        <EuiFlyout @onClose={{onClose}} @side={{state.side}} @closeButtonPosition={{state.position}} @closeButtonProps={{closeButtonProps}} data-flyout>x</EuiFlyout>
      </template>
    );
    const flyout = $('[data-flyout]');
    const button = () => $('.euiFlyout__closeButton');
    const vw = viewport();
    const rect = () => {
      finishAnimations();
      return flyout.getBoundingClientRect();
    };
    close(assert, rect().right, vw, 'right side');
    let b = button().getBoundingClientRect();
    close(assert, rect().right - b.right, SIZE('s'), 'inside: inline end inset');
    close(assert, b.top - rect().top, SIZE('s'), 'inside: top inset');
    assert.dom(button()).hasClass('my-close').hasAttribute('data-test-subj', 'euiFlyoutCloseButton').hasStyle({ backgroundColor: 'rgba(0, 0, 0, 0)' });
    assert.dom(button().parentElement!).hasClass('euiFlyout__closeButtonWrapper').hasStyle({ position: 'absolute', zIndex: '3' });
    const rules = animationGuarded(assert, flyout, 'flyout');
    assert.true(rules.some((rule) => !rule.media && /animation:[^;]*0s/.test(rule.text)), 'without motion the animation has no duration');

    state.position = 'outside';
    await settled();
    b = button().getBoundingClientRect();
    close(assert, rect().left - b.right, SIZE('l'), 'outside: left of a right flyout');
    assert.notStrictEqual(css(button()).backgroundColor, 'rgba(0, 0, 0, 0)', 'outside: filled');

    state.side = 'left';
    await settled();
    assert.strictEqual($('[data-flyout]'), flyout, 'same element');
    close(assert, rect().left, 0, 'left side');
    b = button().getBoundingClientRect();
    close(assert, b.left - rect().right, SIZE('l'), 'outside: right of a left flyout');

    await click(button());
    assert.strictEqual(closed, 1);
    assert.strictEqual(extra, 1, 'closeButtonProps.onClick');

    state.position = 'inside';
    state.side = 'right';
    document.documentElement.setAttribute('dir', 'rtl');
    await settled();
    close(assert, rect().left, 0, 'RTL: the "right" (inline end) flyout sits on the left');
    b = button().getBoundingClientRect();
    close(assert, b.left - rect().left, SIZE('s'), 'RTL: close button at the inline end');
    state.side = 'left';
    await settled();
    close(assert, rect().right, vw, 'RTL: the "left" flyout sits on the right');
  });

  test('EuiFlyout: z-index against mask and header, fixed header offset', async function (assert) {
    class State {
      @tracked location: 'above' | 'below' = 'below';
    }
    const state = new State();
    document.documentElement.style.setProperty('--euiFixedHeadersOffset', '48px');
    await render(
      <template>
        <EuiFlyout @onClose={{noop}} @maskProps={{hash headerZindexLocation=state.location}} data-flyout>x</EuiFlyout>
      </template>
    );
    const flyout = $('[data-flyout]');
    const mask = $('.euiOverlayMask');
    const header = Number(light.levels.header);
    assert.dom(flyout).hasStyle({ zIndex: String(light.levels.flyout), top: '48px' });
    assert.dom(mask).hasAttribute('data-relative-to-header', 'below').hasStyle({ zIndex: String(Number(light.levels.flyout) - 2), top: '48px' });
    assert.true(Number(css(mask).zIndex) < header, 'below: the header stays above the mask');
    assert.false(mask.contains(flyout), 'mask and flyout are siblings (upstream)');
    assert.true(Number(css(flyout).zIndex) > Number(css(mask).zIndex));

    state.location = 'above';
    await settled();
    assert.strictEqual($('[data-flyout]'), flyout, 'same element');
    assert.dom(flyout).hasStyle({ zIndex: String(light.levels.mask) });
    const aboveMask = $('.euiOverlayMask');
    assert.dom(aboveMask).hasAttribute('data-relative-to-header', 'above').hasStyle({ zIndex: String(Number(light.levels.mask) - 2) });
    assert.true(Number(css(aboveMask).zIndex) > header, 'above: the mask covers the header');
  });

  test('EuiFlyout: push type pads the body, cleans up, and stays non-modal', async function (assert) {
    class State {
      @tracked side: 'left' | 'right' = 'right';
      @tracked size: string | number = 400;
      @tracked open = true;
      @tracked second = false;
    }
    const state = new State();
    let closed = 0;
    const onClose = () => closed++;
    document.body.style.paddingInlineEnd = '7px';
    await render(
      <template>
        {{#if state.open}}
          <EuiFlyout @type="push" @pushMinBreakpoint="xs" @side={{state.side}} @size={{state.size}} @onClose={{onClose}} data-flyout>
            <EuiFlyoutBody>Body</EuiFlyoutBody>
          </EuiFlyout>
        {{/if}}
        {{#if state.second}}
          <EuiFlyout @type="push" @pushMinBreakpoint="xs" @size={{600}} @onClose={{onClose}} data-second>2</EuiFlyout>
        {{/if}}
      </template>
    );
    const flyout = el(this.element, '[data-flyout]');
    const width = () => flyout.offsetWidth;
    await waitUntil(() => document.body.style.paddingInlineEnd !== '7px', { timeout: 2000 });
    close(assert, parseFloat(document.body.style.paddingInlineEnd), width(), 'body padded by the border-box width');
    assert.strictEqual(document.documentElement.style.getPropertyValue('--euiPushFlyoutOffsetInlineEnd'), document.body.style.paddingInlineEnd, 'offset variable');
    assert.dom('.euiOverlayMask', document.body).doesNotExist('no mask');
    assert.true(this.element.contains(flyout), 'rendered in place, not in a portal');
    assert.dom(flyout).doesNotHaveAttribute('role').doesNotHaveAttribute('aria-modal').doesNotHaveAttribute('tabindex').doesNotHaveAttribute('aria-describedby');
    assert.dom(flyout).hasStyle({
      borderLeftWidth: '1px',
      borderLeftColor: borderColor(light.border.thin),
      boxShadow: 'none',
      zIndex: String(light.levels.flyout),
      animationDuration: '0s'
    });
    await triggerKeyEvent(flyout, 'keydown', 'Escape');
    assert.strictEqual(closed, 0, 'Escape does not close a pushed flyout (upstream)');

    state.size = 500;
    await waitUntil(() => Math.abs(parseFloat(document.body.style.paddingInlineEnd) - width()) < 1 && width() > 450, { timeout: 2000 });
    assert.strictEqual(el(this.element, '[data-flyout]'), flyout, 'resizing keeps the element');
    close(assert, parseFloat(document.body.style.paddingInlineEnd), width(), 'padding follows the width');

    state.second = true;
    await settled();
    const second = el(this.element, '[data-second]');
    await waitUntil(() => parseFloat(document.body.style.paddingInlineEnd) > width() + 1, { timeout: 2000 });
    close(assert, parseFloat(document.body.style.paddingInlineEnd), second.offsetWidth, 'two pushed flyouts: the widest wins');
    state.second = false;
    await settled();
    close(assert, parseFloat(document.body.style.paddingInlineEnd), width(), 'back to the remaining flyout');

    state.side = 'left';
    await waitUntil(() => document.body.style.paddingInlineStart !== '', { timeout: 2000 });
    assert.strictEqual(document.body.style.paddingInlineEnd, '7px', 'the end side is restored');
    close(assert, parseFloat(document.body.style.paddingInlineStart), el(this.element, '[data-flyout]').offsetWidth, 'left pushes the inline start');
    assert.dom('[data-flyout]', document.body).hasStyle({ borderRightWidth: '1px' });

    state.open = false;
    await settled();
    assert.strictEqual(document.body.style.paddingInlineStart, '', 'start padding removed');
    assert.strictEqual(document.body.style.paddingInlineEnd, '7px', "the app's own padding is restored");
    assert.strictEqual(document.documentElement.style.getPropertyValue('--euiPushFlyoutOffsetInlineStart'), '', 'variable removed');
    assert.dom(document.body).doesNotHaveClass('euiBody--hasFlyout');

    await render(
      <template>
        <EuiFlyout @type="push" @pushMinBreakpoint={{100000}} @onClose={{onClose}} data-flyout>x</EuiFlyout>
      </template>
    );
    assert.dom('.euiOverlayMask', document.body).exists('below the push breakpoint it is an overlay');
    assert.dom('[data-flyout]', document.body).hasAttribute('role', 'dialog');
    assert.strictEqual(document.body.style.paddingInlineEnd, '7px', 'no padding');
  });

  test('EuiFlyout: Escape, mask and outside clicks, dialog semantics and body class', async function (assert) {
    class State {
      @tracked outside: boolean | undefined = undefined;
      @tracked ownFocus = true;
    }
    const state = new State();
    let closed = 0;
    const onClose = () => closed++;
    await render(
      <template>
        <button type="button" data-outside>outside</button>
        <EuiFlyout @onClose={{onClose}} @ownFocus={{state.ownFocus}} @outsideClickCloses={{state.outside}} aria-labelledby="t" data-flyout>
          <EuiFlyoutHeader><h2 id="t">Title</h2></EuiFlyoutHeader>
          <EuiFlyoutBody><button type="button" data-inside>in</button></EuiFlyoutBody>
        </EuiFlyout>
      </template>
    );
    const flyout = $('[data-flyout]');
    assert.dom(flyout).hasAttribute('role', 'dialog').hasAttribute('aria-modal', 'true').hasAttribute('tabindex', '0').hasAttribute('aria-labelledby', 't');
    const description = document.getElementById(flyout.getAttribute('aria-describedby')!)!;
    assert.dom(description).hasText('You are in a modal dialog. Press Escape or tap/click outside the dialog on the shadowed overlay to close.');
    assert.dom(document.body).hasClass('euiBody--hasFlyout');
    await waitUntil(() => document.activeElement === flyout, { timeout: 2000 });
    assert.strictEqual(document.activeElement, flyout, 'focuses itself');

    await triggerKeyEvent($('[data-inside]'), 'keydown', 'Escape');
    assert.strictEqual(closed, 1, 'Escape');
    await click($('.euiOverlayMask'));
    assert.strictEqual(closed, 2, 'mask click closes by default');
    state.outside = false;
    await settled();
    await click($('.euiOverlayMask'));
    assert.strictEqual(closed, 2, 'outsideClickCloses=false keeps it open');

    state.ownFocus = false;
    state.outside = undefined;
    await settled();
    const unmasked = $('[data-flyout]');
    assert.dom('.euiOverlayMask', document.body).doesNotExist();
    assert.dom(document.getElementById(unmasked.getAttribute('aria-describedby')!)!).hasText('You are in a modal dialog. To close the dialog, press Escape.');
    await triggerEvent($('[data-outside]'), 'mousedown');
    await triggerEvent($('[data-outside]'), 'mouseup');
    assert.strictEqual(closed, 2, 'no mask: outside clicks do not close by default');
    state.outside = true;
    await settled();
    await triggerEvent($('[data-inside]'), 'mousedown');
    await triggerEvent($('[data-inside]'), 'mouseup');
    assert.strictEqual(closed, 2, 'inside clicks never close');
    await triggerEvent($('[data-outside]'), 'mousedown');
    await triggerEvent($('[data-outside]'), 'mouseup');
    assert.strictEqual(closed, 3, 'no mask + outsideClickCloses: outside clicks close');

    await clearRender();
    assert.dom(document.body).doesNotHaveClass('euiBody--hasFlyout', 'body class removed with the last flyout');

    await render(<template><EuiFlyout @role={{null}} data-flyout>x</EuiFlyout></template>);
    assert.dom('[data-flyout]', document.body).doesNotHaveAttribute('role').doesNotHaveAttribute('aria-modal');
    assert.dom('.euiFlyout__closeButton', document.body).doesNotExist('no close button without @onClose');
  });

  test('light/dark nearest provider, sibling isolation, portalled content and JS-object overrides', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
      @tracked overrides: EuiBorealisOverrides = {};
    }
    const state = new State();
    const nested = {
      size: { l: '30px' },
      border: { radius: { frame: '4px' } },
      levels: { flyout: 1500 }
    } as unknown as EuiBorealisOverrides;
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}} @borealisOverrides={{state.overrides}} @globalStyles={{false}}>
          <EuiFlyout @onClose={{noop}} @ownFocus={{false}} data-outer>
            <EuiFlyoutHeader>o</EuiFlyoutHeader>
            <EuiFlyoutFooter data-outer-footer>f</EuiFlyoutFooter>
          </EuiFlyout>
          <EuiEmotionProvider @colorMode="dark" @borealisOverrides={{nested}}>
            <EuiFlyout @onClose={{noop}} data-dark>
              <EuiFlyoutHeader data-dark-header>d</EuiFlyoutHeader>
              <EuiFlyoutFooter data-dark-footer>f</EuiFlyoutFooter>
            </EuiFlyout>
            <EuiModal @onClose={{noop}} data-dark-modal>
              <EuiModalHeader data-dark-modal-header><EuiModalHeaderTitle>t</EuiModalHeaderTitle></EuiModalHeader>
            </EuiModal>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light" @globalStyles={{false}}>
          <EuiModal @onClose={{noop}} data-sibling-modal>s</EuiModal>
        </EuiEmotionProvider>
      </template>
    );
    const outer = $('[data-outer]');
    assert.false(this.element.contains(outer), 'flyouts are portalled to <body>');
    assert.dom(outer).hasStyle({ backgroundColor: rgb(light.colors.backgroundBasePlain), color: rgb(light.colors.textParagraph) });
    assert.dom('[data-outer-footer]', document.body).hasStyle({ backgroundColor: rgb(light.components.flyoutFooterBackground) });
    assert.dom('[data-dark]', document.body).hasStyle({ backgroundColor: rgb(dark.colors.backgroundBasePlain), color: rgb(dark.colors.textParagraph), zIndex: '1500' });
    assert.dom('[data-dark-footer]', document.body).hasStyle({ backgroundColor: rgb(dark.components.flyoutFooterBackground) });
    assert.dom('[data-dark-header]', document.body).hasStyle({ paddingTop: '30px' }, 'nested override: size.l');
    assert.strictEqual(css(document.querySelectorAll('.euiOverlayMask')[0]!).zIndex, '1498', 'mask follows the overridden flyout level');
    assert.dom('[data-dark-modal]', document.body).hasStyle({ backgroundColor: rgb(dark.colors.backgroundBasePlain), color: rgb(dark.colors.textParagraph), borderTopLeftRadius: '4px' });
    assert.dom('[data-dark-modal-header]', document.body).hasStyle({ paddingTop: '30px', paddingLeft: '30px' });
    assert.dom('[data-sibling-modal]', document.body).hasStyle({ backgroundColor: rgb(light.colors.backgroundBasePlain), borderTopLeftRadius: light.border.radius.frame });

    state.mode = 'dark';
    state.overrides = { size: { l: '10px' } } as EuiBorealisOverrides;
    await settled();
    assert.strictEqual($('[data-outer]'), outer, 'same element');
    assert.dom(outer).hasStyle({ backgroundColor: rgb(dark.colors.backgroundBasePlain), color: rgb(dark.colors.textParagraph) });
    assert.dom('[data-outer] .euiFlyoutHeader', document.body).hasStyle({ paddingTop: '10px' });
    assert.dom('[data-dark-header]', document.body).hasStyle({ paddingTop: '30px' }, 'the nearest provider wins');
    assert.dom('[data-sibling-modal]', document.body).hasStyle({ backgroundColor: rgb(light.colors.backgroundBasePlain) }, 'sibling untouched');
    state.overrides = {};
    state.mode = 'light';
    await settled();
    assert.dom('[data-outer] .euiFlyoutHeader', document.body).hasStyle({ paddingTop: light.size.l });
  });

  test('high contrast: flyout and footer borders', async function (assert) {
    class State {
      @tracked contrast: EuiBorealisHighContrastMode = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider @highContrastMode={{state.contrast}} @globalStyles={{false}}>
          <EuiFlyout @onClose={{noop}} data-flyout>
            <EuiFlyoutFooter data-footer>f</EuiFlyoutFooter>
          </EuiFlyout>
          <EuiModal @onClose={{noop}} data-modal>m</EuiModal>
        </EuiEmotionProvider>
      </template>
    );
    assert.dom('[data-footer]', document.body).hasStyle({ borderTopWidth: '0px' });
    assert.dom('[data-flyout]', document.body).hasStyle({ borderTopWidth: '0px' });
    assert.notStrictEqual(css($('[data-flyout]')).boxShadow, 'none');
    state.contrast = 'preferred';
    await settled();
    const hc = resolveBorealisTheme('light', {}, 'preferred').euiTheme;
    assert.dom('[data-footer]', document.body).hasStyle({ borderTopWidth: '1px', borderTopColor: borderColor(hc.border.thin) });
    assert.dom('[data-flyout]', document.body).hasStyle({ borderTopWidth: '1px', borderLeftWidth: '1px', borderRightWidth: '1px', boxShadow: 'none' }, 'overlay flyouts get a full border instead of a shadow');
    assert.dom('[data-modal]', document.body).hasStyle({ borderBottomWidth: '1px', boxShadow: 'none' });
  });
});
