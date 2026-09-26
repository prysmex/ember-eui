import Component from '@glimmer/component';
import { assert } from '@ember/debug';
import { action } from '@ember/object';
import { getOwner } from '@ember/owner';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import willDestroy from '@ember/render-modifiers/modifiers/will-destroy';
import { scheduleOnce } from '@ember/runloop';
import { waitForPromise } from '@ember/test-waiters';
import { EuiFieldText } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import flatpickr from 'flatpickr';
import { and, not } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';

/**
 * EUI text field wired to flatpickr (https://flatpickr.js.org).
 *
 * The flatpickr lifecycle below used to come from extending ember-flatpickr's
 * component; it is inlined (same arguments and behavior) because
 * ember-flatpickr still depends on v1 addons (@ember/render-modifiers 3,
 * @ember/test-waiters 3), which break Vite apps.
 *
 * Requires `@date` and `@onChange` (or null); any other argument is passed to
 * flatpickr as an option.
 */
export default class EuiFlatpickrComponent extends Component {
  flatpickrRef;

  @action
  onClear() {
    this.args.clear(null);
  }

  @action
  onInsert(element) {
    this.setupFlatpickr(element);
  }

  @action
  onWillDestroy() {
    this.flatpickrRef?.destroy();
  }

  setupFlatpickr(element) {
    const { date, onChange, wrap } = this.args;

    assert(
      '<EuiFlatpickr> requires a `date` to be passed as the value for flatpickr.',
      date !== undefined
    );
    assert(
      '<EuiFlatpickr> requires an `onChange` action or null for no action.',
      onChange !== undefined
    );
    assert(
      '<EuiFlatpickr> does not support the wrap option.',
      wrap !== true
    );

    scheduleOnce('afterRender', this, this.setFlatpickrOptions, element);
  }

  async setFlatpickrOptions(element) {
    const fastboot = getOwner(this)?.lookup('service:fastboot');

    if (fastboot?.isFastBoot) {
      return;
    }

    const {
      date,
      disabled = false,
      onChange,
      onReady,
      onOpen,
      onClose,
      ...rest
    } = this.args;
    const config = Object.fromEntries(
      Object.entries(rest).filter((entry) => entry[1] !== undefined)
    );

    if (typeof this.args.locale === 'string' && this.args.locale !== 'en') {
      await waitForPromise(
        import(`flatpickr/dist/l10n/${this.args.locale}.js`)
      );
    }

    this.flatpickrRef = flatpickr(element, {
      onChange,
      onClose,
      onOpen,
      onReady,
      ...config,
      defaultDate: date,
    });
    this.setDisabled(disabled);
  }

  setDisabled(disabled) {
    if (!this.flatpickrRef) {
      return;
    }

    const { altInput, element } = this.flatpickrRef;

    if (altInput && element?.nextSibling) {
      // with `altInput`, `element` is the hidden input holding the value and
      // the next sibling is the visible input the user interacts with
      element.nextSibling.disabled = disabled;
    } else {
      element.disabled = disabled;
    }
  }

  @action
  onAltFormatUpdated() {
    this.flatpickrRef?.set('altFormat', this.args.altFormat);
  }

  @action
  onAltInputClassUpdated() {
    const { altInputClass } = this.args;

    this.flatpickrRef?.set('altInputClass', altInputClass || '');

    // https://github.com/flatpickr/flatpickr/issues/861
    const altInput = this.flatpickrRef?.altInput;

    if (altInput) {
      altInput.className = altInputClass || '';
    }
  }

  @action
  onDateUpdated() {
    if (typeof this.args.date !== 'undefined') {
      this.flatpickrRef?.setDate(this.args.date);
    }
  }

  @action
  onDisabledUpdated() {
    if (typeof this.args.disabled !== 'undefined') {
      this.setDisabled(this.args.disabled);
    }
  }

  @action
  onLocaleUpdated(element) {
    this.flatpickrRef?.destroy();
    this.setupFlatpickr(element);
  }

  @action
  onMaxDateUpdated() {
    this.flatpickrRef?.set('maxDate', this.args.maxDate);
  }

  @action
  onMinDateUpdated() {
    this.flatpickrRef?.set('minDate', this.args.minDate);
  }

  <template>
    {{#let
      (and (not (argOrDefault @isFakePrependBlock false)) (has-block "prepend"))
      (and (not (argOrDefault @isFakeAppendBlock false)) (has-block "append"))
      (argOrDefault @id (randomId))
      as |hasPrepend hasAppend inputId|
    }}
      <EuiFieldText
        aria-label={{@ariaLabel}}
        @icon={{if @icon @icon "calendar"}}
        @fullWidth={{@fullWidth}}
        @isLoading={{@isLoading}}
        @readOnly={{@readOnly}}
        @inputRef={{@inputRef}}
        @controlOnly={{@controlOnly}}
        @compressed={{@compressed}}
        @id={{inputId}}
        @isFakePrependBlock={{not hasPrepend}}
        @isFakeAppendBlock={{not hasAppend}}
        @disabled={{@disabled}}
        @isInvalid={{@isInvalid}}
        @clear={{if
          (and @clear @date (not @isDisabled) (not @disabled))
          this.onClear
        }}
        {{didInsert this.onInsert}}
        {{willDestroy this.onWillDestroy}}
        {{didUpdate this.onAltFormatUpdated @altFormat}}
        {{didUpdate this.onAltInputClassUpdated @altInputClass}}
        {{didUpdate this.onDateUpdated @date}}
        {{didUpdate this.onDisabledUpdated @disabled}}
        {{didUpdate this.onLocaleUpdated @locale}}
        {{didUpdate this.onMaxDateUpdated @maxDate}}
        {{didUpdate this.onMinDateUpdated @minDate}}
        ...attributes
      >
        <:prepend as |classes finalId|>
          {{yield classes finalId to="prepend"}}
        </:prepend>
        <:append as |classes finalId|>
          {{yield classes finalId to="append"}}
        </:append>
      </EuiFieldText>
    {{/let}}
  </template>
}
