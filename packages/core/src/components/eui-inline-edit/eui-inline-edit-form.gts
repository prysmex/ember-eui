import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { get } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';

import argOrDefault from '../../helpers/arg-or-default.ts';
import { not } from 'ember-truth-helpers';
import { randomId } from '../../-private/random-id.ts';
import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import {
  euiFormVariables,
  euiInlineEditReadModeStyles
} from '../../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import EuiButtonEmpty from '../eui-button-empty.gts';
import EuiButtonIcon from '../eui-button-icon.gts';
import EuiFieldText from '../eui-field-text.gts';
import EuiFlexGroup from '../eui-flex-group.gts';
import EuiFlexItem from '../eui-flex-item.gts';
import EuiFormLabel from '../eui-form-label.gts';
import EuiFormRow from '../eui-form-row.gts';
import EuiSkeletonLoading from '../eui-skeleton-loading.gts';
import EuiSkeletonRectangle from '../eui-skeleton-rectangle.gts';

import type { ComponentLike } from '@glint/template';
import type { TemplateOnlyComponent } from '@ember/component/template-only';
import type Owner from '@ember/owner';
import type EuiI18n from '../../services/eui-i18n';
import type { EuiCss } from '../../utils/eui/styles.ts';
import type { EuiButtonIconSignature } from '../eui-button-icon';

/** Props for the save/cancel `EuiButtonIcon`s (upstream `saveButtonProps`). */
export interface EuiInlineEditButtonProps {
  /** Called after the save/cancel itself. */
  onClick?: (event: MouseEvent) => void;
  'aria-label'?: string;
  'data-test-subj'?: string;
  title?: string;
  color?: EuiButtonIconSignature['Args']['color'];
  display?: EuiButtonIconSignature['Args']['display'];
  iconType?: EuiButtonIconSignature['Args']['iconType'];
  isDisabled?: boolean;
}

/** Arguments shared by `EuiInlineEditText` and `EuiInlineEditTitle`. */
export interface EuiInlineEditCommonArgs {
  /** Text shown (and used as the input placeholder) while there is no value. */
  placeholder?: string;
  /**
   * Called with the edited text when saving. Return (or resolve to) `false`
   * to stay in edit mode, e.g. to show `@isInvalid` or `@isLoading`.
   */
  onSave?: (value: string) => void | boolean | Promise<boolean | void>;
  /**
   * Accessible name of the input (required: the input has no visible
   * label).
   */
  inputAriaLabel: string;
  /** Starts in edit mode. */
  startWithEditOpen?: boolean;
  /** Initial text (uncontrolled). */
  defaultValue?: string;
  /**
   * The text, for controlled usage: update it from `@onChange` and reset it
   * from `@onCancel`.
   */
  value?: string;
  /** Called on every input event in edit mode (controlled usage). */
  onChange?: (event: Event) => void;
  /** Called with the previous read mode text when the edit is cancelled. */
  onCancel?: (previousValue: string) => void;
  /** Loading state, shown in edit mode (spinner, skeleton buttons). */
  isLoading?: boolean;
  /** Invalid state, shown in edit mode (with `editModeProps.formRowProps.error`). */
  isInvalid?: boolean;
  /** Locks read mode and shows the text without the edit affordance. */
  isReadOnly?: boolean;
  /**
   * Upstream `readModeProps` for the read mode `EuiButtonEmpty`. Supported:
   * `onClick` (called after edit mode opens), `buttonRef`, `title`,
   * `aria-describedby` (added to the instructions), `data-test-subj`,
   * `color` (any `EuiButtonEmpty` color, defaults to `'text'`) and
   * `iconSide` (`'left'` or `'right'`, defaults to `'right'`).
   */
  readModeProps?: {
    color?: string;
    iconSide?: 'left' | 'right';
    onClick?: (event: MouseEvent) => void;
    buttonRef?: (element: HTMLElement) => void;
    title?: string;
    'aria-describedby'?: string;
    'data-test-subj'?: string;
  };
  /**
   * Upstream `editModeProps`:
   * - `formRowProps`: `error` (shown while `@isInvalid`), `helpText`,
   *   `data-test-subj`
   * - `inputProps`: `onChange`, `onKeyDown` (called after the inline edit's
   *   own handling), `inputRef`, `aria-describedby`, `name`, `maxLength`,
   *   `data-test-subj`, `readOnly`, `prepend` and `append` (text, shown in
   *   an `EuiFormLabel`, or a component)
   * - `saveButtonProps` / `cancelButtonProps`: see `EuiInlineEditButtonProps`
   */
  editModeProps?: {
    formRowProps?: {
      error?: string | string[];
      helpText?: string;
      'data-test-subj'?: string;
    };
    inputProps?: {
      onChange?: (event: Event) => void;
      onKeyDown?: (event: KeyboardEvent) => void;
      inputRef?: (element: HTMLInputElement | null) => void;
      'aria-describedby'?: string;
      name?: string;
      maxLength?: number;
      readOnly?: boolean;
      prepend?: string | ComponentLike;
      append?: string | ComponentLike;
      'data-test-subj'?: string;
    };
    saveButtonProps?: EuiInlineEditButtonProps;
    cancelButtonProps?: EuiInlineEditButtonProps;
  };
  /**
   * Extra styles composed last into this component's class (like upstream's
   * `css` prop).
   */
  css?: EuiCss;
}

/** Upstream `SMALL_SIZE_FORM` / `MEDIUM_SIZE_FORM`. */
export interface EuiInlineEditSizes {
  iconSize: 's' | 'm';
  compressed: boolean;
  buttonSize: 's' | 'm';
}
export const SMALL_SIZE_FORM: EuiInlineEditSizes = {
  iconSize: 's',
  compressed: true,
  buttonSize: 's'
};
export const MEDIUM_SIZE_FORM: EuiInlineEditSizes = {
  iconSize: 'm',
  compressed: false,
  buttonSize: 'm'
};

/** A string `prepend`/`append` is a label (upstream), anything else a component. */
const SideContent = <template>
  {{#if (isString @content)}}
    <EuiFormLabel class={{@class}} @for={{@inputId}}>{{asText @content}}</EuiFormLabel>
  {{else if @content}}
    {{#let (asComponent @content) as |Content|}}<Content />{{/let}}
  {{/if}}
</template> as TemplateOnlyComponent<{
  Args: {
    content?: string | ComponentLike;
    class?: string;
    inputId?: string;
  };
}>;

function isString(value: unknown): boolean {
  return typeof value === 'string';
}

function asText(value: unknown): string {
  return String(value);
}

function asComponent(value: unknown): ComponentLike {
  return value as ComponentLike;
}

export interface EuiInlineEditFormSignature {
  Element: HTMLDivElement;
  Args: EuiInlineEditCommonArgs & {
    /** @private Form sizes. */
    sizes: EuiInlineEditSizes;
    /** @private Root class names (`euiInlineEditText` / `…Title`). */
    className: string;
    /** @private Root styles of the consumer component. */
    rootCss: EuiCss;
    /** @private Read mode button `role` (read only). */
    readModeRole?: string;
    /** @private Read mode button `aria-level` (read-only headings). */
    readModeAriaLevel?: number;
  };
  Blocks: {
    /** Renders the read mode text; yields it. */
    default: [readModeValue: string];
  };
}

/**
 * @private Upstream `EuiInlineEditForm`: the shared read/edit mode
 * implementation of EuiInlineEditText and EuiInlineEditTitle.
 */
export default class EuiInlineEditForm extends Component<EuiInlineEditFormSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked _isEditing = Boolean(this.args.startWithEditOpen);
  @tracked editModeValue = this.args.defaultValue ?? '';
  // Like upstream, also seeded with the controlled value as an onCancel backup.
  @tracked readModeValue: string;

  /** Which element takes focus once it renders (after a mode switch). */
  pendingFocus: 'read' | 'edit' | null = null;

  constructor(owner: Owner, args: EuiInlineEditFormSignature['Args']) {
    super(owner, args);
    // Seeded eagerly: tracked field initializers run lazily on first read,
    // which would pick up a controlled value changed since.
    this.readModeValue = args.value || args.defaultValue || '';
  }

  readModeDescribedById = `inlineEdit_${randomId()}`;
  editModeDescribedById = `inlineEdit_${randomId()}`;

  get context() {
    return getEuiThemeContext(this);
  }
  get isEditing() {
    // Read-only always shows read mode (upstream switches back to it).
    return this._isEditing && !this.args.isReadOnly;
  }
  get value() {
    if (this.args.value) return this.args.value;
    return this.isEditing
      ? this.editModeValue
      : this.readModeValue || this.args.placeholder || '';
  }

  // i18n
  get saveButtonAriaLabel() {
    return this.euiI18n.lookupToken(
      'euiInlineEditForm.saveButtonAriaLabel',
      'Save edit'
    );
  }
  get cancelButtonAriaLabel() {
    return this.euiI18n.lookupToken(
      'euiInlineEditForm.cancelButtonAriaLabel',
      'Cancel edit'
    );
  }
  get inputKeyboardInstructions() {
    return this.euiI18n.lookupToken(
      'euiInlineEditForm.inputKeyboardInstructions',
      'Press Enter to save your edited text. Press Escape to cancel your edit.'
    );
  }
  get activateEditModeDescription() {
    return this.euiI18n.lookupToken(
      'euiInlineEditForm.activateEditModeDescription',
      'Click to edit this text inline.'
    );
  }
  // prop bags
  get readModeProps() {
    return this.args.readModeProps ?? {};
  }
  get formRowProps() {
    return this.args.editModeProps?.formRowProps ?? {};
  }
  get inputProps() {
    return this.args.editModeProps?.inputProps ?? {};
  }
  get saveButtonProps() {
    return this.args.editModeProps?.saveButtonProps ?? {};
  }
  get cancelButtonProps() {
    return this.args.editModeProps?.cancelButtonProps ?? {};
  }
  get readModeAriaDescribedBy() {
    return [this.readModeDescribedById, this.readModeProps['aria-describedby']]
      .filter(Boolean)
      .join(' ');
  }
  get editModeAriaDescribedBy() {
    return [this.editModeDescribedById, this.inputProps['aria-describedby']]
      .filter(Boolean)
      .join(' ');
  }
  get formRowError() {
    return this.args.isInvalid ? this.formRowProps.error : undefined;
  }

  @cached
  get classes() {
    return `euiInlineEdit ${this.args.className} ${euiClass(
      this.context,
      { boxSizing: 'border-box' },
      this.args.rootCss,
      this.args.css
    )}`;
  }

  /** Composed last into the read mode EuiButtonEmpty (upstream `css`). */
  @cached
  get readModeCss() {
    const styles = useEuiBorealisStyles(
      this.context,
      euiInlineEditReadModeStyles
    );
    return [
      styles.euiInlineEditReadMode,
      this.args.isReadOnly && styles.isReadOnly,
      this.args.placeholder && !this.readModeValue && styles.hasPlaceholder
    ];
  }

  /** Upstream `loadingSkeletonSize`: the control height. */
  get skeletonSize() {
    const form = useEuiBorealisStyles(this.context, euiFormVariables);
    return this.args.sizes.compressed
      ? form.controlCompressedHeight
      : form.controlHeight;
  }

  // focus management: focus the element of the new mode once it renders
  @action
  readModeButtonInserted(element: HTMLElement) {
    this.readModeProps.buttonRef?.(element);
    if (this.pendingFocus === 'read') {
      this.pendingFocus = null;
      element.focus();
    }
  }
  @action
  inputInserted(element: HTMLInputElement | null) {
    this.inputProps.inputRef?.(element);
    if (element && this.pendingFocus === 'edit') {
      this.pendingFocus = null;
      element.focus();
    }
  }
  @action
  readOnlyChanged() {
    // Switching to read-only while editing returns to read mode for good.
    if (this.args.isReadOnly) this._isEditing = false;
  }

  @action
  activateEditMode(event: MouseEvent) {
    this.pendingFocus = 'edit';
    this._isEditing = true;
    this.readModeProps.onClick?.(event);
  }

  @action
  cancel() {
    this.editModeValue = this.readModeValue;
    this.args.onCancel?.(this.readModeValue);
    this.pendingFocus = 'read';
    this._isEditing = false;
  }

  /**
   * Not wrapped in a test waiter: the promise belongs to the app's `@onSave`
   * (it can wait for user input, e.g. a confirmation), and the edit mode
   * stays usable meanwhile.
   */
  @action
  async save() {
    const { onSave } = this.args;
    if (onSave) {
      const result = onSave(this.value);
      const awaited = result instanceof Promise ? await result : result;
      if (awaited === false || this.isDestroying || this.isDestroyed) return;
    }
    this.readModeValue = this.editModeValue;
    this.pendingFocus = 'read';
    this._isEditing = false;
  }

  @action
  onInput(event: Event) {
    this.editModeValue = (event.target as HTMLInputElement).value;
    this.args.onChange?.(event);
    this.inputProps.onChange?.(event);
  }

  @action
  onKeyDown(event: KeyboardEvent) {
    switch (event.key) {
      case 'Enter':
        // Enter keypresses do not proceed otherwise on WebKit and screen readers.
        event.preventDefault();
        void this.save();
        break;
      case 'Escape':
        this.cancel();
        break;
    }
    this.inputProps.onKeyDown?.(event);
  }

  @action
  onSaveClick(event: MouseEvent) {
    void this.save();
    this.saveButtonProps.onClick?.(event);
  }
  @action
  onCancelClick(event: MouseEvent) {
    this.cancel();
    this.cancelButtonProps.onClick?.(event);
  }

  <template>
    <div
      class={{this.classes}}
      ...attributes
      {{didUpdate this.readOnlyChanged @isReadOnly}}
    >
      {{#if this.isEditing}}
        <EuiFlexGroup @gutterSize="s" @responsive={{false}}>
          <EuiFlexItem>
            <EuiFormRow
              @fullWidth={{true}}
              @isInvalid={{@isInvalid}}
              @error={{this.formRowError}}
              @helpText={{this.formRowProps.helpText}}
              data-test-subj={{get this.formRowProps "data-test-subj"}}
            >
              <EuiFieldText
                @fullWidth={{true}}
                @value={{this.value}}
                @compressed={{@sizes.compressed}}
                @isInvalid={{@isInvalid}}
                @isLoading={{@isLoading}}
                @readOnly={{this.inputProps.readOnly}}
                @isFakePrependBlock={{not this.inputProps.prepend}}
                @isFakeAppendBlock={{not this.inputProps.append}}
                @inputRef={{this.inputInserted}}
                aria-label={{@inputAriaLabel}}
                placeholder={{if @placeholder @placeholder}}
                name={{this.inputProps.name}}
                maxlength={{this.inputProps.maxLength}}
                data-test-subj={{if
                  (get this.inputProps "data-test-subj")
                  (get this.inputProps "data-test-subj")
                  "euiInlineEditModeInput"
                }}
                aria-describedby={{this.editModeAriaDescribedBy}}
                {{on "input" this.onInput}}
                {{on "keydown" this.onKeyDown}}
              >
                <:prepend as |classes inputId|>
                  <SideContent
                    @content={{this.inputProps.prepend}}
                    @class={{classes}}
                    @inputId={{inputId}}
                  />
                </:prepend>
                <:append as |classes inputId|>
                  <SideContent
                    @content={{this.inputProps.append}}
                    @class={{classes}}
                    @inputId={{inputId}}
                  />
                </:append>
              </EuiFieldText>
            </EuiFormRow>
            <span id={{this.editModeDescribedById}} hidden>
              {{this.inputKeyboardInstructions}}
            </span>
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiSkeletonLoading
              @isLoading={{if @isLoading true false}}
              @announceLoadingStatus={{true}}
              @announceLoadedStatus={{false}}
            >
              <:loadingContent as |loading|>
                <EuiFlexGroup
                  @gutterSize="s"
                  role={{loading.role}}
                  aria-label={{loading.ariaLabel}}
                >
                  <EuiSkeletonRectangle
                    @width={{this.skeletonSize}}
                    @height={{this.skeletonSize}}
                    @borderRadius="m"
                  />
                  <EuiSkeletonRectangle
                    @width={{this.skeletonSize}}
                    @height={{this.skeletonSize}}
                    @borderRadius="m"
                  />
                </EuiFlexGroup>
              </:loadingContent>
              <:loadedContent>
                <EuiFlexGroup @gutterSize="s">
                  <EuiButtonIcon
                    @iconType={{if
                      this.saveButtonProps.iconType
                      this.saveButtonProps.iconType
                      "check"
                    }}
                    @color={{if
                      this.saveButtonProps.color
                      this.saveButtonProps.color
                      "success"
                    }}
                    @display={{if
                      this.saveButtonProps.display
                      this.saveButtonProps.display
                      "base"
                    }}
                    @size={{@sizes.buttonSize}}
                    @iconSize={{@sizes.iconSize}}
                    @isDisabled={{this.saveButtonProps.isDisabled}}
                    aria-label={{if
                      (get this.saveButtonProps "aria-label")
                      (get this.saveButtonProps "aria-label")
                      this.saveButtonAriaLabel
                    }}
                    title={{this.saveButtonProps.title}}
                    data-test-subj={{if
                      (get this.saveButtonProps "data-test-subj")
                      (get this.saveButtonProps "data-test-subj")
                      "euiInlineEditModeSaveButton"
                    }}
                    {{on "click" this.onSaveClick}}
                  />
                  <EuiButtonIcon
                    @iconType={{if
                      this.cancelButtonProps.iconType
                      this.cancelButtonProps.iconType
                      "cross"
                    }}
                    @color={{if
                      this.cancelButtonProps.color
                      this.cancelButtonProps.color
                      "danger"
                    }}
                    @display={{if
                      this.cancelButtonProps.display
                      this.cancelButtonProps.display
                      "base"
                    }}
                    @size={{@sizes.buttonSize}}
                    @iconSize={{@sizes.iconSize}}
                    @isDisabled={{this.cancelButtonProps.isDisabled}}
                    aria-label={{if
                      (get this.cancelButtonProps "aria-label")
                      (get this.cancelButtonProps "aria-label")
                      this.cancelButtonAriaLabel
                    }}
                    title={{this.cancelButtonProps.title}}
                    data-test-subj={{if
                      (get this.cancelButtonProps "data-test-subj")
                      (get this.cancelButtonProps "data-test-subj")
                      "euiInlineEditModeCancelButton"
                    }}
                    {{on "click" this.onCancelClick}}
                  />
                </EuiFlexGroup>
              </:loadedContent>
            </EuiSkeletonLoading>
          </EuiFlexItem>
        </EuiFlexGroup>
      {{else}}
        <EuiButtonEmpty
          @color={{argOrDefault this.readModeProps.color "text"}}
          @iconType={{unless @isReadOnly "pencil"}}
          @iconSide={{argOrDefault this.readModeProps.iconSide "right"}}
          @flush="both"
          @iconSize={{@sizes.iconSize}}
          @size={{@sizes.buttonSize}}
          @isDisabled={{@isReadOnly}}
          @css={{this.readModeCss}}
          title={{if this.readModeProps.title this.readModeProps.title this.value}}
          data-test-subj={{if
            (get this.readModeProps "data-test-subj")
            (get this.readModeProps "data-test-subj")
            "euiInlineReadModeButton"
          }}
          role={{@readModeRole}}
          aria-level={{@readModeAriaLevel}}
          aria-describedby={{this.readModeAriaDescribedBy}}
          {{on "click" this.activateEditMode}}
          {{didInsert this.readModeButtonInserted}}
        >{{yield this.value}}</EuiButtonEmpty>
        <span id={{this.readModeDescribedById}} hidden>
          {{#unless @isReadOnly}}{{this.activateEditModeDescription}}{{/unless}}
        </span>
      {{/if}}
    </div>
  </template>
}
