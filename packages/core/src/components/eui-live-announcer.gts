import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { registerDestructor } from '@ember/destroyable';

import { observeLiveText } from '../-private/live-text.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiScreenReaderOnlyClass } from './eui-screen-reader-only.gts';

import type Owner from '@ember/owner';
import type {
  EuiAriaLive,
  EuiLiveRegionRole
} from './eui-screen-reader-live.gts';

/** Upstream renders the content after a short delay, so it is announced. */
const MOUNT_DELAY_MS = 50;

/**
 * Announces a message to screen readers once, e.g. feedback after an
 * action, then clears it (upstream `EuiLiveAnnouncer`). The message is not
 * shown. It is announced when the component is inserted and again whenever
 * its text changes. For content that stays in sync with the page, e.g. a
 * result count, use `EuiScreenReaderLive`.
 *
 * The block is rendered into a `hidden` element; its text is copied into
 * the live region.
 */
export interface EuiLiveAnnouncerSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Clears the live region after this many ms (it is still read if it is
     * cleared meanwhile), or `false` to keep the message. Defaults to `2000`.
     */
    clearAfterMs?: number | false;
    /**
     * Whether screen readers announce the message (`aria-live="off"`
     * otherwise). Defaults to `true`.
     */
    isActive?: boolean;
    /** `role` of the live region. Defaults to `'status'`. */
    role?: EuiLiveRegionRole;
    /**
     * `aria-live` of the live region: `'polite'`, `'assertive'` or
     * `'off'`. Defaults to `'polite'`.
     */
    ariaLive?: EuiAriaLive;
  };
  Blocks: {
    /** The message. */
    default: [];
  };
}

export default class EuiLiveAnnouncer extends Component<EuiLiveAnnouncerSignature> {
  /** The announced text; empty before the first message and once cleared. */
  @tracked content = '';
  @tracked isMounted = false;

  #clearTimer?: ReturnType<typeof setTimeout>;

  observeLiveText = observeLiveText;

  constructor(owner: Owner, args: EuiLiveAnnouncerSignature['Args']) {
    super(owner, args);
    const mountTimer = setTimeout(() => {
      this.isMounted = true;
    }, MOUNT_DELAY_MS);
    registerDestructor(this, () => {
      clearTimeout(mountTimer);
      clearTimeout(this.#clearTimer);
    });
  }

  @cached
  get srClass() {
    return euiScreenReaderOnlyClass(getEuiThemeContext(this));
  }

  get role(): EuiLiveRegionRole {
    return this.args.role ?? 'status';
  }

  get ariaLive(): EuiAriaLive {
    return (this.args.isActive ?? true)
      ? (this.args.ariaLive ?? 'polite')
      : 'off';
  }

  get text(): string {
    return this.isMounted ? this.content : '';
  }

  /** Upstream's effect on `[children, clearAfterMs]`. */
  onText = (text: string): void => {
    if (text) this.content = text;
    clearTimeout(this.#clearTimer);
    const clearAfterMs = this.args.clearAfterMs ?? 2000;
    if (clearAfterMs) {
      this.#clearTimer = setTimeout(() => {
        this.content = '';
      }, clearAfterMs);
    }
  };

  <template>
    <div
      class={{this.srClass}}
      aria-atomic="true"
      ...attributes
      role={{this.role}}
      aria-live={{this.ariaLive}}
    >{{this.text}}</div>
    <div hidden {{this.observeLiveText this.onText @clearAfterMs}}>{{yield}}</div>
  </template>
}
