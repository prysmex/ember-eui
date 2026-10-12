import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { later, scheduleOnce } from '@ember/runloop';
import { service } from '@ember/service';
import type Owner from '@ember/owner';

import { modifier } from 'ember-modifier';
import style from 'ember-style-modifier/modifiers/style';

import { highlightLanguage } from '../-private/language-loader.ts';
import Annotation from '../components/eui-code-block/annotation.gts';
import Controls from '../components/eui-code-block/controls.gts';
import FullScreenDisplay from '../components/eui-code-block/full-screen-display.gts';
import VirtualizedCodeBlock from '../components/eui-code-block/virtualized.gts';
import mutationObserver from '../modifiers/mutation-observer.ts';
import resizeObserver from '../modifiers/resize-observer.ts';
import {
  checkSupportedLanguage,
  getHtmlContent,
  highlightByLine
} from '../utils/code/utils.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiCodeBlockLineStyles } from '../utils/eui/code-block.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiCodeBlockCodeStyles,
  euiCodeBlockPreStyles,
  euiCodeBlockStyles
} from '../utils/eui/styles.generated.ts';
import { euiScreenReaderOnlyClass } from './eui-screen-reader-only.gts';

import type EuiI18n from '../services/eui-i18n.ts';
import type {
  EuiCodeSharedProps,
  LineClasses,
  LineNumbersConfig as LineNumbersFinal
} from '../utils/code/utils.ts';
import type { RefractorNode } from 'refractor/core';

interface LineNumbersConfig {
  /** First line number. Defaults to `1`. */
  start?: number;
  /** Lines to highlight, e.g. `'1, 5-10, 20-30, 40'`. */
  highlight?: string;
  /**
   * Notes shown in a popover from a button next to a line number, keyed
   * by line number: `{ 6: 'A special note about this line' }`. Not shown
   * when `@isVirtualized`.
   */
  annotations?: Record<number, string>;
  show?: boolean;
}

export type PaddingSize = 'none' | 's' | 'm' | 'l';
export type FontSize = 's' | 'm' | 'l';

// Based on observed line height for non-virtualized code blocks (upstream)
const fontSizeToRowHeightMap = {
  s: 18,
  m: 21,
  l: 24
};

export type EuiCodeBlockArgs = EuiCodeSharedProps & {
  /** Padding around the code: `'none'`, `'s'`, `'m'` or `'l'`. Defaults to `'l'`. */
  paddingSize?: PaddingSize;
  /** `'s'`, `'m'` or `'l'`. Defaults to `'s'`. */
  fontSize?: FontSize;

  /**
   * Specify how `white-space` inside the element is handled.
   * `pre` respects line breaks/white space but doesn't force them to wrap the line
   * `pre-wrap` respects line breaks/white space but does force them to wrap the line when necessary.
   * Defaults to `'pre-wrap'`.
   */
  whiteSpace?: 'pre' | 'pre-wrap';

  /**
   * Displays an icon button to copy the code snippet to the clipboard
   * (only when there is code to copy).
   */
  isCopyable?: boolean;

  /** `aria-label` of the copy button. Defaults to `'Copy'`. */
  copyAriaLabel?: string;

  /**
   * Prefixes the code block's screen reader label
   * (`"<ariaLabel>, <language> code block:"`).
   */
  ariaLabel?: string;

  /**
   * Displays line numbers.
   * Optionally accepts a configuration object for setting the starting number,
   * visually highlighting ranges, or annotating specific lines:
   * `{ start: 100, highlight: '1, 5-10, 20-30, 40', annotations: { 6: 'A special note about this line' } }`
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

/**
 * Multi-line code with syntax highlighting, optional copy button, line
 * numbers and full screen view:
 * `<EuiCodeBlock @language="js" @isCopyable={{true}}>{{this.code}}</EuiCodeBlock>`.
 * `...attributes` go on the `<code>` element.
 */
export interface EuiCodeBlockSignature {
  Element: HTMLElement;
  Args: EuiCodeBlockArgs;
  Blocks: {
    /** The code, as text (e.g. a string from your component). */
    default: [];
  };
}

type HighlightResult = { data: RefractorNode[]; element: HTMLElement; text: string };

const highlightTargetModifier = modifier(
  (
    _e,
    _pos: unknown[],
    {
      element: targetEle,
      language = 'text',
      lineNumbersConfig = { start: 1, show: false },
      lineClasses,
      onChange
    }: {
      element: Element | undefined;
      language: EuiCodeSharedProps['language'];
      lineNumbersConfig: LineNumbersFinal;
      lineClasses: LineClasses;
      onChange: (result: HighlightResult) => void;
    }
  ) => {
    const getHighlighted = (): HighlightResult => {
      const text = (targetEle?.textContent ? targetEle.textContent : '').trim();
      const data = highlightByLine(
        text,
        language,
        lineNumbersConfig,
        lineClasses
      );

      return { data, element: getHtmlContent(data).element, text };
    };

    const observer = new MutationObserver((mutationsList) => {
      if (mutationsList.length) onChange(getHighlighted());
    });

    if (targetEle) {
      onChange(getHighlighted());
      observer.observe(targetEle, {
        characterData: true,
        subtree: true,
        childList: true
      });
    }

    return () => observer.disconnect();
  }
);

interface AnnotationTarget {
  element: HTMLElement;
  lineNumber: number;
  content: string;
}

type PaddingKey = 'none' | 's' | 'm' | 'l' | 'xl';

/**
 * Scoped stand-in for upstream's global reset (`pre { margin: 0 }`),
 * composed first so upstream's `controlsOffset` margin still wins.
 */
const PRE_RESET = { margin: 0 };

/** The highlighted HTML last written into each <code> element. */
const renderedHtml = new WeakMap<HTMLElement, string>();

/** Upstream EUI 123 / Borealis code block. */
export default class EuiCodeBlockComponent extends Component<EuiCodeBlockSignature> {
  @service declare euiI18n: EuiI18n;

  // Detached element the block yields into; its text is highlighted and
  // rendered into the visible (and full screen) <code>.
  @tracked codeTarget?: HTMLElement;
  // <code> element of the inline view
  @tracked code?: HTMLElement;
  // <code> element of the full screen view
  @tracked codeFullScreen?: HTMLElement;
  @tracked wrapperRef?: HTMLElement;
  rootElement?: HTMLElement;
  @tracked tabIndex = -1;
  @tracked isFullScreen = false;
  @tracked data?: HighlightResult;
  @tracked annotationTargets: AnnotationTarget[] = [];

  constructor(owner: Owner, args: EuiCodeBlockArgs) {
    super(owner, args);
    this.codeTarget = document.createElement('div');
  }

  get context() {
    return getEuiThemeContext(this);
  }

  get language() {
    return checkSupportedLanguage(this.args.language || '');
  }

  /** Plain text until the language has loaded. */
  get highlightLanguage() {
    return highlightLanguage(this.language);
  }

  get paddingSize(): PaddingSize {
    return this.args.paddingSize ?? 'l';
  }

  get fontSize(): FontSize {
    return this.args.fontSize ?? 's';
  }

  get whiteSpace() {
    return this.args.whiteSpace ?? 'pre-wrap';
  }

  get isVirtualized() {
    return !!(this.args.isVirtualized && Array.isArray(this.data?.data));
  }

  @cached
  get lineNumbersConfig(): LineNumbersFinal {
    const lineNumbers = this.args.lineNumbers ?? false;
    const config = typeof lineNumbers === 'object' ? lineNumbers : {};
    const final: LineNumbersFinal = lineNumbers
      ? { start: 1, show: true, ...config }
      : { start: 1, show: false };

    // annotations render Ember components into the lines; the virtualized
    // list builds its rows from detached nodes, so they are not supported there
    if (this.args.isVirtualized) delete final.annotations;

    return final;
  }

  /** Upstream's `{language} code block:` screen reader label. */
  get label() {
    const label = this.euiI18n.lookupToken(
      'euiCodeBlock.label',
      ({ language }) => `${language as string} code block:`,
      { language: this.language }
    );

    return this.args.ariaLabel ? `${this.args.ariaLabel}, ${label}` : label;
  }

  get textToCopy() {
    // The source text, as upstream copies for virtualized blocks (the
    // rendered `innerText` would lose blank lines).
    return this.data?.text ?? '';
  }

  get showCopyButton() {
    return !!(this.args.isCopyable && this.textToCopy);
  }

  get showFullScreenButton() {
    return !!this.args.overflowHeight;
  }

  get hasControls() {
    return this.showCopyButton || this.showFullScreenButton;
  }

  get rowHeight() {
    return fontSizeToRowHeightMap[this.fontSize] ?? fontSizeToRowHeightMap.s;
  }

  get fullScreenRowHeight() {
    return fontSizeToRowHeightMap.l;
  }

  @cached
  get overflowHeightStyles() {
    const overflowHeight = this.args.overflowHeight;

    if (!overflowHeight) return {};

    return typeof overflowHeight === 'string'
      ? { 'block-size': overflowHeight }
      : { 'max-block-size': `${overflowHeight}px` };
  }

  @cached
  get classes() {
    const { context, paddingSize } = this;
    const styles = useEuiBorealisStyles(context, euiCodeBlockStyles);
    const controls = this.hasControls
      ? this.showCopyButton && this.showFullScreenButton
        ? styles.hasBothControls[paddingSize]
        : styles.hasControls[paddingSize]
      : undefined;

    return [
      'euiCodeBlock',
      euiClass(
        context,
        styles.euiCodeBlock,
        styles[this.fontSize] ?? styles.s,
        this.args.transparentBackground
          ? styles.transparentBackground
          : undefined,
        controls
      ),
      this.args.className
    ]
      .filter(Boolean)
      .join(' ');
  }

  preClassFor(paddingSize: PaddingKey) {
    const { context } = this;
    const styles = useEuiBorealisStyles(context, euiCodeBlockPreStyles);
    const isWhiteSpacePre = this.whiteSpace === 'pre' || this.isVirtualized;
    const whiteSpace = isWhiteSpacePre
      ? styles.whiteSpace.pre
      : styles.whiteSpace.preWrap;

    return `euiCodeBlock__pre ${euiClass(
      context,
      PRE_RESET,
      styles.euiCodeBlock__pre,
      isWhiteSpacePre ? styles.whiteSpace.pre.pre : styles.whiteSpace.preWrap.preWrap,
      styles.padding[paddingSize],
      this.hasControls ? whiteSpace.controlsOffset[paddingSize] : undefined
    )}`;
  }

  @cached
  get preClasses() {
    return this.preClassFor(this.paddingSize);
  }

  /** Full screen always uses xl padding (upstream). */
  @cached
  get preFullScreenClasses() {
    return this.preClassFor('xl');
  }

  @cached
  get codeClasses() {
    const { context } = this;
    const styles = useEuiBorealisStyles(context, euiCodeBlockCodeStyles);
    return `euiCodeBlock__code ${euiClass(
      context,
      styles.euiCodeBlock__code,
      this.isVirtualized ? styles.isVirtualized : undefined
    )}`;
  }

  @cached
  get labelClasses() {
    return euiScreenReaderOnlyClass(this.context);
  }

  /** Line node classes, registered in the nearest provider's cache. */
  @cached
  get lineClasses(): LineClasses {
    const { context } = this;
    const styles = useEuiBorealisStyles(context, euiCodeBlockLineStyles);
    return {
      line: euiClass(context, styles.euiCodeBlock__line),
      lineWithNumbers: euiClass(
        context,
        styles.euiCodeBlock__line,
        styles.hasLineNumbers
      ),
      lineText: euiClass(context, styles.lineText.euiCodeBlock__lineText),
      lineTextHighlighted: euiClass(
        context,
        styles.lineText.euiCodeBlock__lineText,
        styles.lineText.isHighlighted
      ),
      lineNumberWrapper: euiClass(
        context,
        styles.lineNumber.euiCodeBlock__lineNumberWrapper
      ),
      lineNumber: euiClass(context, styles.lineNumber.euiCodeBlock__lineNumber)
    };
  }

  @action
  setRoot(element: HTMLElement) {
    this.rootElement = element;
  }

  @action
  setWrapperRef(element: HTMLElement) {
    this.wrapperRef = element;
    scheduleOnce('afterRender', this, this.doesOverflow);
  }

  @action
  setCode(element: HTMLElement) {
    this.code = element;
    scheduleOnce('afterRender', this, this.renderCode);
  }

  @action
  setCodeFullScreen(element: HTMLElement) {
    this.codeFullScreen = element;
    scheduleOnce('afterRender', this, this.renderCode);
  }

  returnFocus() {
    // after the full screen view (and its focus trap) is gone, as upstream
    later(
      this,
      () => {
        if (this.isDestroying || this.isDestroyed) return;
        this.rootElement
          ?.querySelector<HTMLElement>('.euiCodeBlock__fullScreenButton')
          ?.focus();
      },
      0
    );
  }

  @action
  toggleFullScreen() {
    const wasFullScreen = this.isFullScreen;

    this.isFullScreen = !wasFullScreen;
    if (wasFullScreen) this.returnFocus();
  }

  @action
  onFullScreenKeyDown(event: KeyboardEvent) {
    if (event.key !== 'Escape') return;

    // Escape in an annotation popover only closes the popover
    const focus = document.activeElement as HTMLElement | null;
    const inPopover =
      !!focus?.dataset['popoverOpen'] || !!focus?.closest('[data-popover-open]');

    if (inPopover) return;

    event.preventDefault();
    event.stopPropagation();
    this.isFullScreen = false;
    this.returnFocus();
  }

  @action
  doesOverflow() {
    if (!this.wrapperRef || this.isDestroying || this.isDestroyed) return;

    const { clientWidth, clientHeight, scrollWidth, scrollHeight } =
      this.wrapperRef;
    const doesOverflow =
      scrollHeight > clientHeight || scrollWidth > clientWidth;

    this.tabIndex = doesOverflow ? 0 : -1;
  }

  /** Copies the highlighted HTML into the rendered <code> elements. */
  renderCode() {
    const html = this.data?.element.innerHTML;

    if (html === undefined || this.isDestroying || this.isDestroyed) return;

    const targets: AnnotationTarget[] = [];
    const annotations = this.lineNumbersConfig.annotations ?? {};

    for (const code of [this.code, this.codeFullScreen]) {
      if (!code?.isConnected) continue;
      // rewriting unchanged code would drop rendered annotations
      if (renderedHtml.get(code) !== html) {
        code.innerHTML = html;
        renderedHtml.set(code, html);
      }

      code
        .querySelectorAll<HTMLElement>('[data-annotation-line]')
        .forEach((element) => {
          const lineNumber = Number(element.dataset['annotationLine']);
          targets.push({
            element,
            lineNumber,
            content: annotations[lineNumber] ?? ''
          });
        });
    }

    this.annotationTargets = targets;
  }

  @action
  updateCode(result: HighlightResult) {
    scheduleOnce('afterRender', this, this.applyUpdate, result);
  }

  applyUpdate(result: HighlightResult) {
    if (this.isDestroying || this.isDestroyed) return;
    this.data = result;
    this.renderCode();
  }

  willDestroy() {
    super.willDestroy();

    this.codeTarget = undefined;
    this.code = undefined;
    this.codeFullScreen = undefined;
    this.wrapperRef = undefined;
    this.rootElement = undefined;
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
    <div
      class={{this.classes}}
      {{style this.overflowHeightStyles}}
      {{didInsert this.setRoot}}
      {{highlightTargetModifier
        element=this.codeTarget
        language=this.highlightLanguage
        lineNumbersConfig=this.lineNumbersConfig
        lineClasses=this.lineClasses
        onChange=this.updateCode
      }}
    >
      {{#if this.isVirtualized}}
        <VirtualizedCodeBlock
          tabindex="0"
          @preClass={{this.preClasses}}
          @codeClass={{this.codeClasses}}
          @label={{this.label}}
          @labelClass={{this.labelClasses}}
          @language={{this.language}}
          @data={{this.data.data}}
          @rowHeight={{this.rowHeight}}
          @overflowHeight={{@overflowHeight}}
        />
      {{else}}
        {{!template-lint-disable}}
        <pre
          class={{this.preClasses}}
          {{style this.overflowHeightStyles}}
          tabindex={{this.tabIndex}}
          {{didInsert this.setWrapperRef}}
          {{resizeObserver onResize=this.doesOverflow}}
          {{mutationObserver
            onMutation=this.doesOverflow
            observerOptions=(hash subtree=true childList=true)
          }}
        ><div class={{this.labelClasses}}>{{this.label}}</div><code
            class={{this.codeClasses}}
            data-code-language={{this.language}}
            {{didInsert this.setCode}}
            ...attributes
          ></code></pre>
      {{/if}}

      <Controls
        @paddingSize={{this.paddingSize}}
        @isFullScreen={{this.isFullScreen}}
        @showFullScreenButton={{this.showFullScreenButton}}
        @toggleFullScreen={{this.toggleFullScreen}}
        @showCopyButton={{this.showCopyButton}}
        @copyAriaLabel={{@copyAriaLabel}}
        @textToCopy={{this.textToCopy}}
      />

      {{#if this.isFullScreen}}
        <FullScreenDisplay @onKeyDown={{this.onFullScreenKeyDown}}>
          {{#if this.isVirtualized}}
            <VirtualizedCodeBlock
              tabindex="0"
              @preClass={{this.preFullScreenClasses}}
              @codeClass={{this.codeClasses}}
              @label={{this.label}}
              @labelClass={{this.labelClasses}}
              @language={{this.language}}
              @data={{this.data.data}}
              @rowHeight={{this.fullScreenRowHeight}}
            />
          {{else}}
            <pre
              class={{this.preFullScreenClasses}}
              tabindex="0"
            ><div class={{this.labelClasses}}>{{this.label}}</div><code
                class={{this.codeClasses}}
                data-code-language={{this.language}}
                {{didInsert this.setCodeFullScreen}}
              ></code></pre>
          {{/if}}
          <Controls
            @paddingSize="l"
            @isFullScreen={{this.isFullScreen}}
            @showFullScreenButton={{this.showFullScreenButton}}
            @showCopyButton={{this.showCopyButton}}
            @copyAriaLabel={{@copyAriaLabel}}
            @toggleFullScreen={{this.toggleFullScreen}}
            @textToCopy={{this.textToCopy}}
          />
        </FullScreenDisplay>
      {{/if}}
    </div>
    {{#each this.annotationTargets as |target|}}
      {{#in-element target.element insertBefore=null}}
        <Annotation @lineNumber={{target.lineNumber}}>{{target.content}}</Annotation>
      {{/in-element}}
    {{/each}}
  </template>
}
