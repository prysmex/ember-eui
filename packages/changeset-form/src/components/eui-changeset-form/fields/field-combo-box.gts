import { assert } from '@ember/debug';
import { action } from '@ember/object';
import EuiFormRow from '@ember-eui/core/components/eui-form-row';
import { argOrDefault } from '@ember-eui/core/helpers';
import type Owner from '@ember/owner';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import queue from '@nullvoxpopuli/ember-composable-helpers/helpers/queue';
import { or } from 'ember-truth-helpers';

import { LazyComponent } from '../../../-private/lazy-component.ts';
import randomId from '../../../-private/random-id.ts';
import Base from './base.gts';

import type { BaseSignature } from './base';
import type EuiComboBox from '@ember-eui/core/components/eui-combo-box';
import type { EuiComboBoxSignature } from '@ember-eui/core/components/eui-combo-box';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';

/**
 * A combo box in an EuiFormRow bound to `@fieldName` of the form's changeset.
 * Takes EuiFormRow's and the control's args.
 */
export interface EuiChangesetFormFieldComboBoxSignature {
  Element: EuiComboBoxSignature['Element'];
  Args: BaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiComboBoxSignature['Args'] & {
      /** Required: called with the selected options. Set the changeset property here (the field only validates it), e.g. to store ids instead of objects. */
      onChange: (options: any[] | string) => void;
      /** Classes for the control. */
      fieldClasses?: string;
      /** Accessible label of the control. */
      ariaLabel?: string;
      /** Focuses the control on render. */
      autofocus?: boolean;
      /** Placeholder text. */
      placeholder?: string;
      /** The radio's own label (next to it); `@label` is the row's label. */
      radioLabel?: string;
    };

  Blocks: {
    default: EuiComboBoxSignature['Blocks']['default'];
  };
}

/**
 * In order to provide full flexibility, this component doesn't handle the setting
 * or hardcodes the selected
 */
// imported on first render (see LazyComponent)
const euiComboBox = new LazyComponent<typeof EuiComboBox>(
  () => import('@ember-eui/core/components/eui-combo-box')
);

export default class EuiChangesetFormFieldComboBox extends Base<EuiChangesetFormFieldComboBoxSignature> {
  constructor(
    owner: Owner,
    args: EuiChangesetFormFieldComboBoxSignature['Args']
  ) {
    super(owner, args);

    assert(
      `Must provide @onChange to FieldComboBox for ${this.args.fieldName}`,
      this.args.onChange
    );
  }

  @action
  handleChange(options: any[]) {
    this.args.onChange(options);
    this.validate();
  }

  /**
   * Custom options are added by the caller (Enter, the "add" option, or
   * leaving the combo box with typed text): validate again afterwards, as
   * leaving validated before the option was added.
   */
  @action
  handleCreateOption(
    ...args: Parameters<NonNullable<EuiComboBoxSignature['Args']['onCreateOption']>>
  ) {
    const result = this.args.onCreateOption?.(...args);

    this.validate();

    return result;
  }

  get EuiComboBox() {
    return euiComboBox.component;
  }

  <template>
    {{#let this.EuiComboBox as |EuiComboBox|}}
      {{#if EuiComboBox}}
        {{#let (argOrDefault @id (randomId)) as |theId|}}
          <EuiFormRow
            class={{this.rowClasses}}
            @labelType={{@labelType}}
            @display={{@display}}
            @hasEmptyLabelSpace={{@hasEmptyLabelSpace}}
            @fullWidth={{@fullWidth}}
            @hasChildLabel={{@hasChildLabel}}
            @label={{@label}}
            @labelAppend={{@labelAppend}}
            @id={{theId}}
            @isInvalid={{this.isInvalid}}
            @error={{this.errors}}
            @helpText={{@helpText}}
            @errorClasses={{@errorClasses}}
          >
            {{#let
              (component
                EuiComboBox
                onChange=this.handleChange
                options=@options
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
                onCreateOption=(if @onCreateOption this.handleCreateOption)
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
                isInvalid=this.isInvalid
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
                onBlur=(queue this.validate (optional @onBlur))
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
          </EuiFormRow>
        {{/let}}
      {{/if}}
    {{/let}}
  </template>
}
