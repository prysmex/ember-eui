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
 * Resolves a locale key ("es", "ru", ...) to flatpickr's locale object.
 *
 * A template-literal import (`flatpickr/dist/l10n/${key}.js`) can't be
 * resolved by bundlers (Vite/Rollup keep it as a bare runtime specifier), so
 * load flatpickr's locale index instead: a static import that bundlers split
 * into a lazy chunk, fetched only when a non-English string locale is used.
 * Unknown keys fall back to the key itself (flatpickr then uses English).
 */
async function loadLocale(key) {
  const module = await import('flatpickr/dist/l10n/index.js');
  const locales = module.default?.default ?? module.default ?? module;

  return locales[key] ?? key;
}

/**
 * EUI text field wired to flatpickr (https://flatpickr.js.org): a date,
 * time, date range or multiple dates picker. Load flatpickr's styles once,
 * e.g. `import 'flatpickr/dist/flatpickr.css'` in `app/app.js`.
 *
 * Arguments:
 * - `@date` (required): the selected date(s): a `Date`, a string in
 *   `@dateFormat`, an array for ranges / multiple dates, or `null`.
 * - `@onChange` (required, or `null`): called with
 *   `(selectedDates: Date[], dateStr: string, instance)`; update `@date`.
 * - `@onOpen`, `@onClose`, `@onReady`: flatpickr's hooks, same arguments.
 * - `@locale`: a flatpickr locale object, or a key such as `'es'` (loaded
 *   lazily). Changing it recreates the picker.
 * - `@disabled`: disables the input.
 * - `@clear`: shows a clear button (while there is a `@date`) calling
 *   `@clear(null)`.
 * - `@ariaLabel`: accessible label of the input.
 * - Any other flatpickr option is passed through, e.g. `@mode` (`'single'`,
 *   `'multiple'`, `'range'`), `@enableTime`, `@noCalendar`, `@dateFormat`,
 *   `@altInput` / `@altFormat` / `@altInputClass`, `@minDate`, `@maxDate`,
 *   `@inline`, `@weekNumbers`. `@minDate`, `@maxDate`, `@altFormat`,
 *   `@altInputClass` and `@date` also update a rendered picker.
 * - EuiFieldText's args style the input: `@icon` (defaults to
 *   `'calendar'`), `@fullWidth`, `@compressed`, `@isInvalid`,
 *   `@isLoading`, `@readOnly`, `@controlOnly`, `@inputRef`, `@id`, plus the
 *   `<:prepend>` / `<:append>` blocks.
 *
 * `@wrap` is not supported.
 *
 * The flatpickr lifecycle below used to come from extending ember-flatpickr's
 * component; it is inlined (same arguments and behavior) because
 * ember-flatpickr still depends on v1 addons (@ember/render-modifiers 3,
 * @ember/test-waiters 3), which break Vite apps.
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

    if (typeof config.locale === 'string' && config.locale !== 'en') {
      config.locale = await waitForPromise(loadLocale(config.locale));
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
