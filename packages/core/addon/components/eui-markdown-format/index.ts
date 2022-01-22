import Component from '@glimmer/component';
import type MarkdownActions from '../../utils/markdown/markdown-actions';
import {
  defaultParsingPlugins,
  defaultProcessingPlugins
} from '../../utils/markdown/plugins/markdown-default-plugins';
import { cached } from '@glimmer/tracking';
import unified from 'unified';
import { toDOM } from '../../utils/markdown/plugins/to-dom';
import { RehypeNode } from '../../utils/markdown/markdown-types';

export interface EuiMarkdownEditorToolbarArgs {
  parsingPluginList?: typeof defaultParsingPlugins;
  processingPluginList?: typeof defaultProcessingPlugins;
  viewMode?: string;
  markdownActions: MarkdownActions;
  value: string;
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
      return toDOM(processed.result as RehypeNode);
      //eslint-disable-next-line
    } catch (e) {
      return this.args.value;
    }
  }
}
