import { fn } from '@ember/helper';
import { array } from '@ember/helper';
import { on } from '@ember/modifier';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import { EnsureSafeComponentHelper } from '@embroider/util';

import optional from 'ember-composable-helpers/helpers/optional';
import EmberPowerSelectMultipleTrigger from 'ember-power-select/components/power-select-multiple/trigger';
import { and, not, or } from 'ember-truth-helpers';

import argOrDefault from '../../helpers/arg-or-default.ts';
import classNames from '../../helpers/class-names.ts';
import EuiComboBoxPill from '../eui-combo-box-pill.gts';
import EuiFormControlLayout from '../eui-form-control-layout.gts';
import EuiComboBoxTriggerInput from './trigger/input.gts';

export default class EuiComboBoxTriggerComponent extends EmberPowerSelectMultipleTrigger {
  <template>
    {{! @glint-nocheck: not typesafe yet }}
    <EuiFormControlLayout
      @icon={{argOrDefault @icon "arrowDown"}}
      @iconSide="right"
      @fullWidth={{@fullWidth}}
      @compressed={{@compressed}}
      @readOnly={{@readOnly}}
      @clear={{if
        (and @select.selected @allowClear)
        (fn @select.actions.select (array))
      }}
      @isLoading={{@isLoading}}
      @disabled={{@select.disabled}}
    >
      <:field>
        {{! template-lint-disable }}
        <ul
          id="ember-power-select-multiple-options-{{@select.uniqueId}}"
          class={{classNames
            "euiComboBox__inputWrap ember-power-select-multiple-options"
            (if @compressed "euiComboBox__inputWrap--compressed")
            (if @fullWidth "euiComboBox__inputWrap--fullWidth")
            (if @singleSelection "euiComboBox__inputWrap--noWrap")
            (if @isLoading "euiComboBox__inputWrap--isLoading")
            (if @allowClear "euiComboBox__inputWrap-isClearable")
          }}
          ...attributes
          {{didUpdate this.openChanged @select.isOpen}}
          {{on "touchstart" this.chooseOption}}
          {{on "mousedown" this.chooseOption}}
        >
          {{! template-lint-enable }}
          {{#if
            (or
              (and @singleSelection (not @select.searchText))
              (not @singleSelection)
            )
          }}
            {{#each @select.selected as |opt idx|}}
              {{#if @selectedItemComponent}}
                {{#let
                  (component
                    (EnsureSafeComponentHelper @selectedItemComponent)
                    extra=@extra
                    option=opt
                    select=@select
                  )
                  as |SelectedItemComponent|
                }}
                  <SelectedItemComponent />
                {{/let}}
              {{else}}
                <EuiComboBoxPill
                  class="ember-power-select-multiple-option
                    {{if
                      opt.disabled
                      'ember-power-select-multiple-option--disabled'
                    }}"
                  @option={{opt}}
                  @onClose={{if
                    (or @select.disabled @singleSelection)
                    false
                    (if @onClose (fn (optional @onClose) opt) true)
                  }}
                  @dataSelectedIconIndex={{idx}}
                  @color={{opt.color}}
                  @asPlainText={{@singleSelection.asPlainText}}
                >
                  {{yield opt @select}}
                </EuiComboBoxPill>
              {{/if}}
            {{else}}{{#if (and @placeholder (not @searchEnabled))}}
                <span class="ember-power-select-placeholder">
                  {{@placeholder}}
                </span>
              {{/if}}{{/each}}
          {{/if}}
          {{#if @searchEnabled}}
            {{#if (and this.maybePlaceholder (not @select.searchText))}}
              <p class="euiComboBoxPlaceholder">
                {{this.maybePlaceholder}}
              </p>
            {{/if}}
            {{#let
              (component
                EuiComboBoxTriggerInput
                select=@select
                ariaActiveDescendant=@ariaActiveDescendant
                ariaLabelledBy=@ariaLabelledBy
                ariaLabel=@ariaLabel
                listboxId=@listboxId
                tabindex=@tabindex
                buildSelection=@buildSelection
                placeholder=@placeholder
                placeholderComponent=@placeholderComponent
                searchField=@searchField
                onFocus=@onFocus
                isInvalid=@isInvalid
                onBlur=@onBlur
                onKeydown=@onKeydown
                onInput=@onInput
                onCreateOption=@onCreateOption
              )
              as |InputComponent|
            }}
              {{#let
                (component
                  (EnsureSafeComponentHelper @placeholderComponent)
                  select=@select
                  placeholder=@placeholder
                  isMultipleWithSearch=true
                  inputComponent=InputComponent
                  displayPlaceholder=(and
                    (not @select.searchText) (not @select.selected)
                  )
                )
                as |PlaceholderComponent|
              }}
                <PlaceholderComponent />
              {{/let}}
            {{/let}}
          {{else}}
            {{! template-lint-disable }}
            <div
              class="euiComboBox__input"
              style="font-size: 14px; display: inline-block;"
            ></div>
            {{! template-lint-enable }}
          {{/if}}
        </ul>
      </:field>
    </EuiFormControlLayout>
  </template>
}
