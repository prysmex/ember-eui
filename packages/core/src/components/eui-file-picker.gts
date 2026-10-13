import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { service } from '@ember/service';

import { randomId } from '../-private/random-id.ts';
import validatableControl from '../modifiers/validatable-control.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiFilePickerStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiFormControlLayoutClearButton from './eui-form-control-layout-clear-button.gts';
import EuiIcon from './eui-icon.gts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';
import EuiProgress from './eui-progress.gts';

import type EuiI18n from '../services/eui-i18n';
import type { CSSObject } from '@emotion/css/create-instance';

/**
 * `'default'`: the height of the other form controls. `'large'`: a taller
 * drop zone. `'none'` is a deprecated alias of `'default'`.
 */
export type EuiFilePickerDisplay = 'default' | 'large' | 'none';

/**
 * You can find more typing on the template
 */
type EuiFilePicker = {
  /** Id of the file input. Defaults to a random id. */
  id?: string;
  /** `name` of the file input, for forms. */
  name?: string;
  /** @deprecated Has no effect, use `class=`. */
  class?: string;
  /**
   * The content that appears in the dropzone if no file is attached.
   * Defaults to "Select or drag and drop a file"
   * (`euiFilePicker.promptText`).
   */
  initialPromptText?: Component | string | null;
  /**
   * Called with the selected files (a `FileList`) when they change,
   * including when they are removed (an empty list).
   */
  onChange?: (files: FileList | null) => void;
  /**
   * Reduces the size to a typical (compressed) input
   */
  compressed?: boolean;
  /**
   * Size or type of display;
   * `default` for normal height, similar to other controls;
   * `large` for taller size. Defaults to `default`.
   */
  display?: EuiFilePickerDisplay;
  /** Stretches the picker to its container's width. */
  fullWidth?: boolean;
  /**
   * Shows the invalid state (danger border and warning icon), sets
   * `aria-invalid` and marks the input invalid for native form validation.
   */
  isInvalid?: boolean;
  /** Shows a spinner (`default`) or a progress bar (`large`). */
  isLoading?: boolean;
  /** Disables the picker. */
  disabled?: boolean;
  /** Allows selecting several files. */
  multiple?: boolean;
  /**
   * Files to show as selected (their name, or "N files selected"), e.g. to
   * keep the prompt when a multi-step form re-renders the picker. Browsers
   * don't let the file input itself be set: keep the files in your state.
   * A new array replaces whatever the user picked since.
   */
  files?: File[] | null;

  /**
   * Called with the component instance, e.g. to call its `removeFiles()`
   * action and reset the picker.
   */
  ref?: (c: typeof EuiFilePickerComponent) => void;
};

/**
 * A file input styled as a drop zone. Attributes such as `accept` go to the
 * `<input type="file">`.
 */
export interface EuiFilePickerSignature {
  Element: HTMLInputElement;
  Args: EuiFilePicker;
  Blocks: {
    /** Unused. */
    default: [];
  };
}

/** Ember has no React global `*` box-sizing reset. */
const boxReset: CSSObject = { boxSizing: 'border-box' };

/** Reset of the invisible `<input>` (React global reset: no margin). */
const inputReset: CSSObject = { boxSizing: 'border-box', margin: 0, padding: 0 };

/**
 * Upstream composes `euiFilePicker__clearButton` (and, for the default
 * display, the right icon position) into the clear button / spinner
 * themselves. Those migrated children take no `@css` yet, so the same
 * styles go on a wrapper; `pointer-events` is inherited by the child.
 */
const rightIconWrapperReset: CSSObject = { display: 'flex', lineHeight: 0 };

/**
 * Upstream `EuiFilePicker` (EUI 123.1.0 `euiFilePickerStyles`): an invisible
 * native file input over a dashed prompt, in a `default` (form control
 * height) or `large` (drop zone) display.
 */
export default class EuiFilePickerComponent extends Component<EuiFilePickerSignature> {
  @service('eui-i18n') declare euiI18n: EuiI18n;

  @tracked fileInput: HTMLInputElement | null = null;
  /** The prompt after the user picked or removed files (UI state). */
  @tracked pickedPromptText: string | null = null;
  @tracked hasPicked = false;
  /** `@files` when the user last picked: a new `@files` wins again. */
  @tracked filesWhenPicked: File[] | null | undefined = undefined;
  @tracked isHoveringDrop = false;

  generatedId = randomId();

  get inputId(): string {
    return this.args.id ?? this.generatedId;
  }

  get promptId(): string {
    return `${this.inputId}-filePicker__prompt`;
  }

  get initialPromptText(): Component | string | null {
    if (this.args.initialPromptText !== undefined) {
      return this.args.initialPromptText;
    }

    return this.euiI18n.lookupToken(
      'euiFilePicker.promptText',
      'Select or drag and drop a file'
    );
  }

  get normalFormControl(): boolean {
    return this.args.display !== 'large';
  }

  /** Upstream `getPromptTextFromFileList`. */
  promptFromFiles(files: File[] | null | undefined): string | null {
    if (!files || files.length === 0) return null;

    if (files.length > 1) {
      return this.euiI18n.lookupToken(
        'euiFilePicker.filesSelected',
        '{fileCount} files selected',
        { fileCount: files.length }
      );
    }

    return files[0]!.name;
  }

  /**
   * Upstream keeps the prompt in state, set from `files` initially and
   * whenever `files` changes, and from the input when the user picks.
   */
  get promptText(): string | null {
    if (this.hasPicked && this.filesWhenPicked === this.args.files) {
      return this.pickedPromptText;
    }

    return this.promptFromFiles(this.args.files);
  }

  get isOverridingInitialPrompt(): boolean {
    return this.promptText != null;
  }

  get showClearButton(): boolean {
    return this.isOverridingInitialPrompt && !this.args.disabled;
  }

  get showSpinner(): boolean {
    return Boolean(this.args.isLoading) && this.normalFormControl;
  }

  get showProgress(): boolean {
    return Boolean(this.args.isLoading) && !this.normalFormControl;
  }

  get removeSelectedAriaLabel(): string {
    return this.euiI18n.lookupToken(
      'euiFilePicker.removeSelectedAriaLabel',
      'Remove selected files'
    );
  }

  get removeSelectedText(): string {
    return this.euiI18n.lookupToken('euiFilePicker.removeSelected', 'Remove');
  }

  get iconType(): string {
    // Upstream `warning` / `minusCircle` / `upload`.
    if (this.args.isInvalid) return 'warning';
    if (this.args.disabled) return 'minusCircle';
    return 'upload';
  }

  get iconColor(): string {
    // Upstream passes `'disabled'`, which is not a named icon color and so
    // ends up inheriting the disabled prompt color.
    if (this.args.isInvalid) return 'danger';
    if (this.args.disabled) return 'inherit';
    return 'text';
  }

  get rootStateClasses(): string {
    return [
      'euiFilePicker',
      this.isHoveringDrop && 'euiFilePicker-isDroppingFile',
      this.args.isInvalid && 'euiFilePicker-isInvalid',
      this.args.isLoading && 'euiFilePicker-isLoading',
      this.isOverridingInitialPrompt && 'euiFilePicker-hasFiles'
    ]
      .filter(Boolean)
      .join(' ');
  }

  @cached
  get styles() {
    const context = getEuiThemeContext(this);
    return {
      context,
      styles: useEuiBorealisStyles(context, euiFilePickerStyles)
    };
  }

  @cached
  get rootClass(): string {
    const { context, styles } = this.styles;
    const { disabled, fullWidth, isInvalid, isLoading } = this.args;
    // Same order as upstream's `cssStyles`.
    return euiClass(
      context,
      boxReset,
      styles.euiFilePicker,
      fullWidth ? styles.fullWidth : styles.formWidth,
      this.isHoveringDrop && styles.isDroppingFile,
      isInvalid && !disabled && styles.invalid,
      this.isOverridingInitialPrompt && !disabled && styles.hasFiles,
      isLoading && styles.loading
    );
  }

  @cached
  get inputClass(): string {
    const { context, styles } = this.styles;
    return euiClass(
      context,
      inputReset,
      styles.input.euiFilePicker__input,
      !this.normalFormControl &&
        !this.args.disabled &&
        styles.input.largeInteractive
    );
  }

  @cached
  get promptClass(): string {
    const { context, styles } = this.styles;
    const { compressed, disabled } = this.args;
    return euiClass(
      context,
      boxReset,
      styles.euiFilePicker__prompt,
      disabled && styles.disabled,
      ...(this.normalFormControl
        ? [compressed ? styles.compressed : styles.uncompressed]
        : [
            styles.large.large,
            compressed ? styles.large.compressed : styles.large.uncompressed
          ])
    );
  }

  @cached
  get iconCss() {
    const { styles } = this.styles;
    return [
      styles.icon.euiFilePicker__icon,
      ...(this.normalFormControl
        ? [
            styles.icon.normal,
            this.args.compressed
              ? styles.icon.compressed
              : styles.icon.uncompressed
          ]
        : [styles.icon.large])
    ];
  }

  /** Default display: the clear button / spinner position. */
  @cached
  get rightIconClass(): string {
    const { context, styles } = this.styles;
    return euiClass(
      context,
      rightIconWrapperReset,
      styles.euiFilePicker__clearButton,
      styles.rightIcon.euiFilePicker__rightIcon,
      this.args.compressed
        ? styles.rightIcon.compressed
        : styles.rightIcon.uncompressed
    );
  }

  /** Large display: the "Remove" button. */
  @cached
  get removeButtonWrapperClass(): string {
    const { context, styles } = this.styles;
    return euiClass(context, styles.euiFilePicker__clearButton);
  }

  get childSize(): 's' | 'm' {
    return this.args.compressed ? 's' : 'm';
  }

  @action
  showDrop(): void {
    if (!this.args.disabled) {
      this.isHoveringDrop = true;
    }
  }

  @action
  hideDrop(): void {
    this.isHoveringDrop = false;
  }

  @action
  handleChange(): void {
    if (!this.fileInput) return;

    const files = this.fileInput.files;
    let promptText: string | null;

    if (files && files.length === 1) {
      promptText = this.fileInput.value.split('\\').pop() || files[0]!.name;
    } else {
      promptText = this.promptFromFiles(files ? Array.from(files) : null);
    }

    this.pickedPromptText = promptText;
    this.filesWhenPicked = this.args.files;
    this.hasPicked = true;

    const { onChange } = this.args;

    if (onChange) {
      onChange(this.fileInput.files);
    }
  }

  @action
  removeFiles(e?: MouseEvent): void {
    if (e) {
      e.stopPropagation();
      e.preventDefault();
    }

    if (!this.fileInput) return;

    this.fileInput.value = '';
    this.handleChange();
  }

  @action
  didInsertInput(inputRef: HTMLInputElement): void {
    this.fileInput = inputRef;
    this.args.ref?.(this as any as typeof EuiFilePickerComponent);
  }

  willDestroy(): void {
    super.willDestroy();

    this.fileInput = null;
  }

  <template>
    <div class="{{this.rootStateClasses}} {{this.rootClass}}">
      <input
        type="file"
        id={{this.inputId}}
        name={{@name}}
        class="euiFilePicker__input {{this.inputClass}}"
        disabled={{@disabled}}
        aria-describedby={{this.promptId}}
        aria-invalid={{if @isInvalid "true"}}
        multiple={{@multiple}}
        {{on "dragover" this.showDrop}}
        {{on "dragleave" this.hideDrop}}
        {{on "drop" this.hideDrop}}
        {{on "change" this.handleChange}}
        {{didInsert this.didInsertInput}}
        {{validatableControl @isInvalid}}
        ...attributes
      />
      <div class="euiFilePicker__prompt {{this.promptClass}}" id={{this.promptId}}>
        <EuiIcon
          @iconClasses="euiFilePicker__icon"
          @css={{this.iconCss}}
          @type={{this.iconType}}
          @color={{this.iconColor}}
          @size={{if this.normalFormControl "m" "l"}}
          aria-hidden="true"
        />
        <span class="euiFilePicker__promptText">
          {{if this.promptText this.promptText this.initialPromptText}}
        </span>
        {{#if this.showSpinner}}
          <span class={{this.rightIconClass}}>
            <EuiLoadingSpinner
              class="euiFilePicker__loadingSpinner"
              @size={{this.childSize}}
            />
          </span>
        {{else if this.showClearButton}}
          {{#if this.normalFormControl}}
            <span class={{this.rightIconClass}}>
              <EuiFormControlLayoutClearButton
                class="euiFilePicker__clearButton"
                @label={{this.removeSelectedAriaLabel}}
                @size={{this.childSize}}
                {{on "click" this.removeFiles}}
              />
            </span>
          {{else}}
            <span class={{this.removeButtonWrapperClass}}>
              <EuiButtonEmpty
                aria-label={{this.removeSelectedAriaLabel}}
                class="euiFilePicker__clearButton"
                @size="xs"
                {{on "click" this.removeFiles}}
              >
                {{this.removeSelectedText}}
              </EuiButtonEmpty>
            </span>
          {{/if}}
        {{/if}}
        {{#if this.showProgress}}
          <EuiProgress @size="xs" @color="accent" @position="absolute" />
        {{/if}}
      </div>
    </div>
  </template>
}
