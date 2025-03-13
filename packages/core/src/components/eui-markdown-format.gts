import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { isArray } from '@ember/array';
import { EnsureSafeComponentHelper } from '@embroider/util';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import unified from 'unified';

import { sizeMapping as textSizeMapping } from '../utils/css-mappings/eui-text.ts';
import {
  defaultParsingPlugins,
  defaultProcessingPlugins
} from '../utils/markdown/plugins/markdown-default-plugins/index.ts';
import { toDOM } from '../utils/markdown/plugins/to-dom.ts';

import type {
  EuiMarkdownAstNodePosition,
  RehypeNode
} from '../utils/markdown/markdown-types';
import type { EuiTextSignature } from './eui-text.gts';
import type { Processor } from 'unified';

export type Replacer = (
  position: EuiMarkdownAstNodePosition,
  str: string
) => void;

export interface EuiMarkdownFormatSignature {
  Args: {
    parsingPluginList?: typeof defaultParsingPlugins;
    processingPluginList?: typeof defaultProcessingPlugins;
    replaceNode?: Replacer;
    value: string;
    //you can pass in a string or an array of strings to be added to the root element
    rootClasses?: string | string[];
    textSize?: EuiTextSignature['Args']['size'];
    shouldIncludeDefaultRootClasses?: boolean;
  };
}

export default class EuiMarkdownEditorToolbarComponent extends Component<EuiMarkdownFormatSignature> {
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

  get shouldIncludeDefaultRootClasses() {
    return this.args.shouldIncludeDefaultRootClasses ?? true;
  }

  get rootClasses(): string[] {
    let baseClasses = ['euiMarkdownFormat'];

    if (this.shouldIncludeDefaultRootClasses) {
      baseClasses = baseClasses.concat(['euiText', this.textSizeClass]);
    }

    if (this.args.rootClasses) {
      let rootClasses = isArray(this.args.rootClasses)
        ? this.args.rootClasses
        : (this.args.rootClasses as string)?.trim()?.split(' ') || [];

      baseClasses = baseClasses.concat(rootClasses);
    }

    return baseClasses;
  }

  get textSize() {
    return this.args.textSize || 'm';
  }

  get textSizeClass() {
    return textSizeMapping[this.textSize];
  }

  @cached
  get result() {
    try {
      const processed = this.processor.processSync(this.args.value);

      return toDOM(processed['result'] as RehypeNode, {
        rootClasses: this.rootClasses
      });
      //eslint-disable-next-line
    } catch (e) {
      console.warn(e);
    }

    return null;
  }

  <template>
    {{! This hbs was inspired by https://github.com/ampatspell/ember-cli-remark-static/blob/v3.0.5/addon/components/remark.hbs }}
    {{#if this.result}}
      {{this.result.element}}
      {{#each this.result.components as |CompNode|}}
        {{#in-element CompNode.element}}
          {{#if CompNode.componentName}}
            {{#let
              (component (EnsureSafeComponentHelper CompNode.componentName))
              as |DynamicComponent|
            }}
              <DynamicComponent
                @replaceNode={{optional @replaceNode}}
                @node={{CompNode}}
              />
            {{/let}}
          {{/if}}
        {{/in-element}}
      {{/each}}
    {{/if}}
  </template>
}
