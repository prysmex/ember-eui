import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { helper } from '@ember/component/helper';
import { hash } from '@ember/helper';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { scheduleOnce } from '@ember/runloop';
import type Owner from '@ember/owner';

import onKey from 'ember-keyboard/modifiers/on-key';
import { modifier } from 'ember-modifier';
import set from 'ember-set-helper/helpers/set';
import style from 'ember-style-modifier/modifiers/style';
import { and, eq, not,or } from 'ember-truth-helpers';

import Controls from '../components/eui-code-block/controls.gts';
import FullScreenDisplay from '../components/eui-code-block/full-screen-display.gts';
import VirtualizedCodeBlock from '../components/eui-code-block/virtualized.gts';
import EuiInnerText from '../components/eui-inner-text.gts';
import classNames from '../helpers/class-names.ts';
import mutationObserver from '../modifiers/mutation-observer.ts';
import resizeObserver from '../modifiers/resize-observer.ts';
import {
  checkSupportedLanguage,
  getHtmlContent,
  highlightByLine
} from '../utils/code/utils.ts';

import type { EuiCodeSharedProps } from '../utils/code/utils.ts';
import type { RefractorNode } from 'refractor';

interface LineNumbersConfig {
  start?: number;
  highlight?: string;
  show?: boolean;
}

export type PaddingSize = 'none' | 's' | 'm' | 'l';
export type FontSize = 's' | 'm' | 'l';

const fontSizeToRowHeightMap = {
  s: 18,
  m: 21,
  l: 24
};

export type EuiCodeBlockArgs = EuiCodeSharedProps & {
  paddingSize?: PaddingSize;
  fontSize?: FontSize;

  /**
   * Specify how `white-space` inside the element is handled.
   * `pre` respects line breaks/white space but doesn't force them to wrap the line
   * `pre-wrap` respects line breaks/white space but does force them to wrap the line when necessary.
   */
  whiteSpace?: 'pre' | 'pre-wrap';

  /**
   * Displays an icon button to copy the code snippet to the clipboard.
   */
  isCopyable?: boolean;

  /**
   * Displays line numbers.
   * Optionally accepts a configuration object for setting the starting number and visual highlighting ranges:
   * `{ start: 100, highlight: '1, 5-10, 20-30, 40' }`
   */
  lineNumbers?: boolean | LineNumbersConfig;

  /**
   * Sets the maximum container height.
   * Accepts a pixel value (`300`) or a percentage (`'100%'`)
   * Ensure the container has calcuable height when using a percentage
   */
  overflowHeight?: number | string;

  /**
   * Renders code block lines virtually.
   * Useful for improving load times of large code blocks.
   *
   * When using this configuration, `overflowHeight` is required and
   * `whiteSpace` can only be `pre`.
   */
  isVirtualized?: boolean;
};

export interface EuiCodeBlockSignature {
  Element: HTMLElement;
  Args: EuiCodeBlockArgs;
  Blocks: {
    default: [];
  };
}

interface LineNumbersFinal {
  start: number;
  show: boolean;
  highlight?: string;
}

const highlightTargetModifier = modifier(
  (
    _e,
    _pos: unknown[],
    {
      element: targetEle,
      language = 'text',
      lineNumbersConfig = { start: 1, show: false },
      onChange
    }: {
      element: Element | undefined;
      language: EuiCodeSharedProps['language'];
      lineNumbersConfig: LineNumbersFinal;
      onChange: ({
        data,
        element
      }: {
        data: RefractorNode[];
        element: HTMLElement;
      }) => void;
    }
  ) => {
    let observer: undefined | MutationObserver;

    const getHighlighedHtml = () => {
      const html = (targetEle?.textContent ? targetEle.textContent : '').trim();

      let data: RefractorNode[];

      if (typeof html !== 'string') {
        data = [];
      } else {
        data = highlightByLine(html, language, lineNumbersConfig);
      }

      return {
        data,
        element: getHtmlContent(data).element
      };
    };

    const setupObserver = () => {
      const newObserver = new MutationObserver((mutationsList) => {
        if (mutationsList.length) {
          onChange(getHighlighedHtml());
        }
      });

      if (targetEle) {
        onChange(getHighlighedHtml());
        newObserver.observe(targetEle, {
          characterData: true,
          subtree: true,
          childList: true
        });
      }

      return newObserver;
    };

    if (targetEle) {
      observer = setupObserver();
    }

    return () => {
      observer?.disconnect();
    };
  }
);

const cleanTextHelper = helper(function ([text]: [string]) {
  return text?.replace(/[\r\n?]{2}|\n\n/g, '\n') || '';
});

const textToCopyHelper = helper(function (
  _pos,
  {
    isVirtualized,
    element,
    innerText
  }: {
    isVirtualized: boolean;
    element: HTMLElement | undefined;
    innerText: string;
  }
) {
  if (element) {
    return isVirtualized
      ? element.textContent
        ? element.textContent
        : ''
      : innerText;
  }

  return '';
});

export default class EuiCodeBlockComponent extends Component<EuiCodeBlockSignature> {
  //fake element where yield writes to, so we can observe and clone a highlighted version to code and codeFullSceen
  @tracked codeTarget?: HTMLElement;
  //<code> Element for non fullscreen
  @tracked code?: HTMLElement;
  //<code> Element for fullscreen modal
  @tracked codeFullScreen?: HTMLElement;
  @tracked wrapperRef?: HTMLElement;
  @tracked tabIndex = 1;
  @tracked isFullScreen = false;
  @tracked data?: { data: RefractorNode[]; element: HTMLElement };

  get language() {
    return checkSupportedLanguage(this.args.language || '');
  }

  get transparentBackground() {
    return this.args.transparentBackground ?? false;
  }

  get paddingSize() {
    return this.args.paddingSize ?? 'l';
  }

  get fontSize() {
    return this.args.fontSize ?? 's';
  }

  get isCopyable() {
    return this.args.isCopyable ?? false;
  }

  get whiteSpace() {
    return this.args.whiteSpace ?? 'pre-wrap';
  }

  get isVirtualized() {
    return !!(this.args.isVirtualized && Array.isArray(this.data?.data));
  }

  get lineNumbers() {
    return this.args.lineNumbers ?? false;
  }

  get lineNumbersConfig() {
    const { lineNumbers } = this;
    const config = typeof lineNumbers === 'object' ? lineNumbers : {};

    return lineNumbers
      ? { start: 1, show: true, ...config }
      : { start: 1, show: false };
  }

  get optionalStyles() {
    const overflowHeight = this.args.overflowHeight;

    if (overflowHeight) {
      const property =
        typeof overflowHeight === 'string' ? 'height' : 'maxHeight';

      return {
        [property]:
          typeof overflowHeight === 'string'
            ? overflowHeight
            : `${overflowHeight}px`
      };
    }

    return {};
  }

  get showCopyButton() {
    return this.isCopyable && true;
  }

  get rowHeight() {
    return fontSizeToRowHeightMap[this.fontSize];
  }

  get showFullScreenButton() {
    return !!this.args.overflowHeight;
  }

  constructor(owner: Owner, args: EuiCodeBlockArgs) {
    super(owner, args);
    this.codeTarget = document.createElement('div');
  }

  @action
  toggleFullScreen() {
    this.isFullScreen = !this.isFullScreen;
  }

  @action
  closeFullScreen(e: KeyboardEvent) {
    e.preventDefault();
    e.stopPropagation();
    this.isFullScreen = false;
  }

  @action
  doesOverflow() {
    if (!this.wrapperRef) return;

    const { clientWidth, clientHeight, scrollWidth, scrollHeight } =
      this.wrapperRef;
    const doesOverflow =
      scrollHeight > clientHeight || scrollWidth > clientWidth;

    this.tabIndex = doesOverflow ? 0 : -1;
  }

  @action
  updateCode(resp: { data: RefractorNode[]; element: HTMLElement }) {
    const render = () => {
      const code = this.code;
      const codeFullScreen = this.codeFullScreen;

      if (code && !this.isFullScreen) {
        this.data = resp;
        code.innerHTML = resp.element.innerHTML;
      }

      if (codeFullScreen && this.isFullScreen) {
        this.data = resp;
        codeFullScreen.innerHTML = resp.element.innerHTML;
      }
    };

    scheduleOnce('afterRender', this, render);
  }

  willDestroy() {
    super.willDestroy();

    this.codeTarget = undefined;
    this.code = undefined;
    this.codeFullScreen = undefined;
    this.wrapperRef = undefined;
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
    {{#if this.codeTarget}}
      {{#in-element this.codeTarget}}
        {{yield}}
      {{/in-element}}
    {{/if}}
    <EuiInnerText as |setInnerTextRef innerText|>
      {{#let
        (classNames
          "euiCodeBlock"
          (if
            (or this.showCopyButton this.showFullScreenButton)
            "euiCodeBlock--hasControl"
          )
          (if
            (and this.showCopyButton this.showFullScreenButton)
            "euiCodeBlock--hasBothControls"
          )
          (if this.lineNumbersConfig.show "euiCodeBlock--hasLineNumbers")
          @className
        )
        (classNames
          "euiCodeBlock__pre"
          (if
            (or (eq this.whiteSpace "pre") this.isVirtualized)
            "euiCodeBlock__pre--whiteSpacePre"
          )
          (if
            (and (eq this.whiteSpace "pre-wrap") (not this.isVirtualized))
            "euiCodeBlock__pre--whiteSpacePreWrap"
          )
          (if this.isVirtualized "euiCodeBlock__pre--isVirtualized")
        )
        as |wrapperClasses preClasses|
      }}
        <div
          class={{classNames
            wrapperClasses
            (if
              this.transparentBackground "euiCodeBlock--transparentBackground"
            )
            componentName="EuiCodeBlock"
            fontSize=this.fontSize
            paddingSize=this.paddingSize
          }}
          {{style this.optionalStyles}}
          {{highlightTargetModifier
            element=this.codeTarget
            language=this.language
            lineNumbersConfig=this.lineNumbersConfig
            onChange=this.updateCode
          }}
        >
          {{#if this.isVirtualized}}
            {{!virtualized}}
            <VirtualizedCodeBlock
              class={{preClasses}}
              tabindex="0"
              {{onKey "Escape" this.closeFullScreen}}
              @language={{this.language}}
              @data={{this.data.data}}
              @rowHeight={{this.rowHeight}}
            />
          {{else}}
            {{!template-lint-disable}}
            <pre
              class={{preClasses}}
              {{style this.optionalStyles}}
              tabindex={{this.tabIndex}}
              {{didInsert (set this "wrapperRef")}}
              {{resizeObserver onResize=this.doesOverflow}}
              {{mutationObserver
                onMutation=this.doesOverflow
                observerOptions=(hash subtree=true childList=true)
              }}
              {{didInsert setInnerTextRef}}
            ><code
                class="euiCodeBlock__code"
                data-code-language={{this.language}}
                {{didInsert (set this "code")}}
                ...attributes
              ></code></pre>

          {{/if}}

          <Controls
            @isFullScreen={{this.isFullScreen}}
            @showFullScreenButton={{this.showFullScreenButton}}
            @toggleFullScreen={{this.toggleFullScreen}}
            @showCopyButton={{this.showCopyButton}}
            @textToCopy={{textToCopyHelper
              isVirtualized=this.isVirtualized
              innerText=(cleanTextHelper innerText)
              element=this.data.element
            }}
          />

          {{#if this.isFullScreen}}
            <FullScreenDisplay class={{wrapperClasses}}>
              {{#if this.isVirtualized}}
                <VirtualizedCodeBlock
                  class={{preClasses}}
                  tabindex="0"
                  {{onKey "Escape" this.closeFullScreen}}
                  @language={{this.language}}
                  @data={{this.data.data}}
                  @rowHeight={{fontSizeToRowHeightMap.l}}
                />
              {{else}}
                <pre
                  class={{preClasses}}
                  tabindex="0"
                  {{onKey "Escape" this.closeFullScreen}}
                ><code
                    class="euiCodeBlock__code"
                    data-code-language={{this.language}}
                    {{didInsert (set this "codeFullScreen")}}
                  ></code></pre>
              {{/if}}
              <Controls
                @isFullScreen={{this.isFullScreen}}
                @showFullScreenButton={{this.showFullScreenButton}}
                @showCopyButton={{this.showCopyButton}}
                @toggleFullScreen={{this.toggleFullScreen}}
                @textToCopy={{textToCopyHelper
                  isVirtualized=this.isVirtualized
                  innerText=(cleanTextHelper innerText)
                  element=this.data.element
                }}
              />
            </FullScreenDisplay>
          {{/if}}
        </div>
      {{/let}}
    </EuiInnerText>
  </template>
}
