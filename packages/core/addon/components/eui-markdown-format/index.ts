//@ts-nocheck
import Component from '@glimmer/component';
import { EuiPopoverArgs } from '../eui-popover';
import type MarkdownActions from '../../utils/markdown/markdown-actions';
import {
  defaultParsingPlugins,
  defaultProcessingPlugins
} from '../../utils/markdown/plugins/markdown-default-plugins';
import { cached } from '@glimmer/tracking';
import unified from 'unified';
import { toDOM } from '../../utils/markdown/plugins/to-dom';

export interface EuiMarkdownEditorToolbarArgs
  extends Omit<EuiPopoverArgs, 'button' | 'buttonRef'> {
  disableFocusTrap?: boolean;
  fullWidth?: boolean;
  input: EuiPopoverArgs['button'];
  inputRef?: EuiPopoverArgs['buttonRef'];
  viewMode?: string;
  markdownActions: MarkdownActions;
}

export default class EuiMarkdownEditorToolbarComponent extends Component<EuiMarkdownEditorToolbarArgs> {
  get parsingPluginList() {
    return this.args.parsingPluginList || defaultParsingPlugins;
  }

  get processingPluginList() {
    return this.args.processingPluginList || defaultProcessingPlugins;
  }

  @cached
  get processor() {
    return unified().use(this.parsingPluginList).use(this.processingPluginList);
  }

  @cached
  get result() {
    try {
      const processed = this.processor.processSync(this.args.value);
      // `.result` is intentionally `unknown` (https://github.com/vfile/vfile/pull/53)
      // cast to something expected.
      const { element, components } = toDOM(processed.result);
      return {
        element,
        components
      };
      //eslint-disable-next-line
    } catch (e) {
      return this.args.value;
    }
  }
}
