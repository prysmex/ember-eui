import { cached } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import PowerSelectTrigger from 'ember-power-select/components/power-select/trigger';
import { and, not, or } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import {
  euiComboBoxInputStyles,
  euiFontSize,
  euiFormVariables
} from '../../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import EuiComboBoxPill from '../eui-combo-box-pill.gts';
import EuiFormControlLayout from '../eui-form-control-layout.gts';
import EuiFormLabel from '../eui-form-label.gts';
import EuiFormAppend from '../eui-form-append.gts';
import EuiFormPrepend from '../eui-form-prepend.gts';
import EuiScreenReaderOnly from '../eui-screen-reader-only.gts';
import EuiComboBoxNode from './node.gts';
import EuiComboBoxTriggerInput from './trigger/input.gts';
import {
  comboBoxAppendPrependStyles,
  comboBoxOptionLabel,
  isTextNode
} from '../../utils/eui/combo-box.ts';

import type {
  EuiFormControlLayoutClearProps,
  EuiFormControlLayoutIconShape
} from '../eui-form-control-layout-icons.gts';

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
  prepend?: unknown;
  append?: unknown;
  noSuggestions?: boolean;
  screenReaderInstructions?: string;
  searchField?: string;
  allowClear?: boolean;
  onClear?: (event?: Event) => void;
  onToggleList?: (event: MouseEvent) => void;
}

/** Upstream side nodes: one string is an EuiFormPrepend/Append label. */
const isSingleText = (node: unknown) => !Array.isArray(node) && isTextNode(node);

const nodeList = (node: unknown): unknown[] =>
  Array.isArray(node) ? node : [node];

const optionNode = (option: unknown, key: 'prepend' | 'append') =>
  option && typeof option === 'object'
    ? (option as Record<string, unknown>)[key]
    : undefined;

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

  /**
   * Upstream: `@prepend` / `@append` only show with single selection, so
   * pills never wrap onto rows taller than them.
   */
  get prepend(): unknown {
    return this.comboArgs.singleSelection ? this.comboArgs.prepend : undefined;
  }

  get append(): unknown {
    return this.comboArgs.singleSelection ? this.comboArgs.append : undefined;
  }

  get inputId(): string {
    return `ember-power-select-trigger-multiple-input-${this.comboArgs.select.uniqueId}`;
  }

  /**
   * Upstream's toggle button (`comboBoxToggleListButton`): the chevron is a
   * button opening or closing the list. Upstream `noIcon={!!noSuggestions}`:
   * no list, no chevron; none while disabled either.
   */
  @cached
  get icon(): EuiFormControlLayoutIconShape | undefined {
    const { select, noSuggestions, onToggleList } = this.comboArgs;

    if (select.disabled || noSuggestions) return undefined;

    return {
      // @ts-expect-error `icon` is curried by EuiComboBox
      type: this.args.icon ?? 'chevronSingleDown',
      side: 'right',
      'aria-label': select.isOpen
        ? 'Close list of options'
        : 'Open list of options',
      'data-test-subj': 'comboBoxToggleListButton',
      tabIndex: -1,
      onClick: (event: MouseEvent) => onToggleList?.(event)
    };
  }

  /** Upstream `clear` props: `comboBoxClearButton`, shown with a selection. */
  @cached
  get clearProps(): EuiFormControlLayoutClearProps | undefined {
    const { allowClear, onClear } = this.comboArgs;

    if (!allowClear || !onClear || !this.hasSelection) return undefined;

    return {
      'data-test-subj': 'comboBoxClearButton',
      onClick: (event: MouseEvent) => onClear(event)
    };
  }

  /** Plain text selection: the selected option, shown as the input's text. */
  get plainTextOption(): unknown {
    return this.asPlainText ? this.comboArgs.select.selected?.[0] : undefined;
  }

  /** Upstream: the input shows the search text, else the selection's label. */
  get plainTextValue(): string | undefined {
    const option = this.plainTextOption;

    if (option === undefined) return undefined;

    return comboBoxOptionLabel(option, this.comboArgs.searchField) ?? '';
  }

  /** Plain text selection's option prepend/append: upstream `xxs` spacing. */
  @cached
  get plainTextSideClasses(): { prepend: string; append: string } {
    const context = getEuiThemeContext(this);
    const styles = comboBoxAppendPrependStyles(
      String(context.upstream.euiTheme.size.xxs)
    );

    return {
      prepend: euiClass(context, styles.prepend),
      append: euiClass(context, styles.append)
    };
  }

  /**
   * The toggle button handles its own clicks: ember-basic-dropdown's
   * trigger must not toggle the list on the same press, and focus stays in
   * the input.
   */
  keepToggle = (event: Event) => {
    const target = event.target as Element | null;

    if (!target?.closest?.('[data-test-subj="comboBoxToggleListButton"]')) {
      return;
    }

    event.stopPropagation();

    if (event.type === 'mousedown') event.preventDefault();
  };

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
      select.disabled ? styles.disabled : stateCss,
      Boolean(this.prepend || this.append) && styles.inGroup
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
      @icon={{this.icon}}
      @inputId={{this.inputId}}
      @isPrependProvided={{if this.prepend true false}}
      @isAppendProvided={{if this.append true false}}
      @iconSide="right"
      {{on "mousedown" this.keepToggle capture=true}}
      {{on "touchstart" this.keepToggle capture=true}}
      {{on "touchend" this.keepToggle capture=true}}
      @fullWidth={{@fullWidth}}
      @compressed={{@compressed}}
      @readOnly={{@readOnly}}
      @isInvalid={{@isInvalid}}
      @clear={{this.clearProps}}
      @isLoading={{@isLoading}}
      @disabled={{@select.disabled}}
      @css={{this.layoutCss}}
    >
      <:prepend>
        {{#if (isSingleText this.prepend)}}
          <EuiFormPrepend
            @label={{this.prepend}}
            @inputId={{this.inputId}}
            @compressed={{@compressed}}
          />
        {{else}}
          {{#each (nodeList this.prepend) as |node|}}
            {{#if (isTextNode node)}}
              <EuiFormLabel @for={{this.inputId}}>{{node}}</EuiFormLabel>
            {{else}}
              <EuiComboBoxNode @node={{node}} />
            {{/if}}
          {{/each}}
        {{/if}}
      </:prepend>
      <:field>
        {{! template-lint-disable }}
        <div
          id="ember-power-select-multiple-options-{{@select.uniqueId}}"
          class="euiComboBox__inputWrap ember-power-select-multiple-options
            {{if this.asPlainText 'euiComboBox__inputWrap--plainText'}}
            {{this.wrapClass}}"
          data-test-subj="comboBoxInput"
          ...attributes
          {{! no ember-power-select openChange: upstream keeps the search
            text when the list closes (leftover text marks it invalid) }}
          {{on "touchstart" this.chooseOption}}
          {{on "mousedown" this.chooseOption}}
        >
          {{! template-lint-enable }}
          {{! upstream: no pill for plain text (the input shows it), and
            no single selection pill while searching }}
          {{#if
            (and
              (not this.asPlainText)
              (or
                (and @singleSelection (not @select.searchText))
                (not @singleSelection)
              )
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
          {{#let
            (optionNode this.plainTextOption "prepend")
            (optionNode this.plainTextOption "append")
            as |plainPrepend plainAppend|
          }}
          {{#if plainPrepend}}
            <span
              class="euiComboBoxPlainTextSelection__prepend
                {{this.plainTextSideClasses.prepend}}"
            ><EuiComboBoxNode
                @node={{plainPrepend}}
                @option={{this.plainTextOption}}
              /></span>
          {{/if}}
          {{#if @searchEnabled}}
            {{#let
              (component
                EuiComboBoxTriggerInput
                select=@select
                ariaActiveDescendant=@ariaActiveDescendant
                ariaLabelledBy=(or @inputAriaLabelledBy @ariaLabelledBy)
                ariaDescribedBy=@ariaDescribedBy
                ariaLabel=(or @inputAriaLabel @ariaLabel)
                listboxId=@listboxId
                tabindex=@inputTabindex
                role=@inputRole
                required=@inputRequired
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
                noSuggestions=@noSuggestions
                plainTextValue=this.plainTextValue
                asPlainText=this.asPlainText
                onPlainTextClick=@onPlainTextClick
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
            {{#if this.asPlainText}}
              {{#each @select.selected as |opt|}}
                <EuiComboBoxPill
                  @option={{opt}}
                  @searchField={{@searchField}}
                  @asPlainText={{true}}
                >{{yield opt @select}}</EuiComboBoxPill>
              {{/each}}
            {{/if}}
            <div class="euiComboBox__input {{this.spacerClass}}"></div>
          {{/if}}
          {{#if plainAppend}}
            <span
              class="euiComboBoxPlainTextSelection__append
                {{this.plainTextSideClasses.append}}"
            ><EuiComboBoxNode
                @node={{plainAppend}}
                @option={{this.plainTextOption}}
              /></span>
          {{/if}}
          {{/let}}
          {{#if @screenReaderInstructions}}
            {{! upstream: read when the input gets focus }}
            <EuiScreenReaderOnly>
              <span
                aria-live="polite"
                id="{{@select.uniqueId}}_removeOptionMessage"
              >{{@screenReaderInstructions}}</span>
            </EuiScreenReaderOnly>
          {{/if}}
        </div>
      </:field>
      <:append>
        {{#if (isSingleText this.append)}}
          <EuiFormAppend
            @label={{this.append}}
            @inputId={{this.inputId}}
            @compressed={{@compressed}}
          />
        {{else}}
          {{#each (nodeList this.append) as |node|}}
            {{#if (isTextNode node)}}
              <EuiFormLabel @for={{this.inputId}}>{{node}}</EuiFormLabel>
            {{else}}
              <EuiComboBoxNode @node={{node}} />
            {{/if}}
          {{/each}}
        {{/if}}
      </:append>
    </EuiFormControlLayout>
  </template>
}
