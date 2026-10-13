import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { run } from '@ember/runloop';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiMarkdownEditorDropZoneStyles } from '../utils/eui/styles.generated.ts';
import resizeObserver from '../modifiers/resize-observer.ts';
import EuiMarkdownEditorFooter from './eui-markdown-editor-footer.gts';

import type {
  EuiMarkdownDropHandler,
  EuiMarkdownStringTagConfig
} from '../utils/markdown/markdown-types';
import type { EuiMarkdownEditorFooterSignature } from './eui-markdown-editor-footer';
import type { CSSObject } from '@emotion/css/create-instance';

/** The hidden file input (react-dropzone's `getInputProps()`). */
const hiddenInput: CSSObject = { display: 'none' };

/** Files (or drag items) no handler accepts, as upstream. */
export function getUnacceptedItems(
  items: ArrayLike<{ type: string }>,
  dropHandlers: EuiMarkdownDropHandler[]
) {
  const unacceptedItems = [];

  for (let i = 0; i < items.length; i++) {
    const item = items[i]!;

    if (!dropHandlers.some((handler) => handler.accepts(item.type))) {
      unacceptedItems.push(item);
    }
  }

  return unacceptedItems;
}

/** @private EuiMarkdownEditor's area accepting dropped or picked files. */
export interface EuiMarkdownEditorDropZoneSignature {
  Element: HTMLDivElement;
  Args: {
    /** The editor's plugins, for the footer's help. */
    uiPlugins?: EuiMarkdownEditorFooterSignature['Args']['uiPlugins'];
    /** Errors listed in the footer; they also mark the textarea invalid. */
    errors?: EuiMarkdownEditorFooterSignature['Args']['errors'];
    /** Handlers turning dropped files into markdown. None disables dropping. */
    dropHandlers?: EuiMarkdownDropHandler[];
    /** Inserts the markdown produced for a dropped file. */
    insertText?: (text: string, config: EuiMarkdownStringTagConfig) => void;
    /** A dropped file had no handler (owned by the editor). */
    hasUnacceptedItems?: boolean;
    /** Updates `@hasUnacceptedItems`. */
    setHasUnacceptedItems?: (value: boolean) => void;
    /** Called with the footer's height (px) when it changes. */
    setEditorFooterHeight?: (height: number) => void;
    /** Marks the textarea invalid (Ember `@isInvalid`). */
    isInvalid?: boolean;
    /** Renders the footer. Defaults to `true`. */
    showFooter?: boolean;
    /** Disables dropping and the footer buttons. */
    readOnly?: boolean;
    /** @deprecated Upload state is tracked internally. */
    isUploadingFiles?: boolean;
  };
  Blocks: {
    /** The textarea. */
    default: [];
  };
}

export default class EuiMarkdownEditorDropZone extends Component<EuiMarkdownEditorDropZoneSignature> {
  @tracked isDragging = false;
  @tracked isDraggingError = false;
  @tracked isUploadingFiles = false;

  fileInput: HTMLInputElement | null = null;

  get dropHandlers() {
    return this.args.dropHandlers ?? [];
  }

  get isDisabled() {
    return this.dropHandlers.length === 0 || !!this.args.readOnly;
  }

  get showFooter() {
    return this.args.showFooter ?? true;
  }

  get hasError() {
    return (
      !!this.args.hasUnacceptedItems ||
      (this.args.errors?.length ?? 0) > 0 ||
      !!this.args.isInvalid
    );
  }

  @cached
  get styles() {
    const context = getEuiThemeContext(this);

    return {
      context,
      styles: useEuiBorealisStyles(context, euiMarkdownEditorDropZoneStyles)
    };
  }

  @cached
  get classes() {
    const { context, styles } = this.styles;

    return euiClass(
      context,
      styles.euiMarkdownEditorDropZone,
      this.isDragging && !this.isDraggingError ? styles.isDragging : undefined,
      this.isDraggingError ? styles.isDraggingError : undefined,
      this.hasError ? styles.hasError : undefined
    );
  }

  @cached
  get inputClass() {
    return euiClass(this.styles.context, hiddenInput);
  }

  setHasUnacceptedItems(value: boolean) {
    this.args.setHasUnacceptedItems?.(value);
  }

  /** dragenter/dragover: upstream's shared handler. */
  @action
  onDragOver(event: DragEvent) {
    if (this.isDisabled) return;

    // Allow dropping (react-dropzone always prevents the default here)
    event.preventDefault();

    let accepted: boolean;

    if (event.dataTransfer) {
      const unacceptedItems = getUnacceptedItems(
        event.dataTransfer.items,
        this.dropHandlers
      );

      this.setHasUnacceptedItems(unacceptedItems.length > 0);
      this.isDraggingError = unacceptedItems.length > 0;
      accepted = unacceptedItems.length === 0;
    } else {
      this.setHasUnacceptedItems(false);
      accepted = false;
    }

    this.isDragging = accepted;
  }

  @action
  onDragLeave(event: DragEvent) {
    if (this.isDisabled) return;

    const zone = event.currentTarget as HTMLElement;
    const next = event.relatedTarget as Node | null;

    // Moving between children of the zone is not leaving it
    if (next && zone.contains(next)) return;

    this.isDragging = false;
  }

  @action
  onDrop(event: DragEvent) {
    if (this.isDisabled) return;

    event.preventDefault();
    this.handleFiles(Array.from(event.dataTransfer?.files ?? []));
  }

  @action
  onInputChange(event: Event) {
    const input = event.target as HTMLInputElement;

    this.handleFiles(Array.from(input.files ?? []));
    input.value = '';
  }

  @action
  setFileInput(element: HTMLInputElement) {
    this.fileInput = element;
  }

  @action
  openFiles() {
    this.setHasUnacceptedItems(false);
    this.fileInput?.click();
  }

  footerFrame: number | null = null;

  /**
   * The textarea (a sibling of the footer) resizes in response, so report on
   * the next frame: resizing it inside this ResizeObserver delivery would
   * end the loop with undelivered notifications.
   */
  footerElement: HTMLElement | null = null;

  @action
  setFooterElement(element: HTMLElement) {
    this.footerElement = element;
  }

  @action
  onFooterResize({ height: rectHeight }: { height: number }) {
    // Layout height, not the (transform-scaled) bounding rect
    const height = this.footerElement?.offsetHeight ?? rectHeight;

    if (height === 0) return;

    if (this.footerFrame !== null) cancelAnimationFrame(this.footerFrame);

    this.footerFrame = requestAnimationFrame(() => {
      this.footerFrame = null;
      if (this.isDestroying || this.isDestroyed) return;
      run(() => this.args.setEditorFooterHeight?.(height));
    });
  }

  willDestroy() {
    super.willDestroy();
    if (this.footerFrame !== null) cancelAnimationFrame(this.footerFrame);
  }

  handleFiles(files: File[]) {
    const fileHandlers: EuiMarkdownDropHandler[] = [];

    // verify all files being dropped are supported
    for (const file of files) {
      const handler = this.dropHandlers.find((handler) =>
        handler.accepts(file.type)
      );

      if (!handler) {
        // if we get here then a file isn't handled
        this.setHasUnacceptedItems(true);
        this.isDragging = false;
        this.isDraggingError = false;

        return;
      }

      fileHandlers.push(handler);
    }

    this.isUploadingFiles = true;

    const resolved = files.map((file, i) =>
      Promise.resolve(fileHandlers[i]!.getFormattingForItem(file))
    );

    void Promise.all(resolved)
      .then((results) => {
        results.forEach(({ text, config }) =>
          this.args.insertText?.(text, config)
        );
      })
      .catch(() => {})
      .then(() => {
        if (this.isDestroying || this.isDestroyed) return;

        this.isDragging = false;
        this.isUploadingFiles = false;
        this.isDraggingError = false;
      });
  }

  <template>
    {{! Upstream unsets react-dropzone's role="button": files are added with
      the footer's upload button, so the zone is not interactive itself. }}
    <div
      class="euiMarkdownEditorDropZone {{this.classes}}"
      ...attributes
      {{on "dragenter" this.onDragOver}}
      {{on "dragover" this.onDragOver}}
      {{on "dragleave" this.onDragLeave}}
      {{on "drop" this.onDrop}}
    >
      {{yield}}
      {{#if this.showFooter}}
        <EuiMarkdownEditorFooter
          @uiPlugins={{@uiPlugins}}
          @errors={{@errors}}
          @dropHandlers={{this.dropHandlers}}
          @hasUnacceptedItems={{@hasUnacceptedItems}}
          @isUploadingFiles={{this.isUploadingFiles}}
          @openFiles={{this.openFiles}}
          @readOnly={{@readOnly}}
          {{didInsert this.setFooterElement}}
          {{resizeObserver "height" onResize=this.onFooterResize}}
        />
      {{/if}}
      <input
        class={{this.inputClass}}
        type="file"
        multiple
        tabindex="-1"
        autocomplete="off"
        disabled={{this.isDisabled}}
        {{didInsert this.setFileInput}}
        {{on "change" this.onInputChange}}
      />
    </div>
  </template>
}
