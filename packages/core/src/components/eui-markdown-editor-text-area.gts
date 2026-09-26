import { hash } from '@ember/helper';

import style from 'ember-style-modifier/modifiers/style';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private EuiMarkdownEditor's textarea. */
export interface EuiMarkdownEditorTextAreaSignature {
  Element: HTMLTextAreaElement;
  Args: {
    /** CSS height of the textarea. */
    height?: string;
    /** CSS max height of the textarea. */
    maxHeight?: string;
  };
  Blocks: {
    /** Unused. */
    default: [];
  };
}

const EuiMarkdownEditorTextArea: TemplateOnlyComponent<EuiMarkdownEditorTextAreaSignature> =
  <template>
    <textarea
      class="euiMarkdownEditorTextArea"
      rows="6"
      ...attributes
      {{style (hash height=@height maxHeight=@maxHeight)}}
    >
      {{yield}}
    </textarea>
  </template>;

export default EuiMarkdownEditorTextArea;