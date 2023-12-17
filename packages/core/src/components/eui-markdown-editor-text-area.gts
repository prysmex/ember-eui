import { hash } from '@ember/helper';

import style from 'ember-style-modifier/modifiers/style';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiMarkdownEditorTextAreaSignature {
  Element: HTMLTextAreaElement;
  Args: {
    height?: string;
    maxHeight?: string;
  };
  Blocks: {
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