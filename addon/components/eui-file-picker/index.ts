import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { argOrDefaultDecorator as argOrDefault } from 'ember-eui/helpers/arg-or-default';
import { displayMapping } from 'ember-eui/utils/css-mappings/eui-file-picker';

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
};

export default class EuiFilePickerComponent extends Component<EuiFilePicker> {
  @tracked fileInput: HTMLInputElement | null = null;
  @tracked promptText: string | null | undefined = null;
  @tracked isHoveringDrop: boolean = false;

  @argOrDefault('Select or drag and drop a file') initialPromptText!: Component | string | null;
  @argOrDefault(false) compressed!: boolean;
  @argOrDefault('large') display!: string;

  @action
  showDrop() {
    if (!this.args.disabled) {
      this.isHoveringDrop = true;
    }
  }

  @action
  hideDrop() {
    this.isHoveringDrop = false;
  }

  @action
  handleChange(filesSelected?: string | null) {
    if (!this.fileInput) return;

    if (this.fileInput.files && this.fileInput.files.length > 1) {
      this.promptText = `${this.fileInput.files.length} ${filesSelected}`;
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
  removeFiles(e: MouseEvent) {
    e.stopPropagation();
    e.preventDefault();

    if (!this.fileInput) return;

    this.fileInput.value = '';
    this.handleChange(null);
  }

  @action
  didInsertInput(inputRef: HTMLInputElement) {
    this.fileInput = inputRef;
  }
}
