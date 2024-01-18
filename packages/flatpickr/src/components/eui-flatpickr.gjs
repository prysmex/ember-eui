import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import willDestroy from '@ember/render-modifiers/modifiers/will-destroy';
import { EuiFieldText,EuiFormControlLayout } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import EmberFlatpickr from 'ember-flatpickr/components/ember-flatpickr';
import { and, not, or } from 'ember-truth-helpers';
import randomId from '../-private/random-id';

export default class EuiFlatpickrComponent extends EmberFlatpickr {
  @action
  onClear() {
    this.args.clear(null);
  }

  <template>
    {{#let
      (and (not (argOrDefault @isFakePrependBlock false)) (has-block "prepend"))
      (and (not (argOrDefault @isFakeAppendBlock false)) (has-block "append"))
      (argOrDefault @id (randomId))
      as |hasPrepend hasAppend inputId|
    }}
      <EuiFormControlLayout
        @fullWidth={{@fullWidth}}
        @disabled={{@disabled}}
        @clear={{if
          (and @clear @date (and (not @isDisabled) (not @disabled)))
          this.onClear
        }}
        @compressed={{@compressed}}
        @useGroup={{or hasPrepend hasAppend}}
      >
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
          @isFakePrependBlock={{hasPrepend}}
          @isFakeAppendBlock={{hasAppend}}
          @disabled={{@disabled}}
          @isInvalid={{@isInvalid}}
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
      </EuiFormControlLayout>
    {{/let}}
  </template>
}
