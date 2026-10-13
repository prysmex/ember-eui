import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { hash } from '@ember/helper';

import style from 'ember-style-modifier/modifiers/style';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiMarkdownEditorTextAreaStyles } from '../utils/eui/styles.generated.ts';

import type { CSSObject } from '@emotion/css/create-instance';

/** Stands in for React EUI's global `box-sizing` reset. */
const textAreaReset: CSSObject = { boxSizing: 'border-box' };

/** @private EuiMarkdownEditor's textarea. */
export interface EuiMarkdownEditorTextAreaSignature {
  Element: HTMLTextAreaElement;
  Args: {
    /** CSS height of the textarea. Empty strings are ignored. */
    height?: string;
    /** CSS max height of the textarea. Empty strings are ignored. */
    maxHeight?: string;
    /** Read-only: no focus ring, plain background (upstream `readOnly`). */
    readOnly?: boolean;
  };
  Blocks: {
    /** Unused. */
    default: [];
  };
}

export default class EuiMarkdownEditorTextArea extends Component<EuiMarkdownEditorTextAreaSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(
      context,
      euiMarkdownEditorTextAreaStyles
    );

    return euiClass(
      context,
      textAreaReset,
      styles.euiMarkdownEditorTextArea,
      this.args.readOnly ? styles.readOnly : styles.editable
    );
  }

  // '' removes the inline value (upstream ignores empty strings)
  get height() {
    return this.args.height ?? '';
  }

  get maxHeight() {
    return this.args.maxHeight ?? '';
  }

  <template>
    <textarea
      class="euiMarkdownEditorTextArea
        {{if @readOnly 'euiMarkdownEditorTextArea-isReadOnly'}}
        {{this.classes}}"
      data-test-subj="euiMarkdownEditorTextArea"
      rows="6"
      readonly={{@readOnly}}
      ...attributes
      {{style (hash height=this.height maxHeight=this.maxHeight)}}
    >
      {{yield}}
    </textarea>
  </template>
}
