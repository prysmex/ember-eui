import classNames from '../helpers/class-names';
import EuiMarkdownEditorFooter from './eui-markdown-editor-footer.gts';
import type { EuiMarkdownEditorFooterSignature } from './eui-markdown-editor-footer.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiMarkdownEditorDropZoneSignature {
  Element: HTMLDivElement;
  Args: {
    uiPlugins?: EuiMarkdownEditorFooterSignature['Args']['uiPlugins'];
    isUploadingFiles?: boolean;
    hasUnacceptedItems?: boolean;
    errors?: EuiMarkdownEditorFooterSignature['Args']['errors'];
  };
  Blocks: {
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
