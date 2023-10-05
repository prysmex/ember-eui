import Component from '@glimmer/component';
import {
  defaultParsingPlugins,
  defaultProcessingPlugins
} from '../../utils/markdown/plugins/markdown-default-plugins';
import { cached } from '@glimmer/tracking';
import unified, { Processor } from 'unified';
import { toDOM } from '../../utils/markdown/plugins/to-dom';
import type { RehypeNode } from '../../utils/markdown/markdown-types';
import type EuiMarkdownEditorComponent from '../eui-markdown-editor';
export interface EuiMarkdownEditorToolbarArgs {
  parsingPluginList?: typeof defaultParsingPlugins;
  processingPluginList?: typeof defaultProcessingPlugins;
  replaceNode?: EuiMarkdownEditorComponent['replaceNode'];
  value: string;
  //you can pass in a string or an array of strings to be added to the root element
  rootClasses?: string | string[];
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
    const Compiler = (tree: any) => {
      return tree;
    };

    function identityCompiler(this: Processor) {
      //eslint-disable-next-line
      this.Compiler = Compiler;
    }
    return unified()
      .use(this.parsingPluginList)
      .use(this.processingPluginList)
      .use(identityCompiler);
  }

  get rootClasses(): string[] {
    let baseClasses = ['euiMarkdownFormat', 'euiText', 'euiText--medium'];
    if (this.args.rootClasses) {
      baseClasses = baseClasses.concat(this.args.rootClasses);
    }
    return baseClasses;
  }

  @cached
  get result() {
    try {
      const processed = this.processor.processSync(this.args.value);
      return toDOM(processed.result as RehypeNode, {
        rootClasses: this.rootClasses
      });
      //eslint-disable-next-line
    } catch (e) {
      return this.args.value;
    }
  }
}
