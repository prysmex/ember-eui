import { cached } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { array } from '@ember/helper';
import { on } from '@ember/modifier';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import PowerSelectTrigger from 'ember-power-select/components/power-select/trigger';
import { and, not, or } from 'ember-truth-helpers';

import argOrDefault from '../../helpers/arg-or-default.ts';
import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import {
  euiComboBoxInputStyles,
  euiFontSize,
  euiFormVariables
} from '../../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import EuiComboBoxPill from '../eui-combo-box-pill.gts';
import EuiFormControlLayout from '../eui-form-control-layout.gts';
import EuiComboBoxTriggerInput from './trigger/input.gts';

import type { CSSInterpolation } from '@emotion/css/create-instance';

interface TriggerSelect {
  uniqueId: string;
  isOpen: boolean;
  disabled: boolean;
  searchText: string;
  selected?: unknown[];
}

interface TriggerArgs {
  select: TriggerSelect;
  compressed?: boolean;
  fullWidth?: boolean;
  isInvalid?: boolean;
  placeholder?: string;
  searchEnabled?: boolean;
  singleSelection?: boolean | { asPlainText?: boolean };
}

/**
 * @private EuiComboBox's input with the selected pills. Extends
 * ember-power-select's multiple trigger.
 */
export default class EuiComboBoxTriggerComponent extends PowerSelectTrigger {
  get comboArgs(): TriggerArgs {
    return this.args as unknown as TriggerArgs;
  }

  get asPlainText(): boolean {
    const single = this.comboArgs.singleSelection;

    return Boolean(single && typeof single === 'object' && single.asPlainText);
  }

  get hasSelection(): boolean {
    return Boolean(this.comboArgs.select.selected?.length);
  }

  /** Upstream `showPlaceholder`: a placeholder, no selection, no search. */
  get showPlaceholder(): boolean {
    const { placeholder, select } = this.comboArgs;

    return Boolean(placeholder && !this.hasSelection && !select.searchText);
  }

  /** EuiFormControlLayout grows with the rows of pills (multi selection). */
  @cached
  get layoutCss(): CSSInterpolation[] {
    const styles = useEuiBorealisStyles(
      getEuiThemeContext(this),
      euiComboBoxInputStyles
    );

    return [
      styles.formLayout.euiComboBox__formControlLayout,
      !this.comboArgs.singleSelection && styles.formLayout.multiSelect
    ];
  }

  /**
   * Upstream `euiComboBoxInputWrapper`: the element that looks like the form
   * control (border, background, padding, focus/invalid/disabled states),
   * holding the pills and the search input.
   */
  @cached
  get wrapClass(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiComboBoxInputStyles);
    const { compressed, isInvalid, select, singleSelection } = this.comboArgs;
    const plainText = this.asPlainText || this.showPlaceholder;
    const stateCss = select.isOpen
      ? styles.open
      : isInvalid
        ? styles.invalid
        : undefined;

    return euiClass(
      context,
      // the wrap is a <div>, but keep any list or prose margins off it
      { margin: 0, listStyle: 'none' },
      styles.euiComboBoxInputWrapper,
      !singleSelection && styles.multiSelect,
      compressed ? styles.compressed : styles.uncompressed,
      ...(plainText
        ? [
            styles.plainText.plainText,
            compressed
              ? styles.plainText.compressed
              : styles.plainText.uncompressed
          ]
        : []),
      select.disabled ? styles.disabled : stateCss
    );
  }

  /**
   * Placeholder shown when searching is disabled: the form control
   * placeholder color and size (the input shows it otherwise).
   */
  @cached
  get placeholderClass(): string {
    const context = getEuiThemeContext(this);
    const form = useEuiBorealisStyles(context, euiFormVariables);

    return euiClass(context, {
      alignSelf: 'center',
      fontSize: euiFontSize(context.upstream, 's', undefined).fontSize,
      color: form.controlPlaceholderText,
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      whiteSpace: 'nowrap'
    });
  }

  /** Keeps the wrap one input tall without a search input. */
  @cached
  get spacerClass(): string {
    const context = getEuiThemeContext(this);

    return euiClass(context, {
      blockSize: context.upstream.euiTheme.size.l,
      minInlineSize: '2px'
    });
  }

  <template>
    {{! @glint-nocheck: not typesafe yet }}
    <EuiFormControlLayout
      @icon={{unless @select.disabled (argOrDefault @icon "chevronSingleDown")}}
      @iconSide="right"
      @fullWidth={{@fullWidth}}
      @compressed={{@compressed}}
      @readOnly={{@readOnly}}
      @isInvalid={{@isInvalid}}
      @clear={{if
        (and @select.selected @allowClear)
        (fn @select.actions.select (array))
      }}
      @isLoading={{@isLoading}}
      @disabled={{@select.disabled}}
      @css={{this.layoutCss}}
    >
      <:field>
        {{! template-lint-disable }}
        <div
          id="ember-power-select-multiple-options-{{@select.uniqueId}}"
          class="euiComboBox__inputWrap ember-power-select-multiple-options
            {{if this.asPlainText 'euiComboBox__inputWrap--plainText'}}
            {{this.wrapClass}}"
          data-test-subj="comboBoxInput"
          ...attributes
          {{this.openChange @select.isOpen}}
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
                    @selectedItemComponent
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
                  @searchField={{@searchField}}
                  @onClose={{if
                    (or @select.disabled @singleSelection)
                    false
                    (if @onClose (fn (optional @onClose) opt) true)
                  }}
                  @dataSelectedIconIndex={{idx}}
                  @color={{opt.color}}
                  @asPlainText={{this.asPlainText}}
                >
                  {{yield opt @select}}
                </EuiComboBoxPill>
              {{/if}}
            {{else}}{{#if (and @placeholder (not @searchEnabled))}}
                <span
                  class="ember-power-select-placeholder {{this.placeholderClass}}"
                >
                  {{@placeholder}}
                </span>
              {{/if}}{{/each}}
          {{/if}}
          {{#if @searchEnabled}}
            {{#let
              (component
                EuiComboBoxTriggerInput
                select=@select
                ariaActiveDescendant=@ariaActiveDescendant
                ariaLabelledBy=@ariaLabelledBy
                ariaDescribedBy=@ariaDescribedBy
                ariaLabel=@ariaLabel
                listboxId=@listboxId
                tabindex=@tabindex
                buildSelection=@buildSelection
                placeholder=@placeholder
                placeholderComponent=@placeholderComponent
                searchField=@searchField
                onFocus=@onFocus
                isInvalid=@isInvalid
                fillWidth=(or this.asPlainText this.showPlaceholder)
                onBlur=@onBlur
                onKeydown=@onKeydown
                onInput=@onInput
                onCreateOption=@onCreateOption
              )
              as |InputComponent|
            }}
              {{#let
                (component
                  @placeholderComponent
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
            <div class="euiComboBox__input {{this.spacerClass}}"></div>
          {{/if}}
        </div>
      </:field>
    </EuiFormControlLayout>
  </template>
}
