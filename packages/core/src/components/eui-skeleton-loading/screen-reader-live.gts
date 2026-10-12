import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { waitForPromise } from '@ember/test-waiters';

import { modifier } from 'ember-modifier';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiScreenReaderOnlyClass } from '../eui-screen-reader-only.gts';

/**
 * Upstream `EuiScreenReaderLive` props, as accepted by the skeleton
 * components' `@ariaLiveProps`.
 */
export interface EuiScreenReaderLiveProps {
  /** Whether screen readers are told about the text. Defaults to `true`. */
  isActive?: boolean;
  /** `role` of both live regions. Defaults to `'status'`. */
  role?: string;
  /** `aria-live` of both live regions. Defaults to `'polite'`. */
  'aria-live'?: 'polite' | 'assertive' | 'off';
  /**
   * Focus the region whenever the text changes, so screen readers read it
   * immediately. Defaults to `false`.
   */
  focusRegionOnTextChange?: boolean;
}

interface ScreenReaderLiveSignature {
  Args: {
    /** Text to announce. */
    text: string;
    /** Upstream `EuiScreenReaderLive` props. */
    options?: EuiScreenReaderLiveProps;
  };
}

/**
 * Private port of upstream `EuiScreenReaderLive` (used by the skeleton
 * components): two visually hidden live regions whose content alternates on
 * every text change, so repeated announcements are not swallowed. Like the
 * upstream effect, the first swap happens right after insertion.
 */
export default class EuiScreenReaderLive extends Component<ScreenReaderLiveSignature> {
  @tracked toggle = false;

  get isActive() {
    return this.args.options?.isActive ?? true;
  }

  get role() {
    return this.args.options?.role ?? 'status';
  }

  get focusRegion() {
    return this.args.options?.focusRegionOnTextChange ?? false;
  }

  get ariaLive() {
    return this.args.options?.['aria-live'] ?? 'polite';
  }

  get firstHidden() {
    return this.toggle ? undefined : 'true';
  }

  get secondHidden() {
    return this.toggle ? 'true' : undefined;
  }

  get firstLive() {
    return !this.toggle || this.focusRegion ? 'off' : this.ariaLive;
  }

  get secondLive() {
    return this.toggle || this.focusRegion ? 'off' : this.ariaLive;
  }

  get firstText() {
    return this.isActive && this.toggle ? this.args.text : '';
  }

  get secondText() {
    return this.isActive && !this.toggle ? this.args.text : '';
  }

  @cached
  get srClass() {
    return euiScreenReaderOnlyClass(getEuiThemeContext(this));
  }

  /**
   * Runs on insertion and whenever the text changes (upstream's
   * `useEffect(…, [children])`); the swap is deferred to a microtask so it
   * does not update state that this render already read.
   */
  swapOnChange = modifier((element: HTMLElement, [text]: [string]) => {
    void text;
    void waitForPromise(
      Promise.resolve().then(() => {
        if (this.isDestroying || this.isDestroyed) return;
        this.toggle = !this.toggle;
        if (this.focusRegion) element.focus();
      })
    );
  });

  <template>
    <div
      class={{this.srClass}}
      tabindex={{if this.focusRegion "-1"}}
      {{this.swapOnChange @text}}
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
    </div>
  </template>
}
