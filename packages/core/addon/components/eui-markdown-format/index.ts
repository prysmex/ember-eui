import Component from '@glimmer/component';
import {
  defaultParsingPlugins,
  defaultProcessingPlugins
} from '../../utils/markdown/plugins/markdown-default-plugins';
import { cached, tracked } from '@glimmer/tracking';
import unified, { Processor } from 'unified';
import { DynamicComponent, toDOM } from '../../utils/markdown/plugins/to-dom';
import type { RehypeNode } from '../../utils/markdown/markdown-types';
import type EuiMarkdownEditorComponent from '../eui-markdown-editor';

export interface EuiMarkdownEditorToolbarArgs {
  parsingPluginList?: typeof defaultParsingPlugins;
  processingPluginList?: typeof defaultProcessingPlugins;
  replaceNode?: EuiMarkdownEditorComponent['replaceNode'];
  value: string;
}

export default class EuiMarkdownEditorToolbarComponent extends Component<EuiMarkdownEditorToolbarArgs> {
  @tracked rootNode?: HTMLDivElement;
  @tracked result?:
    | {
        element: Node | undefined;
        components: DynamicComponent[];
      }
    | string;

  _lastValue?: string;

  get parsingPluginList() {
    return this.args.parsingPluginList || defaultParsingPlugins;
  }

  get processingPluginList() {
    return this.args.processingPluginList || defaultProcessingPlugins;
  }

  setRootNode = (node: HTMLDivElement) => {
    this.rootNode = node;
    this.update();
  };

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

  update = () => {
    if (this.rootNode) {
      if (this.args.value === this._lastValue) return;
      this._lastValue = this.args.value;
      this.rootNode.innerHTML = '';
      try {
        const processed = this.processor.processSync(this.args.value);
        this.result = toDOM(processed.result as RehypeNode, this.rootNode);
        //eslint-disable-next-line
      } catch (e) {
        this.result = this.args.value;
      }
    }
    this.result = this.args.value;
  };
}
