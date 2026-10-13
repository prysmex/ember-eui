import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, fillIn, focus, getDeprecations, render, rerender, select, settled, triggerKeyEvent } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiColorStops from '#src/components/eui-color-stops.gts';
import EuiFieldText from '#src/components/eui-field-text.gts';
import EuiForm from '#src/components/eui-form.gts';
import EuiNotificationEvent from '#src/components/eui-notification-event.gts';
import EuiNotificationEventMessages from '#src/components/eui-notification-event-messages.gts';
import EuiNotificationEventMeta from '#src/components/eui-notification-event-meta.gts';
import EuiNotificationEventReadButton from '#src/components/eui-notification-event-read-button.gts';
import EuiNotificationEventReadIcon from '#src/components/eui-notification-event-read-icon.gts';
import EuiRefreshInterval from '#src/components/eui-refresh-interval.gts';
import EuiSuggest from '#src/components/eui-suggest.gts';
import EuiSuggestInput from '#src/components/eui-suggest-input.gts';
import EuiSuggestItem from '#src/components/eui-suggest-item.gts';

import type { ColorStop } from '#src/components/eui-color-stops.gts';

const noop = () => {};
const NO_SUGGESTIONS: never[] = [];

/** Deprecations recorded in this test with the given id. */
function removedUpstream(fileName: string) {
  const id = `ember-eui.${fileName}.removed-upstream`;
  return getDeprecations().filter((d) => d.options?.id === id);
}

module('Integration | Component | upstream decisions', function (hooks) {
  setupRenderingTest(hooks);

  module('EuiForm error callout focus', function () {
    class FormState {
      @tracked isInvalid = false;
      @tracked errors: string[] = ['Name is required'];
      @tracked title = 'Please correct the fields';
    }

    test('focus moves to the callout exactly when the form becomes invalid', async function (assert) {
      const state = new FormState();

      await render(
        <template>
          <EuiForm @isInvalid={{state.isInvalid}} @error={{state.errors}} @errorTitle={{state.title}}>
            <EuiFieldText class="name" aria-label="Name" />
          </EuiForm>
        </template>
      );

      const input = this.element.querySelector<HTMLInputElement>('input.name')!;
      await focus(input);
      assert.dom('.euiForm__errors').doesNotExist('valid: no callout');

      state.isInvalid = true;
      await settled();
      assert.dom('.euiForm__errors').hasAttribute('tabindex', '-1').hasAttribute('role', 'alert').hasAria('live', 'assertive');
      assert.strictEqual(document.activeElement, this.element.querySelector('.euiForm__errors'), 'the callout is focused on the transition to invalid');

      // the user goes back to the field; re-renders of the visible callout keep focus there
      await focus(input);
      const callout = this.element.querySelector('.euiForm__errors');
      state.errors = ['Name is required', 'Email is invalid'];
      state.title = 'Fix these';
      await settled();
      await rerender();
      assert.dom('.euiForm__errors li').exists({ count: 2 });
      assert.strictEqual(this.element.querySelector('.euiForm__errors'), callout, 'same callout element');
      assert.strictEqual(document.activeElement, input, 'no focus move on re-render');

      // valid again, then invalid again: a new transition focuses again
      state.isInvalid = false;
      await settled();
      assert.dom('.euiForm__errors').doesNotExist();
      assert.strictEqual(document.activeElement, input, 'becoming valid does not move focus');

      state.isInvalid = true;
      await settled();
      assert.strictEqual(document.activeElement, this.element.querySelector('.euiForm__errors'), 'focused on the next transition');
    });

    test('no focus move when the callout is hidden', async function (assert) {
      const state = new FormState();

      await render(
        <template>
          <EuiForm @isInvalid={{state.isInvalid}} @error={{state.errors}} @invalidCallout="none">
            <EuiFieldText class="name" aria-label="Name" />
          </EuiForm>
        </template>
      );

      const input = this.element.querySelector<HTMLInputElement>('input.name')!;
      await focus(input);
      state.isInvalid = true;
      await settled();
      assert.dom('.euiForm__errors').doesNotExist();
      assert.strictEqual(document.activeElement, input);
    });
  });

  module('components removed upstream are deprecated', function () {
    const MESSAGES = ['First', 'Second'];
    const STOPS: ColorStop[] = [
      { stop: 0, color: '#54B399' },
      { stop: 50, color: '#D36086' }
    ];
    const TYPE = { iconType: 'kqlField', color: 'tint4' };

    test('each deprecation has the right id, options and message', async function (assert) {
      await render(
        <template>
          <EuiNotificationEvent @id="a" @title="Read button" @messages={{MESSAGES}} @isRead={{false}} @onRead={{noop}} />
          <EuiNotificationEvent @id="b" @title="Read icon" @messages={{MESSAGES}} @isRead={{true}} />
          <EuiSuggest @suggestions={{NO_SUGGESTIONS}} aria-label="Search" />
          <EuiSuggestItem @type={{TYPE}} @label="label" />
          <EuiColorStops @label="Stops" @colorStops={{STOPS}} @onChange={{noop}} @min={{0}} @max={{100}} />
        </template>
      );

      const expected: [string, string, string][] = [
        ['eui-notification-event', 'EuiNotificationEvent', 'EuiPanel'],
        ['eui-notification-event-messages', 'EuiNotificationEventMessages', 'EuiPanel'],
        ['eui-notification-event-meta', 'EuiNotificationEventMeta', 'EuiPanel'],
        ['eui-notification-event-read-button', 'EuiNotificationEventReadButton', 'EuiPanel'],
        ['eui-notification-event-read-icon', 'EuiNotificationEventReadIcon', 'EuiPanel'],
        ['eui-suggest', 'EuiSuggest', 'EuiSelectable'],
        ['eui-suggest-input', 'EuiSuggestInput', 'EuiSelectable'],
        ['eui-suggest-item', 'EuiSuggestItem', 'EuiSelectable'],
        ['eui-color-stops', 'EuiColorStops', 'EuiColorPalettePicker'],
        ['eui-color-stops-thumb', 'EuiColorStopThumb', 'EuiColorPalettePicker']
      ];

      for (const [fileName, name, alternative] of expected) {
        const [deprecation] = removedUpstream(fileName);
        assert.ok(deprecation, `${fileName} fires`);
        if (!deprecation) continue;
        assert.deepEqual(
          { for: deprecation.options.for, since: deprecation.options.since, until: deprecation.options.until },
          { for: '@ember-eui/core', since: { available: '15.0.0', enabled: '15.0.0' }, until: '16.0.0' },
          `${fileName} options`
        );
        assert.true(deprecation.message.startsWith(`${name} was removed from Elastic UI (EUI) upstream`), `${fileName} message names the component`);
        assert.true(deprecation.message.includes('next major version'), `${fileName} message announces the removal`);
        assert.true(deprecation.message.includes(alternative), `${fileName} message suggests ${alternative}`);
      }

      assert.strictEqual(removedUpstream('eui-notification-event').length, 2, 'once per instance');
      assert.strictEqual(removedUpstream('eui-color-stops').length, 1);
      assert.strictEqual(removedUpstream('eui-color-stops-thumb').length, 2, 'one per stop thumb');
    });

    test('sub-components fire on their own; re-renders do not fire again', async function (assert) {
      class State {
        @tracked label = 'one';
      }
      const state = new State();

      await render(
        <template>
          <EuiNotificationEventMeta @id="m" @eventName="Event" @type="Alert" @hasDefaultBlock={{false}} />
          <EuiNotificationEventMessages @messages={{MESSAGES}} />
          <EuiNotificationEventReadButton @id="r" @eventName="Event" @isRead={{false}} />
          <EuiNotificationEventReadIcon @id="i" @eventName="Event" @isRead={{false}} />
          <EuiSuggestInput @hasSuggestions={{false}} aria-label="Query" />
          <EuiSuggestItem @type={{TYPE}} @label={{state.label}} />
        </template>
      );

      for (const fileName of [
        'eui-notification-event-meta',
        'eui-notification-event-messages',
        'eui-notification-event-read-button',
        'eui-notification-event-read-icon',
        'eui-suggest-input',
        'eui-suggest-item'
      ]) {
        assert.strictEqual(removedUpstream(fileName).length, 1, `${fileName} fires once`);
      }
      assert.strictEqual(removedUpstream('eui-notification-event').length, 0, 'the parent did not render');

      state.label = 'two';
      await settled();
      assert.dom('.euiSuggestItem').containsText('two');
      assert.strictEqual(removedUpstream('eui-suggest-item').length, 1, 'updating args does not fire again');
    });
  });

  module('EuiRefreshInterval switch', function () {
    class RefreshState {
      @tracked isPaused = true;
      @tracked refreshInterval = 5000;
      changes: { refreshInterval: number; isPaused: boolean }[] = [];

      apply = (change: { refreshInterval: number; isPaused: boolean }) => {
        this.changes.push(change);
        this.isPaused = change.isPaused;
        this.refreshInterval = change.refreshInterval;
      };
    }

    test('the switch toggles pause, disables the fields while paused and emits changes', async function (assert) {
      const state = new RefreshState();

      await render(
        <template>
          <EuiRefreshInterval @isPaused={{state.isPaused}} @refreshInterval={{state.refreshInterval}} @applyRefreshInterval={{state.apply}} />
        </template>
      );

      const toggle = '[data-test-subj="superDatePickerToggleRefreshButton"]';
      const input = '[data-test-subj="superDatePickerRefreshIntervalInput"]';
      const units = '[data-test-subj="superDatePickerRefreshIntervalUnitsSelect"]';
      const description = this.element.querySelector('.euiScreenReaderOnly p')!;

      assert.dom('.euiButton').doesNotExist('no Start/Stop button');
      assert.dom('legend').doesNotExist('the switch label replaces the legend');
      assert
        .dom(toggle)
        .hasTagName('button')
        .hasAttribute('role', 'switch')
        .hasAria('checked', 'false')
        .hasAria('label', 'Toggle refresh')
        .hasAria('describedby', description.id)
        .doesNotHaveAttribute('aria-labelledby');
      assert.dom('.euiSwitch label.euiFormLabel').hasText('Refresh every', 'visible label is an EuiFormLabel');
      assert.dom(input).isDisabled().hasValue('5').hasAria('describedby', description.id);
      assert.dom(units).isDisabled().hasValue('s');
      assert.dom(description).hasText('Refresh is off, interval set to 5 Seconds.');

      await click(toggle);
      assert.deepEqual(state.changes, [{ refreshInterval: 5000, isPaused: false }]);
      assert.dom(toggle).hasAria('checked', 'true');
      assert.dom(input).isNotDisabled();
      assert.dom(units).isNotDisabled();
      assert.dom(description).hasText('Refresh is on, interval set to 5 Seconds.');

      await fillIn(input, '2');
      await select(units, 'm');
      assert.deepEqual(state.changes.at(-1), { refreshInterval: 120000, isPaused: false });

      await fillIn(input, '');
      assert.dom(input).hasAria('invalid', 'true', 'invalid while running');

      await fillIn(input, '3');
      await click(toggle);
      assert.deepEqual(state.changes.at(-1), { refreshInterval: 180000, isPaused: true });
      assert.dom(toggle).hasAria('checked', 'false');
      assert.dom(input).isDisabled().doesNotHaveAria('invalid');
      assert.dom(units).isDisabled();
    });

    test('clicking the visible label toggles too; Enter starts from the fields', async function (assert) {
      const state = new RefreshState();
      state.isPaused = false;

      await render(
        <template>
          <EuiRefreshInterval @isPaused={{state.isPaused}} @refreshInterval={{state.refreshInterval}} @applyRefreshInterval={{state.apply}} />
        </template>
      );

      await click('.euiSwitch__label');
      assert.deepEqual(state.changes.at(-1), { refreshInterval: 5000, isPaused: true });
      assert.dom('[data-test-subj="superDatePickerRefreshIntervalInput"]').isDisabled();

      state.isPaused = false;
      await settled();
      await fillIn('[data-test-subj="superDatePickerRefreshIntervalInput"]', '10');
      await triggerKeyEvent('[data-test-subj="superDatePickerRefreshIntervalInput"]', 'keydown', 'Enter');
      assert.deepEqual(state.changes.at(-1), { refreshInterval: 10000, isPaused: false });
    });
  });
});
