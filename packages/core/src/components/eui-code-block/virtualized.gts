import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { helper } from '@ember/component/helper';
import { concat } from '@ember/helper';

//@ts-expect-error
import { VerticalCollection } from '@html-next/vertical-collection';
import style from 'ember-style-modifier/modifiers/style';

import EuiRenderNode from '../../-private/eui-render-node.gts';
import randomId from '../../-private/random-id.ts';
import { getHtmlContent } from '../../utils/code/utils.ts';
import EuiAutoSizer from '../eui-auto-sizer.gts';
import Annotation from './annotation.gts';

import type { EuiRenderNode as EuiRenderNodeType } from '../../-private/eui-render-node.gts';

import type { RefractorNode } from 'refractor/core';

export interface VirtualizedCodeBlockSignature<T> {
  Element: HTMLPreElement;
  // We accept an array of items, one per row
  Args: {
    /** The highlighted lines to render. */
    data?: T[];
    /** Language of the code, for the `data-code-language` attribute. */
    language: string;
    /** Height of one line in px, from the font size. */
    rowHeight: number;
    /** Classes of the scrolling `<pre>` (upstream `euiCodeBlock__pre` styles). */
    preClass?: string;
    /** Classes of the `<code>` (upstream `euiCodeBlock__code` + `isVirtualized`). */
    codeClass?: string;
    /**
     * A number fixes the list height to that many px (upstream); otherwise
     * the list fills the code block's height.
     */
    overflowHeight?: number | string;
    /** Screen reader label rendered before the code. */
    label?: string;
    /** Classes of the screen reader label. */
    labelClass?: string;
    /**
     * Line annotations, keyed by line number, rendered into the rows'
     * annotation placeholders as rows scroll into view (upstream).
     */
    annotations?: Record<number, string | EuiRenderNodeType>;
  };
}

export default class EuiCodeBlockVirtualizedComponent<T> extends Component<
  VirtualizedCodeBlockSignature<T>
> {
  /**
   * A row's element, plus its annotation placeholder (and line number) when
   * the line is annotated, which the template renders the note into.
   */
  row = helper(function ([node, index, rowHeight]: [
    RefractorNode,
    number,
    number
  ]) {
    const content = getHtmlContent([node]);
    const span = content.element.firstChild as HTMLElement;
    const placeholder = span?.querySelector<HTMLElement>(
      '[data-annotation-line]'
    );

    if (span) {
      // react-window's row styles, logical (upstream `logicalStyles`)
      span.style.position = 'absolute';
      span.style.blockSize = `${rowHeight}px`;
      span.style.insetInlineStart = '0';
      span.style.inlineSize = '100%';
      span.style.insetBlockStart = `${index * rowHeight}px`;
    }

    return {
      element: span,
      placeholder,
      lineNumber: Number(placeholder?.dataset['annotationLine'])
    };
  });

  annotationFor = (lineNumber: number) =>
    this.args.annotations?.[lineNumber] ?? '';

  get hasFixedHeight() {
    return typeof this.args.overflowHeight === 'number';
  }

  @cached
  get fixedHeightStyle() {
    return this.hasFixedHeight
      ? { 'block-size': `${this.args.overflowHeight as number}px` }
      : {};
  }

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
    {{#let (randomId) as |theID|}}
      <EuiAutoSizer @disableHeight={{this.hasFixedHeight}} as |styles|>
        <pre
          class={{@preClass}}
          {{style styles}}
          {{style this.fixedHeightStyle}}
          {{!template-lint-disable}}
          style="position: relative;"
          id={{theID}}
          ...attributes
        >{{#if @label}}<div class={{@labelClass}}>{{@label}}</div>{{/if}}<VerticalCollection
            @items={{@data}}
            @tagName="code"
            class={{@codeClass}}
            data-code-language={{@language}}
            @estimateHeight={{@rowHeight}}
            @bufferSize={{40}}
            @staticHeight={{true}}
            @containerSelector={{concat "#" theID}}
            as |opt index|
          >{{#let (this.row opt index @rowHeight) as |row|}}{{row.element}}{{#if row.placeholder}}{{#in-element row.placeholder insertBefore=null}}<Annotation @lineNumber={{row.lineNumber}}><EuiRenderNode @value={{this.annotationFor row.lineNumber}} /></Annotation>{{/in-element}}{{/if}}{{/let}}</VerticalCollection></pre>
      </EuiAutoSizer>
    {{/let}}
  </template>
}
