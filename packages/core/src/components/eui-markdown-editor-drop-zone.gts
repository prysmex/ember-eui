import classNames from '../helpers/class-names.ts';
import EuiMarkdownEditorFooter from './eui-markdown-editor-footer.gts';

import type { EuiMarkdownEditorFooterSignature } from './eui-markdown-editor-footer';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private EuiMarkdownEditor's area accepting dropped or pasted files. */
export interface EuiMarkdownEditorDropZoneSignature {
  Element: HTMLDivElement;
  Args: {
    /** The editor's plugins, for the footer's help. */
    uiPlugins?: EuiMarkdownEditorFooterSignature['Args']['uiPlugins'];
    /** Shows the upload spinner. */
    isUploadingFiles?: boolean;
    /** Highlights dropped files no plugin accepts. */
    hasUnacceptedItems?: boolean;
    /** Errors to list in the footer. */
    errors?: EuiMarkdownEditorFooterSignature['Args']['errors'];
  };
  Blocks: {
    /** The textarea or preview. */
    default: [];
  };
}

const EuiMarkdownEditorDropZone: TemplateOnlyComponent<EuiMarkdownEditorDropZoneSignature> =
  <template>
    <div
      class={{classNames
        "euiMarkdownEditorDropZone"
        (if false "euiMarkdownEditorDropZone--isDragging")
        (if @hasUnacceptedItems "euiMarkdownEditorDropZone--hasError")
        (if false "euiMarkdownEditorDropZone--isDraggingError")
      }}
      ...attributes
    >
      {{yield}}
      <EuiMarkdownEditorFooter @uiPlugins={{@uiPlugins}} @errors={{@errors}} />
    </div>
  </template>;

export default EuiMarkdownEditorDropZone;
