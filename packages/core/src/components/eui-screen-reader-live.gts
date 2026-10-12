import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';

import { modifier } from 'ember-modifier';

import { observeLiveText } from '../-private/live-text.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiScreenReaderOnlyClass } from './eui-screen-reader-only.gts';

export type EuiLiveRegionRole = 'status' | 'alert' | 'log' | 'timer' | 'marquee';
export type EuiAriaLive = 'off' | 'polite' | 'assertive';

/**
 * Upstream's focus effect: runs on insert and whenever the toggle flips,
 * focusing the region when `focusRegionOnTextChange` is on.
 */
const focusOnChange = modifier(
  (element: HTMLElement, [, focus]: [boolean, boolean | undefined]) => {
    if (focus) element.focus();
  }
);

/**
 * Announces its content to screen readers whenever the content's text
 * changes, without showing it (upstream `EuiScreenReaderLive`), e.g. "3
 * results" after a search. For a one-off message that is announced once
 * and then cleared, use `EuiLiveAnnouncer`.
 *
 * Like upstream, it renders two live regions and alternates between them on
 * every change, so consecutive announcements are read reliably. The block is
 * rendered into a `hidden` element and its text is what gets announced.
 */
export interface EuiScreenReaderLiveSignature {
  Element: HTMLDivElement;
  Args: {
    /** Whether screen readers are made aware of the content. Defaults to `true`. */
    isActive?: boolean;
    /**
     * `role` of both live regions, e.g. `'status'` or `'alert'`. Defaults
     * to `'status'`.
     */
    role?: EuiLiveRegionRole;
    /**
     * `aria-live` of both live regions: `'polite'`, `'assertive'` or
     * `'off'`. Defaults to `'polite'`.
     */
    ariaLive?: EuiAriaLive;
    /**
     * Focuses the region when the text changes (and on insert), so screen
     * readers read it out. Use it for navigation or page changes, where
     * moving focus back to a known place is desired. Defaults to `false`.
     */
    focusRegionOnTextChange?: boolean;
  };
  Blocks: {
    /** The content to announce. */
    default: [];
  };
}

export default class EuiScreenReaderLive extends Component<EuiScreenReaderLiveSignature> {
  /** The block's current text. */
  @tracked text = '';
  /** Which of the two regions holds the text (upstream's `toggle`). */
  @tracked toggle = false;

  #seen = false;

  observeLiveText = observeLiveText;
  focusOnChange = focusOnChange;

  @cached
  get srClass() {
    return euiScreenReaderOnlyClass(getEuiThemeContext(this));
  }

  get role(): EuiLiveRegionRole {
    return this.args.role ?? 'status';
  }

  get isActive(): boolean {
    return this.args.isActive ?? true;
  }

  liveFor(active: boolean): EuiAriaLive {
    return !active || this.args.focusRegionOnTextChange
      ? 'off'
      : (this.args.ariaLive ?? 'polite');
  }

  get firstLive() {
    return this.liveFor(this.toggle);
  }

  get secondLive() {
    return this.liveFor(!this.toggle);
  }

  get firstHidden() {
    return this.toggle ? undefined : 'true';
  }

  get secondHidden() {
    return this.toggle ? 'true' : undefined;
  }

  get firstText() {
    return this.isActive && this.toggle ? this.text : '';
  }

  get secondText() {
    return this.isActive && !this.toggle ? this.text : '';
  }

  get tabIndex() {
    return this.args.focusRegionOnTextChange ? '-1' : undefined;
  }

  /** Upstream toggles on mount and on every change of `children`. */
  onText = (text: string): void => {
    if (this.#seen && text === this.text) return;
    this.#seen = true;
    this.text = text;
    this.toggle = !this.toggle;
  };

  <template>
    <div
      class={{this.srClass}}
      tabindex={{this.tabIndex}}
      ...attributes
      {{this.focusOnChange this.toggle @focusRegionOnTextChange}}
    >
      <div
        role={{this.role}}
        aria-atomic="true"
        aria-hidden={{this.firstHidden}}
        aria-live={{this.firstLive}}
      >{{this.firstText}}</div>
      <div
        role={{this.role}}
        aria-atomic="true"
        aria-hidden={{this.secondHidden}}
        aria-live={{this.secondLive}}
      >{{this.secondText}}</div>
      <div hidden {{this.observeLiveText this.onText}}>{{yield}}</div>
    </div>
  </template>
}
