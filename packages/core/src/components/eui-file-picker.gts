import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { concat } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import { and, eq, not, notEq, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id';
import argOrDefault, { argOrDefaultDecorator } from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import validatableControl from '../modifiers/validatable-control';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiIcon from './eui-icon.gts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';
import EuiProgress from './eui-progress.gts';

import type { displayMapping } from '../utils/css-mappings/eui-file-picker';

export type EuiFilePickerDisplay = keyof typeof displayMapping;

/**
 * You can find more typing on the template
 */
type EuiFilePicker = {
  id?: string;
  name?: string;
  class?: string;
  /**
   * The content that appears in the dropzone if no file is attached
   */
  initialPromptText?: Component | string | null;
  /**
   * Use as a callback to access the HTML FileList API
   */
  onChange?: (files: FileList | null) => void;
  /**
   * Reduces the size to a typical (compressed) input
   */
  compressed?: boolean;
  /**
   * Size or type of display;
   * `default` for normal height, similar to other controls;
   * `large` for taller size
   */
  display?: EuiFilePickerDisplay;
  fullWidth?: boolean;
  isInvalid?: boolean;
  isLoading?: boolean;
  disabled?: boolean;
  multiple?: boolean;

  /**
   * Optionally pass a fn to get the instance of the component to access it programatically
   */
  ref?: (c: typeof EuiFilePickerComponent) => void;
};

export interface EuiFilePickerSignature {
  Element: HTMLInputElement;
  Args: EuiFilePicker;
  Blocks: {
    default: [];
  };
}

export default class EuiFilePickerComponent extends Component<EuiFilePickerSignature> {
  @tracked fileInput: HTMLInputElement | null = null;
  @tracked promptText: string | null | undefined = null;
  @tracked isHoveringDrop = false;

  @argOrDefaultDecorator('Select or drag and drop a file') initialPromptText!:
    | Component
    | string
    | null;

  @argOrDefaultDecorator(false) compressed!: boolean;
  @argOrDefaultDecorator('') display!: string;

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

    if (this.fileInput.files && this.fileInput.files.length > 1) {
      this.promptText = `${this.fileInput.files.length} files selected`;
      // TODO: Change when EuiI18n is available
      // <EuiI18n
      //   token="euiFilePicker.filesSelected"
      //   default="{fileCount} files selected"
      //   values={{ fileCount: this.fileInput.files.length }}
      // />
    } else if (this.fileInput.files && this.fileInput.files.length === 0) {
      this.promptText = null;
    } else {
      this.promptText = this.fileInput.value.split('\\').pop();
    }

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
    {{#let
      (classNames
        (if @compressed "euiFilePicker--compressed")
        (if @fullWidth "euiFilePicker--fullWidth")
        (if @isInvalid "euiFilePicker--isInvalid")
        (if @isLoading "euiFilePicker--isLoading")
        display=this.display
        componentName="EuiFilePicker"
      )
      (argOrDefault @id (randomId))
      as |classes inputId|
    }}
      {{#let
        (if inputId (concat inputId "-filePicker__prompt") (randomId))
        (notEq this.promptText null)
        (eq this.display "default")
        as |promptId isOverridingInitialPrompt normalFormControl|
      }}
        <div
          class="{{classes}}
            {{if this.isHoveringDrop 'euiFilePicker__showDrop'}}
            {{if isOverridingInitialPrompt 'euiFilePicker--hasFiles'}}"
        >
          <div class="euiFilePicker__wrap">
            <input
              type="file"
              id={{inputId}}
              name={{@name}}
              class="euiFilePicker__input"
              disabled={{@disabled}}
              aria-describedby={{promptId}}
              multiple={{@multiple}}
              {{on "dragover" this.showDrop}}
              {{on "dragleave" this.hideDrop}}
              {{on "drop" this.hideDrop}}
              {{on "change" this.handleChange}}
              {{didInsert this.didInsertInput}}
              {{validatableControl @isInvalid}}
              ...attributes
            />
            <div class="euiFilePicker__prompt" id={{promptId}}>
              <EuiIcon
                @iconClasses="euiFilePicker__icon"
                @type="importAction"
                @size={{if true "m" "l"}}
                aria-hidden="true"
              />
              <div class="euiFilePicker__promptText">
                {{if this.promptText this.promptText this.initialPromptText}}
              </div>
              {{#if (and @isLoading normalFormControl)}}
                <EuiLoadingSpinner class="euiFilePicker__loadingSpinner" />
              {{else if isOverridingInitialPrompt}}
                {{#if normalFormControl}}
                  <button
                    type="button"
                    aria-label="Clear selected files"
                    class="euiFilePicker__clearButton"
                    {{on "click" this.removeFiles}}
                  >
                    <EuiIcon
                      @iconClasses="euiFilePicker__clearIcon"
                      @type="cross"
                    />
                  </button>
                {{else}}
                  <EuiButtonEmpty
                    aria-label="Clear selected files"
                    class="euiFilePicker__clearButton"
                    @size="xs"
                    {{on "click" this.removeFiles}}
                  >
                    Remove
                  </EuiButtonEmpty>
                {{/if}}
              {{/if}}
              {{#if (and (not normalFormControl) @isLoading)}}
                <EuiProgress @size="xs" @color="accent" position="absolute" />
              {{/if}}
            </div>
          </div>
        </div>
      {{/let}}
    {{/let}}
  </template>
}
