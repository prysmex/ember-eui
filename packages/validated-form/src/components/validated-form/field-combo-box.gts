import { fn } from '@ember/helper';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import EuiComboBox from '@ember-eui/core/components/eui-combo-box';
import EuiFormRow from '@ember-eui/core/components/eui-form-row';
import { argOrDefault } from '@ember-eui/core/helpers';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import queue from '@nullvoxpopuli/ember-composable-helpers/helpers/queue';
import { not, or } from 'ember-truth-helpers';

import randomId from '../../-private/random-id.ts';
import ValidatedFormFieldBase from './field-base.gts';

import type { FieldBaseSignature } from './field-base.gts';
import type { EuiComboBoxSignature } from '@ember-eui/core/components/eui-combo-box';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';

/**
 * A validated combo box in an EuiFormRow. Takes FieldBase's, EuiFormRow's and
 * the control's args.
 */
export interface FieldComboBoxSignature {
  Element: EuiComboBoxSignature['Element'];
  Args: FieldBaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiComboBoxSignature['Args'] & {
      /** Classes for the EuiFormRow. */
      rowClasses?: string;
      /** Classes for the control. */
      fieldClasses?: string;
      /** @private Set by ValidatedForm. */
      formId?: string;
      /** Accessible label of the control. */
      ariaLabel?: string;
      /** Focuses the control on render (same as `@autoFocus`). */
      autofocus?: boolean;
      /** Called with the selected options. */
      onChange?: (options: any[]) => void;
      /** Placeholder text. */
      placeholder?: string;
      /** The options, see the control. */
      options?: EuiComboBoxSignature['Args']['options'];
      /** The selected options. */
      selectedOptions?: EuiComboBoxSignature['Args']['selectedOptions'];
    };
  Blocks: {
    label: EuiFormRowSignature['Blocks']['label'];
    helpText: EuiFormRowSignature['Blocks']['helpText'];
    default: EuiComboBoxSignature['Blocks']['default'];
  };
}

export default class ValidatedFormFieldComboBox extends ValidatedFormFieldBase<FieldComboBoxSignature> {
  validationProperty = 'args.selectedOptions';

  @action
  //@ts-expect-error
  handleChange(options: any[]) {
    this.args.onChange(options);
    this.notifyValidityChange();
  }

  <template>
    {{#let (argOrDefault @id (randomId)) as |theId|}}
      <EuiFormRow
        class={{this.rowClasses}}
        @labelType={{@labelType}}
        @display={{@display}}
        @hasEmptyLabelSpace={{@hasEmptyLabelSpace}}
        @fullWidth={{@fullWidth}}
        @hasChildLabel={{@hasChildLabel}}
        @label={{this.label}}
        @labelAppend={{@labelAppend}}
        @id={{theId}}
        @isInvalid={{this.isInvalidAndTouched}}
        @error={{this.validationErrorMessages}}
        @helpText={{@helpText}}
        @errorClasses={{@errorClasses}}
        @isFakeLabelBlock={{not (has-block "label")}}
        @isFakeHelpTextBlock={{not (has-block "helpText")}}
        {{didInsert this.setValidationMessages}}
        {{didUpdate this.didUpdateValue @validations}}
        {{didUpdate this.didUpdateValue @selectedOptions}}
      >
        <:label>
          {{yield to="label"}}
        </:label>
        <:field>
          {{#let
            (component
              EuiComboBox
              onChange=this.handleChange
              options=this.options
              singleSelection=@singleSelection
              selectedOptions=@selectedOptions
              searchEnabled=(argOrDefault @searchEnabled true)
              searchField=@searchField
              search=@search
              searchMessage=@searchMessage
              searchMessageComponent=@searchMessageComponent
              searchPlaceholder=@searchPlaceholder
              placeholder=@placeholder
              placeholderComponent=@placeholderComponent
              loadingMessage=@loadingMessage
              noMatchesMessage=@noMatchesMessage
              noMatchesMessageComponent=@noMatchesMessageComponent
              beforeOptionsComponent=@beforeOptionsComponent
              afterOptionsComponent=@afterOptionsComponent
              selectedItemComponent=@selectedItemComponent
              dropdownClass=@dropdownClass
              optionsClass=@optionsClass
              onCreateOption=@onCreateOption
              alwaysShowCreateOption=@alwaysShowCreateOption
              customOptionText=@customOptionText
              delimiter=@delimiter
              isCaseSensitive=@isCaseSensitive
              sortMatchesBy=@sortMatchesBy
              matcher=@matcher
              optionMatcher=@optionMatcher
              typeAheadOptionMatcher=@typeAheadOptionMatcher
              async=@async
              onSearchChange=@onSearchChange
              noSuggestions=@noSuggestions
              truncationProps=@truncationProps
              rowHeight=@rowHeight
              onFocusBadge=@onFocusBadge
              prepend=@prepend
              append=@append
              triggerIcon=@triggerIcon
              isInvalid=this.isInvalidAndTouched
              isClearable=@isClearable
              isLoading=@isLoading
              isDisabled=@isDisabled
              readOnly=@readOnly
              fullWidth=@fullWidth
              compressed=@compressed
              closeOnSelect=@closeOnSelect
              autoFocus=(or @autoFocus @autofocus)
              initiallyOpen=@initiallyOpen
              defaultHighlighted=@defaultHighlighted
              matchTriggerWidth=@matchTriggerWidth
              renderInPlace=@renderInPlace
              horizontalPosition=@horizontalPosition
              verticalPosition=@verticalPosition
              destination=@destination
              preventScroll=@preventScroll
              calculatePosition=@calculatePosition
              eventType=@eventType
              tabindex=@tabindex
              ariaLabel=@ariaLabel
              ariaLabelledBy=@ariaLabelledBy
              required=@required
              triggerRole=@triggerRole
              title=@title
              triggerId=@triggerId
              removeTag=@removeTag
              onInput=@onInput
              onKeydown=@onKeydown
              registerApi=@registerApi
              onBlur=(queue (fn this.setIsTouched true) (optional @onBlur))
              onFocus=@onFocus
              onClose=@onClose
              onOpen=@onOpen
              extra=@extra
            )
            as |ComboBox|
          }}
            {{#if (has-block)}}
              <ComboBox class={{@fieldClasses}} ...attributes as |opt index search|>
                {{yield opt index search}}
              </ComboBox>
            {{else}}
              {{! without a block, EuiComboBox renders the option labels }}
              <ComboBox class={{@fieldClasses}} ...attributes />
            {{/if}}
          {{/let}}
        </:field>
        <:helpText as |helpText|>
          {{yield helpText to="helpText"}}
        </:helpText>
      </EuiFormRow>
    {{/let}}
  </template>
}
