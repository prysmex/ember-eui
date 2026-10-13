import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { registerDestructor } from '@ember/destroyable';
import { action } from '@ember/object';
import { cancel, later } from '@ember/runloop';
import { buildWaiter } from '@ember/test-waiters';

import { modifier } from 'ember-modifier';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiTextTruncateStyles,
  TruncationUtils
} from '../utils/eui/styles.generated.ts';
import EuiToolTip from './eui-tool-tip.gts';

import type { EuiTooltipArgs } from './eui-tool-tip';

export const TRUNCATION_TYPES = ['end', 'start', 'startEnd', 'middle'] as const;
export type EuiTextTruncationTypes = (typeof TRUNCATION_TYPES)[number];

/** The extracted upstream `TruncationUtils` (canvas text measurement). */
interface Truncation {
  checkIfTruncationIsNeeded(): false | undefined;
  checkSufficientEllipsisWidth(truncation: EuiTextTruncationTypes): false | undefined;
  truncateEnd(truncationOffset?: number): string;
  truncateStart(truncationOffset?: number): string;
  truncateStartEndAtMiddle(): string;
  truncateStartEndAtPosition(truncationPosition: number): string;
  truncateMiddle(): string;
}
const Utils = TruncationUtils as unknown as new (options: {
  fullText: string;
  ellipsis: string;
  container: HTMLElement;
  availableWidth: number;
}) => Truncation;

const waiter = buildWaiter('@ember-eui/core:eui-text-truncate');

/**
 * Upstream `EuiResizeObserver`: reports the border box size after layout,
 * only when it changes (starting from 0×0). Settled-aware until the first
 * observation so tests see the measured text.
 */
const observeSize = modifier(
  (
    element: HTMLElement,
    [observe, onResize]: [
      boolean,
      (size: { width: number; height: number }) => void
    ]
  ) => {
    if (!observe || typeof ResizeObserver === 'undefined') return;
    let size = { width: 0, height: 0 };
    let token: unknown = waiter.beginAsync();
    const settle = () => {
      if (token === undefined) return;
      waiter.endAsync(token);
      token = undefined;
    };
    let frame: number | undefined;
    const observer = new ResizeObserver(([entry]) => {
      const box = entry?.borderBoxSize?.[0];
      if (!box) return settle();
      const next = { width: box.inlineSize, height: box.blockSize };
      if (next.width === size.width && next.height === size.height) {
        return settle();
      }
      size = next;
      // Re-truncating can resize the element again; reporting in the next
      // frame avoids "ResizeObserver loop completed with undelivered
      // notifications".
      if (frame !== undefined) cancelAnimationFrame(frame);
      frame = requestAnimationFrame(() => {
        frame = undefined;
        onResize(size);
        settle();
      });
    });
    observer.observe(element);
    return () => {
      if (frame !== undefined) cancelAnimationFrame(frame);
      observer.disconnect();
      settle();
    };
  }
);

/** Hands the rendered container to the component (upstream's ref state). */
const container = modifier(
  (element: HTMLElement, [setContainer]: [(element: HTMLElement) => void]) => {
    setContainer(element);
  }
);

/** The `EuiToolTip` arguments `@toolTipProps` accepts. */
export type EuiTextTruncateToolTipProps = Partial<
  Pick<
    EuiTooltipArgs,
    'position' | 'delay' | 'title' | 'content' | 'offset' | 'className' | 'css'
  >
>;

export interface EuiTextTruncateSignature {
  Element: HTMLDivElement;
  Args: {
    /** The full text to truncate. */
    text: string;
    /**
     * Where the ellipsis goes: `'end'`, `'start'`, `'startEnd'` (both ends,
     * around `@truncationPosition`) or `'middle'`. Defaults to `'end'`.
     */
    truncation?: EuiTextTruncationTypes;
    /**
     * Only for `'start'` and `'end'`: number of characters at the start
     * (`'start'`) or end (`'end'`) that are always kept. Ignored when it is
     * not less than the text length. Defaults to `0`.
     */
    truncationOffset?: number;
    /**
     * Only for `'startEnd'`: character index the visible text is anchored
     * on (defaults to the middle), e.g. the position of a search match.
     * At or below 0 it truncates the end, at or beyond the text length the
     * start.
     */
    truncationPosition?: number;
    /** The truncation character(s). Defaults to `'…'`. */
    ellipsis?: string;
    /**
     * Available width in pixels. When given, no resize observer is set up
     * (faster for many truncated items in one container). Defaults to the
     * measured width of the component.
     */
    width?: number;
    /**
     * Called with the new width when the resize observer first measures and
     * on every size change. Not called when `@width` is given.
     */
    onResize?: (width: number) => void;
    /**
     * Waits this many milliseconds after rendering before truncating, for
     * fonts or layout that settle late. The full text shows meanwhile.
     */
    calculationDelayMs?: number;
    /**
     * Tooltip showing the full text while truncating: `position`, `delay`,
     * `title`, `content`, `offset`, `className` and `css` of `EuiToolTip`.
     */
    toolTipProps?: EuiTextTruncateToolTipProps;
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop). Prefer this to an extra class when styling it from a parent.
     */
    css?: EuiCss;
  };
  Blocks: {
    /**
     * Custom rendering of the (truncated) text, e.g. with highlighting
     * (upstream's render prop). Receives the text to show.
     */
    default: [text: string];
  };
}

/**
 * Truncates single-line text to the available width at its end, start,
 * both ends or middle (upstream `EuiTextTruncate`), measuring with canvas.
 * While truncating, the full text stays selectable and copyable on top of
 * the truncated text, and a tooltip shows it.
 */
export default class EuiTextTruncate extends Component<EuiTextTruncateSignature> {
  @tracked containerEl: HTMLElement | null = null;
  @tracked observedWidth = 0;
  @tracked hasMeasured = false;
  @tracked ready: boolean;

  constructor(owner: unknown, args: EuiTextTruncateSignature['Args']) {
    super(owner as never, args);
    const delay = args.calculationDelayMs;
    this.ready = !delay;
    if (delay) {
      const timer = later(this, this.markReady, delay);
      registerDestructor(this, () => cancel(timer));
    }
  }

  markReady(): void {
    this.ready = true;
  }

  /** Untracked copy, so the modifier never reads the tracked state it sets. */
  private lastContainer: HTMLElement | null = null;

  @action
  setContainer(element: HTMLElement): void {
    if (this.lastContainer === element) return;
    this.lastContainer = element;
    this.containerEl = element;
  }

  @action
  handleResize({ width }: { width: number }): void {
    this.observedWidth = width;
    this.hasMeasured = true;
    this.args.onResize?.(width);
  }

  get context() {
    return getEuiThemeContext(this);
  }

  get text(): string {
    return this.args.text ?? '';
  }

  get isObserving(): boolean {
    return this.args.width == null;
  }

  get width(): number {
    return this.args.width ?? this.observedWidth;
  }

  get ellipsis(): string {
    return this.args.ellipsis ?? '…';
  }

  /** Upstream's exceptions where the passed props are overridden. */
  @cached
  get settings(): { truncation: EuiTextTruncationTypes; truncationOffset: number } {
    const passed = this.args.truncation ?? 'end';
    const offset = this.args.truncationOffset ?? 0;
    const position = this.args.truncationPosition;
    const length = this.text.length;
    let truncation = passed;
    let truncationOffset = 0;
    if (passed === 'end' || passed === 'start') {
      if (0 < offset && offset < length) truncationOffset = offset;
    } else if (passed === 'startEnd' && position != null) {
      if (position <= 0) truncation = 'end';
      else if (position >= length) truncation = 'start';
    }
    return { truncation, truncationOffset };
  }

  @cached
  get truncatedText(): string {
    const text = this.text;
    const containerEl = this.containerEl;
    if (!this.ready || !containerEl) return text;
    // Upstream renders nothing until its observer reports a width; the full
    // text keeps the line height meanwhile, so the measurement does not
    // resize the observed element again (a ResizeObserver loop error).
    if (this.isObserving && !this.hasMeasured) return text;
    const width = this.width;
    if (!width) return '';
    const { truncation, truncationOffset } = this.settings;
    const position = this.args.truncationPosition;
    const utils = new Utils({
      fullText: text,
      ellipsis: this.ellipsis,
      container: containerEl,
      availableWidth: width
    });
    if (utils.checkIfTruncationIsNeeded() === false) return text;
    if (utils.checkSufficientEllipsisWidth(truncation) === false) return '';
    switch (truncation) {
      case 'start':
        return utils.truncateStart(truncationOffset);
      case 'startEnd':
        return position == null
          ? utils.truncateStartEndAtMiddle()
          : utils.truncateStartEndAtPosition(position);
      case 'middle':
        return utils.truncateMiddle();
      default:
        return utils.truncateEnd(truncationOffset);
    }
  }

  get isTruncating(): boolean {
    return this.truncatedText !== this.text;
  }

  @cached
  get styles() {
    return useEuiBorealisStyles(this.context, euiTextTruncateStyles);
  }

  @cached
  get rootClass(): string {
    return euiClass(this.context, this.styles.euiTextTruncate, this.args.css);
  }

  @cached
  get truncatedTextClass(): string {
    return euiClass(this.context, this.styles.euiTextTruncate__truncatedText);
  }

  @cached
  get fullTextClass(): string {
    return euiClass(this.context, this.styles.euiTextTruncate__fullText);
  }

  <template>
    <div
      class="euiTextTruncate {{this.rootClass}}"
      data-resize-observer={{if this.isObserving "true"}}
      ...attributes
      {{container this.setContainer}}
      {{observeSize this.isObserving this.handleResize}}
    >
      {{#if this.isTruncating}}
        <span
          class="euiTextTruncate__truncatedText {{this.truncatedTextClass}}"
          aria-hidden="true"
          data-test-subj="truncatedText"
        >{{#if (has-block)}}{{yield this.truncatedText}}{{else}}{{this.truncatedText}}{{/if}}</span>
        <span
          class="euiTextTruncate__fullText {{this.fullTextClass}}"
          data-test-subj="fullText"
        >{{this.text}}</span>
        {{! Upstream wraps the truncating text in a block EuiToolTip; attaching
            it keeps this element when truncation starts or stops. }}
        <EuiToolTip
          @attachTo={{this.containerEl}}
          @content={{if @toolTipProps.content @toolTipProps.content this.text}}
          @title={{@toolTipProps.title}}
          @position={{@toolTipProps.position}}
          @delay={{@toolTipProps.delay}}
          @offset={{@toolTipProps.offset}}
          @className={{@toolTipProps.className}}
          @css={{@toolTipProps.css}}
          @disableScreenReaderOutput={{true}}
        />
      {{else}}
        <span
          class="euiTextTruncate__fullText"
          data-test-subj="fullText"
        >{{#if (has-block)}}{{yield this.text}}{{else}}{{this.text}}{{/if}}</span>
      {{/if}}
    </div>
  </template>
}
