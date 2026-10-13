import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';

import { modifier } from 'ember-modifier';

import { BOX_SIZING } from '../../-private/table.ts';
import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import { euiTableStickyScrollbarStyles } from '../../utils/eui/styles.generated.ts';

/**
 * @private State of `EuiTable`'s sticky horizontal scrollbar (upstream
 * `EuiTableStickyScrollbar`'s hooks). The table observes its scrolling
 * wrapper with {@link observe}; the scrollbar renders only while the
 * wrapper overflows inline.
 */
export class StickyScrollbarState {
  /** The wrapper overflows inline. */
  @tracked isActive = false;
  /** The bottom of the wrapper is visible: the native scrollbar is reachable. */
  @tracked isHidden = false;

  wrapper?: HTMLElement;
  track?: HTMLElement;
  private framePending = false;
  private dragStart: { x: number; scrollLeft: number } | null = null;

  updateTrack(element: Element): void {
    const { clientWidth, scrollWidth, scrollLeft } = element;
    if (this.framePending) return;
    this.framePending = true;
    requestAnimationFrame(() => {
      const track = this.track;
      if (track) {
        track.style.inlineSize = `${(clientWidth / scrollWidth) * 100}%`;
        track.style.marginInlineStart = `${(scrollLeft / scrollWidth) * 100}%`;
      }
      this.framePending = false;
    });
  }

  /** Starts observing the table's scrolling wrapper; returns the cleanup. */
  observe(element: HTMLElement): () => void {
    this.wrapper = element;
    this.updateTrack(element);

    const onScroll = (event: Event) => {
      if (event.target) this.updateTrack(event.target as Element);
    };
    element.addEventListener('scroll', onScroll, { passive: true });

    let resizeObserver: ResizeObserver | undefined;
    if (typeof window.ResizeObserver !== 'undefined') {
      resizeObserver = new ResizeObserver((entries) => {
        const target = entries[0]?.target;
        if (!target) return;
        this.updateTrack(target);
        this.isActive = target.clientWidth < target.scrollWidth;
      });
      resizeObserver.observe(element);
    }

    let intersectionObserver: IntersectionObserver | undefined;
    if (typeof window.IntersectionObserver !== 'undefined') {
      intersectionObserver = new IntersectionObserver(
        (entries) => {
          const entry = entries[0];
          if (!entry?.target) return;
          this.isHidden = !entry.isIntersecting;
        },
        { threshold: 0, rootMargin: '-100% 0px 0px 0px' }
      );
      intersectionObserver.observe(element);
    }

    return () => {
      element.removeEventListener('scroll', onScroll);
      resizeObserver?.disconnect();
      intersectionObserver?.disconnect();
      if (this.wrapper === element) this.wrapper = undefined;
    };
  }

  onPointerDown = (event: PointerEvent): void => {
    this.dragStart = {
      x: event.clientX,
      scrollLeft: this.wrapper?.scrollLeft ?? 0
    };
    (event.currentTarget as HTMLElement).setPointerCapture?.(event.pointerId);
  };

  onPointerMove = (event: PointerEvent): void => {
    const wrapper = this.wrapper;
    if (!this.dragStart || !wrapper) return;
    const diff = event.clientX - this.dragStart.x;
    const ratio = wrapper.scrollWidth / wrapper.clientWidth;
    wrapper.scrollLeft = this.dragStart.scrollLeft + diff * ratio;
  };

  onPointerUp = (): void => {
    this.dragStart = null;
  };
}

export interface EuiTableStickyScrollbarSignature {
  Args: {
    state: StickyScrollbarState;
  };
}

/**
 * @private A scrollbar sticking to the bottom of the viewport while the
 * table's own one is out of view (upstream `EuiTableStickyScrollbar`).
 */
export default class EuiTableStickyScrollbar extends Component<EuiTableStickyScrollbarSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTableStickyScrollbarStyles);
    return {
      wrapper: euiClass(context, BOX_SIZING, styles.wrapper),
      hidden: euiClass(context, BOX_SIZING, styles.wrapper, styles.wrapperHidden),
      track: euiClass(context, BOX_SIZING, styles.track)
    };
  }

  captureTrack = modifier((element: HTMLElement) => {
    const { state } = this.args;
    state.track = element;
    if (state.wrapper) state.updateTrack(state.wrapper);
    return () => {
      if (state.track === element) state.track = undefined;
    };
  });

  <template>
    {{#if @state.isActive}}
      <div
        class={{if @state.isHidden this.classes.hidden this.classes.wrapper}}
        data-test-subj="euiTableStickyScrollbar"
        aria-hidden="true"
      >
        <div
          class={{this.classes.track}}
          data-test-subj="euiTableStickyScrollbarTrack"
          {{this.captureTrack}}
          {{on "pointerdown" @state.onPointerDown}}
          {{on "pointermove" @state.onPointerMove}}
          {{on "pointerup" @state.onPointerUp}}
        ></div>
      </div>
    {{/if}}
  </template>
}
