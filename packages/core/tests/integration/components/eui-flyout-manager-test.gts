import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import {
  click,
  render,
  settled,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';

import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiFlyout from '#src/components/eui-flyout.gts';
import EuiFlyoutBody from '#src/components/eui-flyout-body.gts';
import EuiFlyoutMenu from '#src/components/eui-flyout-menu.gts';
import { euiFlyoutManager } from '#src/-private/eui-flyout-context.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiFlyoutCloseMeta } from '#src/components/eui-flyout.gts';
import type EuiFlyoutManagerService from '#src/services/eui-flyout-manager.ts';

const light = resolveBorealisTheme('light').euiTheme;
const FLYOUT_LEVEL = Number(light.levels.flyout);

const $ = (selector: string): HTMLElement => {
  const element = document.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
};

const level = (name: 'main' | 'child') =>
  document.querySelectorAll<HTMLElement>(
    `[data-managed-flyout-level="${name}"]`
  );

class Flyouts {
  @tracked a = false;
  @tracked b = false;
  @tracked c = false;
  @tracked child = false;
  closes: Array<[string, string | undefined]> = [];
  actives: string[] = [];

  closer = (name: 'a' | 'b' | 'c' | 'child') => (_event?: Event, meta?: EuiFlyoutCloseMeta) => {
    this.closes.push([name, meta?.reason]);
    this[name] = false;
  };
  closeA = this.closer('a');
  closeB = this.closer('b');
  closeC = this.closer('c');
  closeChild = this.closer('child');
  activeA = () => this.actives.push('a');
  openChild = () => (this.child = true);
}

/** Waits for the flyouts to register, measure and settle their stages. */
async function managed() {
  await settled();
  await waitUntil(
    () =>
      document
        .getAnimations()
        .every((animation) => animation.playState !== 'running'),
    { timeout: 3000 }
  );
  await new Promise((resolve) => requestAnimationFrame(() => setTimeout(resolve, 30)));
  await settled();
}

module('Integration | Component | EuiFlyout session management', function (hooks) {
  setupRenderingTest(hooks);

  let manager: EuiFlyoutManagerService;

  hooks.beforeEach(function () {
    manager = euiFlyoutManager(this);
  });

  test('a standard flyout is not managed; session="start" opens a session', async function (assert) {
    const state = new Flyouts();
    state.a = true;
    state.b = true;

    await render(
      <template>
        <EuiEmotionProvider>
          {{#if state.a}}
            <EuiFlyout @onClose={{state.closeA}} data-test-subj="standard">a</EuiFlyout>
          {{/if}}
          {{#if state.b}}
            <EuiFlyout
              @session="start"
              @size="s"
              @flyoutMenuProps={{hash title="Flyout B"}}
              @onClose={{state.closeB}}
              data-test-subj="main"
            >b</EuiFlyout>
          {{/if}}
        </EuiEmotionProvider>
      </template>
    );
    await managed();

    assert.dom('[data-test-subj="standard"]', document.body).doesNotHaveAttribute('data-managed-flyout');
    assert
      .dom('[data-test-subj="main"]', document.body)
      .hasAttribute('data-managed-flyout', 'true')
      .hasAttribute('data-managed-flyout-level', 'main')
      .hasAttribute('data-managed-flyout-layout-mode', 'side-by-side')
      .hasAttribute('role', 'dialog')
      .hasAttribute('aria-modal', 'true');
    assert.strictEqual(manager.state.sessions.length, 1);
    assert.strictEqual(manager.state.sessions[0]!.title, 'Flyout B', 'the session is titled by flyoutMenuProps.title');
    assert.deepEqual(manager.state.unmanagedFlyouts.length, 1, 'the standard flyout is tracked for z-index only');
    assert.strictEqual(
      manager.state.flyouts[0]!.activityStage,
      'active',
      'the opening animation activates the main flyout'
    );
    assert.dom('[data-test-subj="main"] [data-test-subj="euiFlyoutMenu"]', document.body).doesNotExist('a hidden title alone renders no menu');
    assert.dom('[data-test-subj="main"] .euiFlyout__closeButton', document.body).exists();

    await click($('[data-test-subj="main"] .euiFlyout__closeButton'));
    await managed();
    assert.deepEqual(state.closes, [['b', 'close-button']]);
    assert.strictEqual(manager.state.sessions.length, 0, 'closing removes the session');
    assert.dom('[data-test-subj="standard"]', document.body).exists('the standard flyout is untouched');
  });

  test('a nested flyout becomes the child, beside the main flyout', async function (assert) {
    const state = new Flyouts();
    state.a = true;

    await render(
      <template>
        <EuiEmotionProvider>
          {{#if state.a}}
            <EuiFlyout @session="start" @size="m" aria-label="Main A" @onClose={{state.closeA}}>
              <EuiFlyoutBody>
                <button type="button" class="open-child" {{on "click" state.openChild}}>Open child</button>
              </EuiFlyoutBody>
              {{#if state.child}}
                <EuiFlyout @size="s" @hasChildBackground={{true}} @flyoutMenuProps={{hash title="Child"}} @onClose={{state.closeChild}}>
                  <EuiFlyoutBody><button type="button" class="in-child">In child</button></EuiFlyoutBody>
                </EuiFlyout>
              {{/if}}
            </EuiFlyout>
          {{/if}}
        </EuiEmotionProvider>
      </template>
    );
    await managed();

    assert.strictEqual(manager.state.sessions[0]!.title, 'Main A', 'aria-label titles the session');
    assert.strictEqual(document.activeElement, level('main')[0], 'the main flyout takes focus');

    await click($('.open-child'));
    await managed();

    const main = level('main')[0]!;
    const child = level('child')[0]!;
    assert.ok(child, 'the nested flyout is a child');
    assert.strictEqual(manager.state.sessions[0]!.childFlyoutId, child.id);
    assert.strictEqual(manager.state.sessions[0]!.childTitle, 'Child');

    const mainRect = main.getBoundingClientRect();
    const childRect = child.getBoundingClientRect();
    assert.true(Math.abs(childRect.right - mainRect.left) <= 1, `the child sits beside the main flyout (${childRect.right} / ${mainRect.left})`);
    assert.strictEqual(getComputedStyle(child).zIndex, String(FLYOUT_LEVEL - 1), 'the child sits one level below its main flyout');
    assert.strictEqual(getComputedStyle(main).zIndex, String(FLYOUT_LEVEL));
    assert.strictEqual(getComputedStyle(main).borderInlineStartWidth, light.border.width.thin, 'the main flyout gets a border towards its child');
    assert.strictEqual(getComputedStyle(main).boxShadow, 'none');
    assert.dom(child).hasClass('euiFlyout--hasChildBackground');
    assert.strictEqual(getComputedStyle(child).backgroundColor, getComputedStyle($('.euiFlyout--hasChildBackground')).backgroundColor);
    assert.dom(child).doesNotHaveAttribute('role', 'a side-by-side child defers the dialog role to its main flyout');
    assert.dom(child).doesNotHaveAttribute('aria-modal');
    assert.dom('.euiOverlayMask', document.body).exists({ count: 1 }, 'only the main flyout has a mask');
    assert.dom('[data-test-subj="euiFlyoutMenu"]', child).doesNotExist('a child has no history: its hidden title alone renders no menu');
    assert.dom('.euiFlyout__closeButton', child).exists();
    assert.true(child.contains(document.activeElement), 'focus moves into the child');

    await triggerKeyEvent(document, 'keydown', 'Escape');
    await managed();
    assert.deepEqual(state.closes, [['child', 'escape']], 'Escape closes only the child');
    assert.dom('[data-managed-flyout-level="child"]', document.body).doesNotExist();
    assert.strictEqual(document.activeElement, $('.open-child'), 'focus returns to the opener');

    await click($('.open-child'));
    await managed();
    await click($(`#${level('main')[0]!.id} > .euiFlyout__closeButton`));
    await managed();
    assert.deepEqual(
      state.closes.slice(1),
      [
        ['a', 'close-button'],
        ['child', 'navigation-cascade']
      ],
      'closing the main flyout closes its child'
    );
    assert.strictEqual(manager.state.flyouts.length, 0);
  });

  test('a new main flyout replaces the old one; Back returns to it', async function (assert) {
    const state = new Flyouts();
    const key = Symbol('journey');
    state.a = true;

    await render(
      <template>
        <EuiEmotionProvider>
          {{#if state.a}}
            <EuiFlyout @session="start" @historyKey={{key}} @flyoutMenuProps={{hash title="Flyout A" iconType="bell"}} @onActive={{state.activeA}} @onClose={{state.closeA}} data-test-subj="a">a</EuiFlyout>
          {{/if}}
          {{#if state.b}}
            <EuiFlyout @session="start" @historyKey={{key}} @flyoutMenuProps={{hash title="Flyout B"}} @onClose={{state.closeB}} data-test-subj="b">b</EuiFlyout>
          {{/if}}
          {{#if state.c}}
            <EuiFlyout @session="start" @historyKey={{key}} @flyoutMenuProps={{hash title="Flyout C"}} @onClose={{state.closeC}} data-test-subj="c">c</EuiFlyout>
          {{/if}}
        </EuiEmotionProvider>
      </template>
    );
    await managed();
    state.actives = [];

    state.b = true;
    await managed();

    const a = $('[data-test-subj="a"]');
    const b = $('[data-test-subj="b"]');
    assert.notStrictEqual(getComputedStyle(a).transform, 'none', 'the previous main flyout moves out of view');
    assert.true(a.getBoundingClientRect().left >= window.innerWidth, 'it is off screen');
    assert.strictEqual(manager.state.flyouts.find((f) => f.flyoutId === a.id)?.activityStage, 'inactive');
    assert.dom('[data-test-subj="euiFlyoutMenu"]', b).exists('the history adds a menu');
    assert.dom('[data-test-subj="euiFlyoutMenuBackButton"]', b).hasText('Back');
    assert.dom('[data-test-subj="euiFlyoutMenuHistoryButton"]', b).doesNotExist('one entry has no history popover');
    assert.dom(b).hasAttribute('aria-labelledby', /-menuTitle/, 'the menu title labels the flyout');
    assert.true(b.getAttribute('style')!.includes(`z-index: ${FLYOUT_LEVEL + 3}`), 'each session stacks 3 levels higher');

    await click($('[data-test-subj="b"] [data-test-subj="euiFlyoutMenuBackButton"]'));
    await managed();
    assert.deepEqual(state.closes, [['b', 'navigation-back']], 'Back closes B with its reason');
    assert.dom('[data-test-subj="b"]', document.body).doesNotExist();
    assert.strictEqual(getComputedStyle(a).transform, 'none', 'A is back in view');
    assert.deepEqual(state.actives, ['a'], 'A reports it is active again');

    // history popover: A, B, C
    state.b = true;
    await managed();
    state.c = true;
    await managed();
    const c = $('[data-test-subj="c"]');
    assert.dom('[data-test-subj="euiFlyoutMenuHistoryButton"]', c).exists();
    await click($('[data-test-subj="c"] [data-test-subj="euiFlyoutMenuHistoryButton"]'));
    assert.dom('[data-test-subj="euiFlyoutMenuHistoryItem-0"]', document.body).hasText('Flyout B');
    assert.dom('[data-test-subj="euiFlyoutMenuHistoryItem-1"]', document.body).hasText('Flyout A');
    assert.dom('[data-test-subj="euiFlyoutMenuHistoryItem-1"] [data-icon-type="bell"]', document.body).exists('the session icon');
    await click($('[data-test-subj="euiFlyoutMenuHistoryItem-1"]'));
    await managed();
    assert.deepEqual(
      state.closes.slice(1).sort(),
      [
        ['b', 'navigation-cascade'],
        ['c', 'navigation-cascade']
      ],
      'jumping to A closes the newer sessions'
    );
    assert.dom('[data-test-subj="a"]', document.body).exists();
    assert.strictEqual(manager.state.sessions.length, 1);
  });

  test('historyKey scopes the history and closing', async function (assert) {
    const state = new Flyouts();
    const alerts = Symbol('alerts');
    const logs = Symbol('logs');
    state.a = true;
    state.b = true;

    await render(
      <template>
        <EuiEmotionProvider>
          {{#if state.a}}
            <EuiFlyout @session="start" @ownFocus={{false}} @historyKey={{alerts}} aria-label="Alerts" @onClose={{state.closeA}} data-test-subj="a">a</EuiFlyout>
          {{/if}}
          {{#if state.b}}
            <EuiFlyout @session="start" @ownFocus={{false}} @historyKey={{logs}} aria-label="Logs" @onClose={{state.closeB}} data-test-subj="b">b</EuiFlyout>
          {{/if}}
        </EuiEmotionProvider>
      </template>
    );
    await managed();

    assert.deepEqual(manager.historyItems, [], 'another group is not history');
    assert.dom('[data-test-subj="b"] [data-test-subj="euiFlyoutMenu"]', document.body).doesNotExist();
    await click($('[data-test-subj="b"] .euiFlyout__closeButton'));
    await managed();
    assert.deepEqual(state.closes, [['b', 'close-button']], 'closing B keeps the other group');
    assert.strictEqual(manager.state.sessions.length, 1);
    assert.strictEqual(getComputedStyle($('[data-test-subj="a"]')).transform, 'none');
  });

  test('a narrow container stacks the child over its main flyout', async function (assert) {
    const state = new Flyouts();
    state.a = true;
    state.child = true;
    // outside the scaled test container, like an app area
    const narrow = document.createElement('div');
    narrow.id = 'narrow-app';
    narrow.setAttribute('style', 'position: fixed; top: 40px; left: 0; width: 700px; height: 500px;');
    document.body.appendChild(narrow);

    await render(
      <template>
        <EuiEmotionProvider>
          {{#if state.a}}
            <EuiFlyout @session="start" @container={{narrow}} @size="m" aria-label="Main" @onClose={{state.closeA}}>
              {{#if state.child}}
                <EuiFlyout @size="s" @session="inherit" @container="#narrow-app" aria-label="Child" @onClose={{state.closeChild}}>child</EuiFlyout>
              {{/if}}
            </EuiFlyout>
          {{/if}}
        </EuiEmotionProvider>
      </template>
    );
    await managed();
    await managed();

    const main = level('main')[0]!;
    const child = level('child')[0]!;
    assert.strictEqual(manager.state.layoutMode, 'stacked');
    assert.dom(main).hasAttribute('data-managed-flyout-layout-mode', 'stacked');
    assert.strictEqual(manager.state.flyouts.find((f) => f.flyoutId === main.id)?.activityStage, 'backgrounded', 'the main flyout is backgrounded');
    assert.notStrictEqual(getComputedStyle(main).transform, 'none');
    assert.dom(child).hasAttribute('role', 'dialog', 'a stacked child is its own dialog');
    assert.dom(child).hasAttribute('aria-modal', 'true');
    const rect = child.getBoundingClientRect();
    assert.strictEqual(Math.round(rect.top), 40, 'the container bounds the flyout');
    assert.strictEqual(Math.round(rect.height), 500);
    assert.true(Math.abs(rect.right - 700) <= 1, `aligned to the container's edge (${rect.right})`);

    state.child = false;
    await managed();
    assert.strictEqual(manager.state.flyouts.find((f) => f.flyoutId === main.id)?.activityStage, 'active', 'the main flyout returns');
    assert.strictEqual(getComputedStyle(main).transform, 'none');
    narrow.remove();
  });

  test('flyoutMenuProps and flyoutMenuDisplayMode on a standard flyout', async function (assert) {
    const state = new Flyouts();
    state.a = true;
    let shared = 0;
    const actions = [{ iconType: 'share', ariaLabel: 'Share', onClick: () => shared++ }];
    const mode = new (class {
      @tracked value: 'auto' | 'always' = 'auto';
      @tracked withActions = true;
    })();

    await render(
      <template>
        <EuiEmotionProvider>
          {{#if state.a}}
            <EuiFlyout
              @flyoutMenuProps={{hash title="Details" trailingActions=(if mode.withActions actions)}}
              @flyoutMenuDisplayMode={{mode.value}}
              @onClose={{state.closeA}}
              aria-labelledby="own-label"
            >
              <h2 id="own-label">Own label</h2>
            </EuiFlyout>
          {{/if}}
        </EuiEmotionProvider>
      </template>
    );

    const flyout = $('.euiFlyout');
    assert.dom('[data-test-subj="euiFlyoutMenu"]', flyout).exists('actions give the menu content');
    const titleId = $('.euiFlyoutMenu h3').id;
    assert.ok(titleId);
    assert.dom(flyout).hasAttribute('aria-labelledby', `${titleId} own-label`, 'the menu title joins the caller label');
    assert.dom('.euiFlyout__closeButton', flyout).exists({ count: 1 }, 'the menu replaces the close button');
    await click($('[aria-label="Share"]'));
    assert.strictEqual(shared, 1);

    mode.withActions = false;
    await settled();
    assert.dom('[data-test-subj="euiFlyoutMenu"]', flyout).doesNotExist('auto: a hidden title alone is no content');
    assert.dom(flyout).hasAttribute('aria-labelledby', 'own-label');

    mode.value = 'always';
    await settled();
    assert.dom('[data-test-subj="euiFlyoutMenu"]', flyout).exists('always renders the menu');
    await click($('.euiFlyoutMenu .euiFlyout__closeButton'));
    assert.deepEqual(state.closes, [['a', 'close-button']]);
  });

  test('a menu placed in the flyout closes it; store pagination wins over the prop', async function (assert) {
    const state = new Flyouts();
    state.a = true;
    state.b = true;
    const own = { currentIndex: 0, total: 3, onPrevious() {}, onNext() {} };

    await render(
      <template>
        <EuiEmotionProvider>
          {{#if state.a}}
            <EuiFlyout @hideCloseButton={{true}} @onClose={{state.closeA}} data-test-subj="a">
              <EuiFlyoutMenu @title="Placed" />
            </EuiFlyout>
          {{/if}}
          {{#if state.b}}
            <EuiFlyout @session="start" @flyoutMenuProps={{hash title="Paged" pagination=own}} @onClose={{state.closeB}} data-test-subj="b">b</EuiFlyout>
          {{/if}}
        </EuiEmotionProvider>
      </template>
    );
    await managed();

    assert.dom('[data-test-subj="b"] .euiFlyoutMenu', document.body).containsText('1 of 3');
    manager.setPagination($('[data-test-subj="b"]').id, { ...own, currentIndex: 1 });
    await settled();
    assert.dom('[data-test-subj="b"] .euiFlyoutMenu', document.body).containsText('2 of 3', 'setPagination overrides flyoutMenuProps.pagination');

    await click($('[data-test-subj="a"] .euiFlyoutMenu .euiFlyout__closeButton'));
    assert.deepEqual(state.closes, [['a', 'close-button']]);
  });

  test('session="never" stays standard inside a managed flyout', async function (assert) {
    const state = new Flyouts();
    state.a = true;

    await render(
      <template>
        <EuiEmotionProvider>
          {{#if state.a}}
            <EuiFlyout @session="start" aria-label="Main" @onClose={{state.closeA}}>
              {{#if state.child}}
                <EuiFlyout @session="never" @onClose={{state.closeChild}} data-test-subj="never">standard</EuiFlyout>
              {{/if}}
            </EuiFlyout>
          {{/if}}
        </EuiEmotionProvider>
      </template>
    );
    await managed();
    state.child = true;
    await managed();

    assert.dom('[data-test-subj="never"]', document.body).doesNotHaveAttribute('data-managed-flyout');
    assert.strictEqual(manager.state.sessions[0]!.childFlyoutId, null);
    assert.true(
      Number(getComputedStyle($('[data-test-subj="never"]')).zIndex) > FLYOUT_LEVEL,
      'a standard flyout opened over a session stacks above it'
    );
  });

  test('focusTrapProps.returnFocus=false keeps focus where the app puts it', async function (assert) {
    const state = new Flyouts();
    const returnFocus = new (class {
      @tracked value: boolean | undefined = false;
    })();

    await render(
      <template>
        <button type="button" class="opener" {{on "click" state.openChild}}>Open</button>
        {{#if state.child}}
          <EuiFlyout @focusTrapProps={{hash returnFocus=returnFocus.value}} @onClose={{state.closeChild}}>
            <button type="button">Inside</button>
          </EuiFlyout>
        {{/if}}
      </template>
    );

    await click($('.opener'));
    assert.true($('.euiFlyout').contains(document.activeElement));
    await triggerKeyEvent(document, 'keydown', 'Escape');
    assert.notStrictEqual(document.activeElement, $('.opener'), 'focus is not returned');

    returnFocus.value = undefined;
    await click($('.opener'));
    await triggerKeyEvent(document, 'keydown', 'Escape');
    await waitUntil(() => document.activeElement === $('.opener'));
    assert.strictEqual(document.activeElement, $('.opener'), 'focus is returned by default');
  });

  test('a container bounds the flyout and its mask; nested flyouts inherit it', async function (assert) {
    const state = new Flyouts();
    const area = document.createElement('div');
    area.setAttribute('style', 'position: fixed; top: 50px; left: 100px; width: 900px; height: 600px;');
    document.body.appendChild(area);
    const size = new (class {
      @tracked value = 's';
    })();
    state.a = true;

    await render(
      <template>
        <EuiEmotionProvider>
          {{#if state.a}}
            <EuiFlyout @container={{area}} @size={{size.value}} @onClose={{state.closeA}} data-test-subj="scoped">
              {{#if state.b}}<EuiFlyout @onClose={{state.closeB}} data-test-subj="inherits">b</EuiFlyout>{{/if}}
              {{#if state.c}}<EuiFlyout @container={{null}} @onClose={{state.closeC}} data-test-subj="viewport">c</EuiFlyout>{{/if}}
            </EuiFlyout>
          {{/if}}
        </EuiEmotionProvider>
      </template>
    );
    await managed();

    const flyout = $('[data-test-subj="scoped"]');
    const rect = flyout.getBoundingClientRect();
    assert.strictEqual(Math.round(rect.top), 50);
    assert.strictEqual(Math.round(rect.height), 600);
    assert.strictEqual(Math.round(rect.right), 1000, 'aligned to the container end');
    assert.strictEqual(flyout.style.inlineSize, '225px', 's is 25% of the container');
    assert.strictEqual(flyout.style.minInlineSize, `${Math.round(Number(light.breakpoint.m) * 0.42)}px`);
    const mask = $('.euiOverlayMask');
    assert.strictEqual(mask.style.insetBlockStart, '50px', 'the mask is clipped to the container');
    assert.strictEqual(mask.style.inlineSize, '900px');

    size.value = 'fill';
    await managed();
    assert.strictEqual(flyout.style.minInlineSize, '0px', 'fill has no min width');
    assert.strictEqual(flyout.style.inlineSize, '810px');

    state.b = true;
    await managed();
    assert.strictEqual(Math.round($('[data-test-subj="inherits"]').getBoundingClientRect().top), 50, 'a nested flyout inherits the container');

    state.b = false;
    state.c = true;
    await managed();
    const viewport = $('[data-test-subj="viewport"]');
    assert.strictEqual(Math.round(viewport.getBoundingClientRect().top), 0, 'container=null uses the viewport');
    assert.true(
      Number(getComputedStyle(viewport).zIndex) >= Number(light.levels.mask),
      'container=null stacks above fixed headers'
    );

    state.a = false;
    await settled();
    area.remove();
  });

  test('a container caps the min width at 90% of a small container', async function (assert) {
    const state = new Flyouts();
    const area = document.createElement('div');
    area.setAttribute('style', 'position: fixed; top: 0; left: 0; width: 300px; height: 300px;');
    document.body.appendChild(area);
    state.a = true;

    await render(
      <template>
        <EuiFlyout @container={{area}} @size="s" @onClose={{state.closeA}} data-test-subj="small">s</EuiFlyout>
      </template>
    );
    await managed();

    assert.strictEqual($('[data-test-subj="small"]').style.minInlineSize, '270px');
    area.remove();
  });

  test('a push flyout in a container pads the container', async function (assert) {
    const state = new Flyouts();
    state.a = true;
    const wide = document.createElement('div');
    wide.id = 'wide-app';
    wide.setAttribute('style', 'position: fixed; top: 0; left: 0; width: 1400px; height: 400px;');
    document.body.appendChild(wide);

    await render(
      <template>
        <EuiEmotionProvider>
          {{#if state.a}}
            <EuiFlyout @type="push" @size={{300}} @container="#wide-app" @onClose={{state.closeA}}>push</EuiFlyout>
          {{/if}}
        </EuiEmotionProvider>
      </template>
    );
    await managed();

    assert.strictEqual($('#wide-app').style.paddingInlineEnd, '300px', 'the container is pushed');
    assert.strictEqual(document.body.style.paddingInlineEnd, '', 'the body is not');

    state.a = false;
    await settled();
    assert.strictEqual($('#wide-app').style.paddingInlineEnd, '');
    wide.remove();
  });
});

module('Integration | Component | EuiFlyout session management (upstream manager tests)', function (hooks) {
  setupRenderingTest(hooks);

  let manager: EuiFlyoutManagerService;

  hooks.beforeEach(function () {
    manager = euiFlyoutManager(this);
  });

  const sessionMainIds = () =>
    manager.state.sessions.map((session) => document.getElementById(session.mainFlyoutId)?.getAttribute('data-test-subj'));

  test('closing a backgrounded main removes only its own session', async function (assert) {
    const state = new Flyouts();
    state.a = true;

    await render(
      <template>
        {{#if state.a}}<EuiFlyout @session="start" aria-label="First" @onClose={{state.closeA}} data-test-subj="first">1</EuiFlyout>{{/if}}
        {{#if state.b}}<EuiFlyout @session="start" aria-label="Second" @onClose={{state.closeB}} data-test-subj="second">2</EuiFlyout>{{/if}}
      </template>
    );
    await managed();
    state.b = true;
    await managed();
    assert.deepEqual(sessionMainIds(), ['first', 'second']);

    state.a = false;
    await managed();
    assert.deepEqual(sessionMainIds(), ['second'], 'the foreground session stays');
    assert.dom('[data-test-subj="second"]', document.body).hasAttribute('data-managed-flyout-level', 'main');
    assert.deepEqual(state.closes, [], 'unrendering a flyout does not call its onClose');

    state.b = false;
    await managed();
    assert.deepEqual(sessionMainIds(), []);
    assert.strictEqual(manager.state.currentZIndex, 0, 'the z-index resets once every flyout is closed');
  });

  test('unrendering the foreground main still closes the whole current session', async function (assert) {
    const state = new Flyouts();
    state.a = true;

    await render(
      <template>
        {{#if state.a}}<EuiFlyout @session="start" aria-label="First" @onClose={{state.closeA}} data-test-subj="first">1</EuiFlyout>{{/if}}
        {{#if state.b}}
          <EuiFlyout @session="start" aria-label="Second" @onClose={{state.closeB}} data-test-subj="second">
            {{#if state.child}}<EuiFlyout aria-label="Child" @onClose={{state.closeChild}}>c</EuiFlyout>{{/if}}
          </EuiFlyout>
        {{/if}}
      </template>
    );
    await managed();
    state.b = true;
    state.child = true;
    await managed();
    assert.strictEqual(manager.state.flyouts.length, 3);

    state.b = false;
    await managed();
    assert.deepEqual(sessionMainIds(), ['first']);
    assert.strictEqual(manager.state.flyouts.length, 1, 'the child went with its main flyout');
    assert.deepEqual(state.closes, [], 'no onClose for flyouts the app removed');
  });

  test('closing from the manager calls onClose with navigation-cascade', async function (assert) {
    const state = new Flyouts();
    state.a = true;
    state.child = true;

    await render(
      <template>
        {{#if state.a}}
          <EuiFlyout @session="start" aria-label="Main" @onClose={{state.closeA}}>
            {{#if state.child}}<EuiFlyout aria-label="Child" @onClose={{state.closeChild}}>c</EuiFlyout>{{/if}}
          </EuiFlyout>
        {{/if}}
      </template>
    );
    await managed();
    assert.deepEqual(
      manager.state.flyouts.map((flyout) => [flyout.level, flyout.size]),
      [
        ['main', 'm'],
        ['child', 's']
      ],
      'main flyouts default to m, children to s'
    );

    manager.closeAllFlyouts();
    await managed();
    assert.deepEqual(
      state.closes.sort(),
      [
        ['a', 'navigation-cascade'],
        ['child', 'navigation-cascade']
      ],
      'each flyout is told once'
    );
  });

  test('menu props: pagination hides the history, children have no history', async function (assert) {
    const state = new Flyouts();
    const key = Symbol('menu');
    const pagination = { currentIndex: 0, total: 2, onPrevious() {}, onNext() {} };
    state.a = true;

    await render(
      <template>
        {{#if state.a}}<EuiFlyout @session="start" @historyKey={{key}} aria-label="A" @onClose={{state.closeA}}>a</EuiFlyout>{{/if}}
        {{#if state.b}}
          <EuiFlyout @session="start" @historyKey={{key}} @flyoutMenuProps={{hash title="B" hideTitle=false}} @onClose={{state.closeB}} data-test-subj="b">
            {{#if state.child}}<EuiFlyout @flyoutMenuProps={{hash title="Child" hideTitle=false}} @onClose={{state.closeChild}} data-test-subj="child">c</EuiFlyout>{{/if}}
          </EuiFlyout>
        {{/if}}
        {{#if state.c}}<EuiFlyout @session="start" @historyKey={{key}} @flyoutMenuProps={{hash title="C" pagination=pagination}} @onClose={{state.closeC}} data-test-subj="c">c</EuiFlyout>{{/if}}
      </template>
    );
    await managed();
    state.b = true;
    state.child = true;
    await managed();

    assert.dom('[data-test-subj="b"] [data-test-subj="euiFlyoutMenuBackButton"]', document.body).exists('history depth shows Back');
    assert.true(
      $('[data-test-subj="b"] .euiFlyoutMenu h3').getBoundingClientRect().width > 0,
      'hideTitle=false shows the title'
    );
    assert.dom('[data-test-subj="child"] .euiFlyoutMenu', document.body).exists('a visible title renders the menu');
    assert.dom('[data-test-subj="child"] [data-test-subj="euiFlyoutMenuBackButton"]', document.body).doesNotExist('children get no history controls');

    state.c = true;
    await managed();
    assert.dom('[data-test-subj="c"] [data-test-subj="euiFlyoutMenuBackButton"]', document.body).doesNotExist('pagination replaces Back');
    assert.dom('[data-test-subj="c"] [data-test-subj="euiFlyoutMenuPaginationNext"]', document.body).exists();
  });

  test('a new main is not clamped against the main it backgrounds; only the active main publishes its width', async function (assert) {
    const state = new Flyouts();
    const mainWidthVar = () => document.documentElement.style.getPropertyValue('--euiFlyoutMainWidth');
    const referenceWidth = window.innerWidth;
    const requested = Math.round(referenceWidth * 0.75);
    const toPct = (width: number) => `${(width / referenceWidth) * 100}%`;
    state.a = true;

    await render(
      <template>
        {{#if state.a}}<EuiFlyout @session="start" @resizable={{true}} @size={{400}} aria-label="First" @onClose={{state.closeA}} data-test-subj="first">1</EuiFlyout>{{/if}}
        {{#if state.b}}<EuiFlyout @session="start" aria-label="Second" @onClose={{state.closeB}}>2</EuiFlyout>{{/if}}
        {{#if state.c}}<EuiFlyout @session="start" @resizable={{true}} @size={{requested}} aria-label="Third" @onClose={{state.closeC}} data-test-subj="third">3</EuiFlyout>{{/if}}
      </template>
    );
    await managed();
    assert.strictEqual(mainWidthVar(), toPct(400), 'the active resizable main publishes its width');

    state.b = true;
    await managed();
    assert.strictEqual(mainWidthVar(), '', 'a backgrounded main withdraws it');

    state.b = false;
    await managed();
    assert.strictEqual(mainWidthVar(), toPct(400), 'back in front it publishes again');

    state.c = true;
    await managed();
    assert.true(
      $('[data-test-subj="third"]').getAttribute('style')!.includes(`inline-size: ${toPct(requested)}`),
      'the new main keeps its requested width'
    );
    assert.strictEqual(mainWidthVar(), toPct(requested));

    state.c = false;
    await managed();
    assert.strictEqual(mainWidthVar(), toPct(400));
    state.a = false;
    await managed();
    assert.strictEqual(mainWidthVar(), '');
  });
});

