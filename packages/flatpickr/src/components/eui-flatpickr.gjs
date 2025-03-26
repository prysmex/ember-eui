import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import willDestroy from '@ember/render-modifiers/modifiers/will-destroy';
import { EuiFieldText } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import EmberFlatpickr from 'ember-flatpickr/components/ember-flatpickr';
import { and, not } from 'ember-truth-helpers';

import randomId from '../-private/random-id';

/**
 * Loop through all properties of an object and nullify any properties that are instanceof HTMLElement,
 * if we detect an array then use recursion to go inside it and apply same logic
 * @param obj - object containing 1 or more properties with DOM Elements
 */
function destroyObjectDomElementProps(obj) {
  for (const key of Object.keys(obj)) {
    if (Array.isArray(obj[key])) {
      destroyObjectDomElementProps(obj[key]);
    }
    if (obj[key] instanceof HTMLElement) {
      obj[key] = null;
    }
  }
}

export default class EuiFlatpickrComponent extends EmberFlatpickr {
  @action
  onClear() {
    this.args.clear(null);
  }

  // @action
  // onWillDestroy() {
  //   if (this.flatpickrRef.element) {
  //     this.flatpickrRef.destroy();
  //     // destroyObjectDomElementProps(this.flatpickrRef);
  //   }
  //   // this.flatpickrRef = null;
  // }

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
