import { helper } from '@ember/component/helper';
import { RefractorNode } from 'refractor';
import Component from '@glimmer/component';
import { getHtmlContent } from '../../utils/code/utils';
import EuiAutoSizer from '../eui-auto-sizer';
import VerticalCollection from '@html-next/vertical-collection/components/vertical-collection';
import { guidFor } from '@ember/object/internals';
import style from 'ember-style-modifier/modifiers/style';
import { concat } from '@ember/helper';

export interface VirtualizedCodeBlockSignature<T> {
  // We have a `<table>` as our root element
  Element: HTMLTableElement;
  // We accept an array of items, one per row
  Args: {
    data: T[];
    language: string;
    rowHeight: number;
  };
}

export default class EuiCodeBlockVirtualizedComponent<T> extends Component<
  VirtualizedCodeBlockSignature<T>
> {
  getHtmlContent = helper(function ([node, index, rowHeight]: [
    RefractorNode,
    number,
    number
  ]) {
    const content = getHtmlContent([node]);
    const span = content.element.firstChild as HTMLElement;
    if (span) {
      span.style.position = 'absolute';
      span.style.height = `${rowHeight}px`;
      span.style.left = '0';
      span.style.top = `${index * rowHeight}px`;
    }
    return span;
  });

  <template>
    {{! DO NOT FORMAT AT ALL, PRE TAGS RESPECT WHITESPACE LITERALLY }}
    {{! DO NOT FORMAT AT ALL, PRE TAGS RESPECT WHITESPACE LITERALLY }}
    {{! DO NOT FORMAT AT ALL, PRE TAGS RESPECT WHITESPACE LITERALLY }}
    {{! DO NOT FORMAT AT ALL, PRE TAGS RESPECT WHITESPACE LITERALLY }}
    {{! DO NOT FORMAT AT ALL, PRE TAGS RESPECT WHITESPACE LITERALLY }}
    {{! DO NOT FORMAT AT ALL, PRE TAGS RESPECT WHITESPACE LITERALLY }}
    {{! DO NOT FORMAT AT ALL, PRE TAGS RESPECT WHITESPACE LITERALLY }}
    {{! DO NOT FORMAT AT ALL, PRE TAGS RESPECT WHITESPACE LITERALLY }}
    {{! DO NOT FORMAT AT ALL, PRE TAGS RESPECT WHITESPACE LITERALLY }}
    {{#let (guidFor) as |theID|}}
      <EuiAutoSizer as |styles|>
        <pre
          {{style styles}}
          {{!template-lint-disable}}
          style="position: relative; overflow: auto;"
          id={{theID}}
          ...attributes
        ><VerticalCollection
            @items={{@data}}
            @tagName="code"
            class="euiCodeBlock__code"
            data-code-language={{@language}}
            @estimateHeight={{@rowHeight}}
            @bufferSize={{40}}
            @staticHeight={{true}}
            @containerSelector={{concat "#" theID}}
            as |opt index|
          >{{this.getHtmlContent
              opt
              index
              @rowHeight
            }}</VerticalCollection></pre>
      </EuiAutoSizer>
    {{/let}}
  </template>
}
