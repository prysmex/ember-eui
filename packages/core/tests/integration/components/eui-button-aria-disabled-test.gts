import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import {
  click,
  focus,
  render,
  settled,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiButton from '#src/components/eui-button.gts';
import EuiButtonEmpty from '#src/components/eui-button-empty.gts';
import EuiButtonGroup from '#src/components/eui-button-group.gts';
import EuiButtonIcon from '#src/components/eui-button-icon.gts';
import EuiSplitButton from '#src/components/eui-split-button.gts';
import EuiToolTip from '#src/components/eui-tool-tip.gts';
import { DISABLED_ELEMENT_EVENTS } from '#src/-private/eui-disabled-element.ts';

function el<T extends HTMLElement = HTMLElement>(selector: string): T {
  const element = document.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

class State {
  @tracked isDisabled = true;
  @tracked hasAriaDisabled = true;
  events: string[] = [];
  record = (event: Event) => {
    this.events.push(
      event instanceof KeyboardEvent ? `${event.type}:${event.key}` : event.type
    );
  };
}

/** Dispatches through the prototype, like a real user event (not overridable). */
function nativeDispatch(element: Element, event: Event) {
  return EventTarget.prototype.dispatchEvent.call(element, event);
}

module('Integration | Component | eui-button hasAriaDisabled', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiButton: aria-disabled instead of disabled, focusable, blocked like upstream', async function (assert) {
    const state = new State();
    const parentClicks: string[] = [];
    const onParentClick = () => parentClicks.push('click');

    await render(
      <template>
        {{! template-lint-disable no-invalid-interactive }}
        <div data-parent {{on "click" onParentClick}}>
          <EuiButton
            @isDisabled={{state.isDisabled}}
            @hasAriaDisabled={{state.hasAriaDisabled}}
            data-aria
            {{on "click" state.record}}
            {{on "mousedown" state.record}}
            {{on "pointerdown" state.record}}
            {{on "keydown" state.record}}
            {{on "keyup" state.record}}
            {{on "focus" state.record}}
            {{on "blur" state.record}}
          >Custom disabled</EuiButton>
        </div>
        <EuiButton @isDisabled={{true}} data-native>Natively disabled</EuiButton>
      </template>
    );

    const button = el<HTMLButtonElement>('[data-aria]');
    assert.dom(button).hasTagName('button');
    assert.dom(button).hasAttribute('aria-disabled', 'true');
    assert.dom(button).doesNotHaveAttribute('disabled');
    assert.notOk(button.matches(':disabled'), 'not natively disabled');
    assert.dom('[data-native]').hasAttribute('disabled');
    assert.dom('[data-native]').doesNotHaveAttribute('aria-disabled');

    // Disabled styling is the same as the native disabled button's.
    const ariaStyle = getComputedStyle(button);
    const nativeStyle = getComputedStyle(el('[data-native]'));
    assert.strictEqual(ariaStyle.color, nativeStyle.color, 'disabled text color');
    assert.strictEqual(ariaStyle.backgroundColor, nativeStyle.backgroundColor, 'disabled background');
    assert.strictEqual(ariaStyle.cursor, 'not-allowed');
    assert.strictEqual(ariaStyle.pointerEvents, 'none', 'upstream blocks pointer interaction in CSS');

    // Stays focusable, and focus/blur still fire.
    await focus(button);
    assert.strictEqual(document.activeElement, button, 'focusable');
    assert.true(state.events.includes('focus'), 'focus event kept');

    // Test helpers dispatch through `dispatchEvent`, which swallows the events.
    await click(button);
    await triggerKeyEvent(button, 'keydown', 'Enter');
    await triggerKeyEvent(button, 'keyup', ' ');
    assert.deepEqual(
      state.events.filter((e) => e !== 'focus'),
      [],
      'click, mousedown, pointerdown and Enter/Space are blocked'
    );

    // `click()` is a no-op; a native event is stopped in the capture phase.
    button.click();
    nativeDispatch(button, new MouseEvent('click', { bubbles: true, cancelable: true }));
    nativeDispatch(button, new MouseEvent('mousedown', { bubbles: true }));
    assert.deepEqual(state.events.filter((e) => e !== 'focus'), [], 'native events are stopped');
    assert.deepEqual(parentClicks, [], 'and do not bubble to the parent');

    // Tab and Escape keep working for navigation.
    await triggerKeyEvent(button, 'keydown', 'Tab');
    await triggerKeyEvent(button, 'keydown', 'Escape');
    assert.deepEqual(
      state.events.filter((e) => e.startsWith('keydown')),
      ['keydown:Tab', 'keydown:Escape'],
      'Tab and Escape are allowed'
    );

    // Enabling restores the element without re-rendering it.
    state.isDisabled = false;
    await settled();
    assert.strictEqual(el('[data-aria]'), button, 'same element');
    assert.dom(button).doesNotHaveAttribute('aria-disabled');
    assert.dom(button).doesNotHaveAttribute('disabled');
    state.events = [];
    await click(button);
    assert.true(state.events.includes('click'), 'clicks work again');
    assert.deepEqual(parentClicks, ['click']);
    assert.strictEqual(getComputedStyle(button).pointerEvents, 'auto');

    // Without @hasAriaDisabled the native attribute is used.
    state.isDisabled = true;
    state.hasAriaDisabled = false;
    await settled();
    assert.dom(button).hasAttribute('disabled');
    assert.dom(button).doesNotHaveAttribute('aria-disabled');
  });

  test('every event upstream prevents is stopped', async function (assert) {
    const seen: string[] = [];
    const record = (event: Event) => seen.push(event.type);

    await render(
      <template>
        <EuiButtonEmpty @isDisabled={{true}} @hasAriaDisabled={{true}} data-aria>Empty</EuiButtonEmpty>
      </template>
    );
    const button = el('[data-aria]');
    for (const type of DISABLED_ELEMENT_EVENTS) button.addEventListener(type, record);

    for (const type of DISABLED_ELEMENT_EVENTS) {
      const event = type.startsWith('key')
        ? new KeyboardEvent(type, { key: 'Enter', bubbles: true, cancelable: true })
        : new Event(type, { bubbles: true, cancelable: true });
      assert.false(button.dispatchEvent(event), `dispatchEvent(${type}) reports cancelled`);
      nativeDispatch(button, event.constructor === KeyboardEvent
        ? new KeyboardEvent(type, { key: 'Enter', bubbles: true, cancelable: true })
        : new Event(type, { bubbles: true, cancelable: true }));
    }
    assert.deepEqual(seen, [], 'no listener ran');

    // Other events (e.g. focus) still go through dispatchEvent.
    button.addEventListener('focus', record);
    button.dispatchEvent(new FocusEvent('focus'));
    assert.deepEqual(seen, ['focus']);
  });

  test('EuiButtonEmpty, EuiButtonIcon and a loading button use aria-disabled', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiButtonEmpty @isDisabled={{true}} @hasAriaDisabled={{true}} data-empty {{on "click" state.record}}>Empty</EuiButtonEmpty>
        <EuiButtonIcon @iconType="trash" @isDisabled={{true}} @hasAriaDisabled={{true}} aria-label="Delete" data-icon {{on "click" state.record}} />
        <EuiButtonIcon @iconType="trash" @isDisabled={{true}} aria-label="Delete" data-icon-native />
        <EuiButton @isLoading={{true}} @hasAriaDisabled={{true}} data-loading {{on "click" state.record}}>Loading</EuiButton>
        <EuiButton @href="#x" @isDisabled={{true}} @hasAriaDisabled={{true}} data-link>Link</EuiButton>
      </template>
    );

    for (const selector of ['[data-empty]', '[data-icon]', '[data-loading]', '[data-link]']) {
      assert.dom(selector).hasAttribute('aria-disabled', 'true', `${selector} aria-disabled`);
      assert.dom(selector).doesNotHaveAttribute('disabled', `${selector} not natively disabled`);
      await click(selector);
    }
    assert.dom('[data-link]').hasTagName('button', 'a disabled link stays a button');
    assert.dom('[data-link]').doesNotHaveAttribute('href');
    assert.deepEqual(state.events, [], 'clicks are blocked');
    assert.strictEqual(
      getComputedStyle(el('[data-icon]')).color,
      getComputedStyle(el('[data-icon-native]')).color,
      'icon button has the disabled color'
    );

    await focus('[data-icon]');
    assert.strictEqual(document.activeElement, el('[data-icon]'));
  });

  test('a submit button with aria-disabled does not submit its form', async function (assert) {
    let submits = 0;
    const onSubmit = (event: Event) => {
      event.preventDefault();
      submits++;
    };

    await render(
      <template>
        <form {{on "submit" onSubmit}}>
          <EuiButton @type="submit" @isDisabled={{true}} @hasAriaDisabled={{true}} data-aria>Save</EuiButton>
        </form>
      </template>
    );

    el('[data-aria]').click();
    nativeDispatch(el('[data-aria]'), new MouseEvent('click', { bubbles: true, cancelable: true }));
    await triggerKeyEvent('[data-aria]', 'keydown', 'Enter');
    assert.strictEqual(submits, 0);
  });

  test('a focusable disabled button shows its tooltip on focus', async function (assert) {
    await render(
      <template>
        <EuiToolTip @content="Not allowed yet">
          <EuiButton @isDisabled={{true}} @hasAriaDisabled={{true}} data-aria>Disabled</EuiButton>
        </EuiToolTip>
      </template>
    );

    await focus('[data-aria]');
    await waitUntil(() => document.querySelector('.euiToolTip'));
    assert.dom('.euiToolTip', document.body).containsText('Not allowed yet');
  });

  test('EuiSplitButton passes @hasAriaDisabled to both actions', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiSplitButton @isDisabled={{state.isDisabled}} @hasAriaDisabled={{true}} as |split|>
          <split.ActionPrimary {{on "click" state.record}}>Primary</split.ActionPrimary>
          <split.ActionSecondary @iconType="gear" aria-label="More" {{on "click" state.record}} />
        </EuiSplitButton>
      </template>
    );

    assert.dom('.euiSplitButtonActionPrimary').hasAttribute('aria-disabled', 'true');
    assert.dom('.euiSplitButtonActionSecondary').hasAttribute('aria-disabled', 'true');
    assert.dom('.euiSplitButton button[disabled]').doesNotExist();
    await click('.euiSplitButtonActionPrimary');
    await click('.euiSplitButtonActionSecondary');
    assert.deepEqual(state.events, []);
    await focus('.euiSplitButtonActionSecondary');
    assert.strictEqual(document.activeElement, el('.euiSplitButtonActionSecondary'));

    state.isDisabled = false;
    await settled();
    assert.dom('.euiSplitButton [aria-disabled]').doesNotExist();
    await click('.euiSplitButtonActionPrimary');
    assert.deepEqual(state.events, ['click']);
  });

  test('EuiButtonGroup options: @hasAriaDisabled keeps options focusable and blocks changes', async function (assert) {
    const state = new State();
    const changes: string[] = [];
    const onChange = (id: string) => changes.push(id);
    const options = [
      { id: 'a', label: 'Alpha', toolTipContent: 'First' },
      { id: 'b', label: 'Beta' }
    ];

    await render(
      <template>
        <EuiButtonGroup
          @legend="Group"
          @options={{options}}
          @idSelected="a"
          @isDisabled={{state.isDisabled}}
          @hasAriaDisabled={{true}}
          @onChange={{onChange}}
        />
      </template>
    );

    assert.dom('fieldset').hasAttribute('aria-disabled', 'true');
    assert.dom('fieldset').doesNotHaveAttribute('disabled');
    assert.dom('button.euiButtonGroupButton').exists({ count: 2 }, 'disabled options render as buttons');
    assert.dom('button.euiButtonGroupButton[aria-disabled="true"]').exists({ count: 2 });
    assert.dom('button.euiButtonGroupButton[disabled]').doesNotExist();

    await click('button.euiButtonGroupButton:not(.euiButtonGroupButton-isSelected)');
    assert.deepEqual(changes, [], 'onChange is not called');

    // The tooltip of a disabled option still shows on focus.
    await focus('.euiButtonGroup__tooltipWrapper button');
    await waitUntil(() => document.querySelector('.euiToolTip'));
    assert.dom('.euiToolTip', document.body).containsText('First');

    state.isDisabled = false;
    await settled();
    assert.dom('fieldset').hasAttribute('aria-disabled', 'false', 'upstream renders aria-disabled={false}');
    assert.dom('[aria-disabled="true"]').doesNotExist();
    await click('label.euiButtonGroupButton:not(.euiButtonGroupButton-isSelected) input');
    assert.deepEqual(changes, ['b']);
  });

  test('EuiButtonGroup options: per-option @hasAriaDisabled and isDisabled', async function (assert) {
    const options = [
      { id: 'a', label: 'Alpha', isDisabled: true, hasAriaDisabled: true },
      { id: 'b', label: 'Beta', isDisabled: true },
      { id: 'c', label: 'Gamma' }
    ];

    await render(
      <template>
        <EuiButtonGroup @legend="Group" @type="multi" @options={{options}} @idToSelectedMap={{undefined}} />
      </template>
    );

    assert.dom('fieldset').doesNotHaveAttribute('aria-disabled');
    assert.dom('button.euiButtonGroupButton:nth-child(1)').hasAttribute('aria-disabled', 'true');
    assert.dom('button.euiButtonGroupButton:nth-child(1)').doesNotHaveAttribute('disabled');
    assert.dom('button.euiButtonGroupButton:nth-child(2)').hasAttribute('disabled');
    assert.dom('button.euiButtonGroupButton:nth-child(3)').doesNotHaveAttribute('aria-disabled');
  });

  test('EuiButtonGroup options: per-option title', async function (assert) {
    const options = [
      { id: 'a', label: 'Alpha' },
      { id: 'b', label: 'Beta', title: 'Custom title' },
      { id: 'c', label: 'Gamma', title: '' }
    ];

    await render(
      <template>
        <EuiButtonGroup @legend="Group" @type="multi" @options={{options}} @idToSelectedMap={{undefined}} />
      </template>
    );
    await waitUntil(() => el('.euiButtonGroupButton').getAttribute('title'));

    assert.dom('.euiButtonGroupButton:nth-child(1)').hasAttribute('title', 'Alpha', 'defaults to the label');
    assert.dom('.euiButtonGroupButton:nth-child(2)').hasAttribute('title', 'Custom title');
    assert.dom('.euiButtonGroupButton:nth-child(3)').hasAttribute('title', '', "'' unsets it");
  });
});
