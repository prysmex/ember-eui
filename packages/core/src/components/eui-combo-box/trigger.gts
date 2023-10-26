import EmberPowerSelectMultipleTrigger from 'ember-power-select/components/power-select-multiple/trigger';
import EuiComboBoxTriggerInput from 'ember-power-select/components/power-select-multiple/trigger/input';
import EuiFormControlLayout from '@ember-eui/components/eui-form-control-layout';
import EuiComboBoxPill from '@ember-eui/components/eui-combo-box/eui-combo-box-pill';
import argOrDefault from '../helpers/arg-or-default';
import classNames from '../../helpers/class-names';
import { or, and, not } from 'ember-truth-helpers';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import { optional } from 'ember-composable-helpers';
import { fn } from '@ember/helper';
import { array } from '@ember/helper';
import { on } from '@ember/modifier';

export default class EuiComboBoxTriggerComponent extends EmberPowerSelectMultipleTrigger {
  <template>
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
                {{component
                  (ensure-safe-component @selectedItemComponent)
                  extra=@extra
                  option=opt
                  select=@select
                }}
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
                onBlur=@onBlur
                onKeydown=@onKeydown
                onInput=@onInput
                onCreateOption=@onCreateOption
              )
              as |InputComponent|
            }}
              {{component
                (ensure-safe-component @placeholderComponent)
                select=@select
                placeholder=@placeholder
                isMutlipleWithSearch=true
                inputComponent=InputComponent
                displayPlaceholder=(and
                  (not @select.searchText) (not @select.selected)
                )
              }}
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