/*
 * Ported from @elastic/eui 123.1.0 `components/focus_trap/focus_trap.tsx`.
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 */
import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';

import { focusTrap } from 'ember-focus-trap';
import { modifier } from 'ember-modifier';

import {
  createRegisteredFocusTrap,
  focusTrapContains,
  setFocusTrapContainers
} from '../-private/focus-trap-registry.ts';
import {
  isolateOutside,
  lockBodyScroll
} from '../-private/focus-trap-effects.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass } from '../utils/eui/styles.ts';

import type { FocusTrap } from 'focus-trap';
import type { EuiCss } from '../utils/eui/styles.ts';

/** An element, a selector, or a function returning an element. */
export type EuiFocusTarget =
  | string
  | HTMLElement
  | SVGElement
  | (() => HTMLElement | SVGElement | null | undefined);

export interface EuiFocusTrapSignature {
  Element: HTMLDivElement;
  Args: {
    /** Turns the trap off. Defaults to `false`. */
    disabled?: boolean;
    /**
     * Where focus goes when the trap is deactivated: `true` returns it to the
     * element focused before activation, `false` leaves it, `FocusOptions`
     * return it with those options and a function receives that element and
     * returns any of these. Defaults to `true`.
     */
    returnFocus?:
      | boolean
      | FocusOptions
      | ((returnTo: Element) => boolean | FocusOptions);
    /**
     * The element focused when the trap activates (selector, element or a
     * function). Otherwise the first `[data-autofocus]` element, then the
     * first tabbable one.
     */
    initialFocus?: EuiFocusTarget;
    /** Set to `false` to not move focus into the trap on activation. */
    autoFocus?: boolean;
    /**
     * Called on a mouse or touch press outside the trap (and its shards and
     * portalled surfaces).
     */
    onClickOutside?: (event: MouseEvent | TouchEvent) => void;
    /** Call `@onClickOutside` on mouseup/touchend instead of on press. */
    closeOnMouseup?: boolean;
    /** The first outside click disables the trap until `@disabled` changes. */
    clickOutsideDisables?: boolean;
    /** Called when Escape is pressed while focus is inside the trap. */
    onEscapeKey?: (event: KeyboardEvent) => void;
    /** Called with the trap element after activation. */
    onActivation?: (node: HTMLElement) => void;
    /** Called after deactivation. */
    onDeactivation?: () => void;
    /**
     * Extra containers that count as inside the trap, as elements, selectors
     * or functions returning an element (upstream's ref objects).
     */
    shards?: EuiFocusTarget[];
    /**
     * Keep focus trapped inside iframes too. By default (`false`) focus may
     * move into an iframe outside the trap.
     */
    crossFrame?: boolean;
    /** Locks body scrolling while the trap is active. Defaults to `false`. */
    scrollLock?: boolean;
    /** How the scrollbar width is kept on lock. Defaults to `'padding'`. */
    gapMode?: 'padding' | 'margin';
    /**
     * `false` hides the content outside the trap from assistive technology
     * and disables pointer events on it. Defaults to `true`.
     */
    noIsolation?: boolean;
    /** Extra styles composed into the wrapper's class. */
    css?: EuiCss;
  };
  Blocks: {
    default: [];
  };
}

const resolve = (target: EuiFocusTarget | undefined) => {
  if (!target) return null;
  if (typeof target === 'string') {
    return document.querySelector<HTMLElement>(target);
  }
  if (typeof target === 'function') return (target() as HTMLElement) ?? null;
  return target as HTMLElement;
};

/** Everything that happens around the trap itself, as one effect. */
const trapEffects = modifier(
  (element: HTMLElement, [owner]: [EuiFocusTrapComponent]) => {
    const { enabled } = owner;
    if (!enabled) return;

    const cleanups: Array<() => void> = [];
    const inside = (target: EventTarget | null) => {
      if (!(target instanceof Node)) return false;
      const trap = owner.trap;
      if (trap) return focusTrapContains(trap, target);
      return element.contains(target);
    };

    // click outside
    const press = (event: MouseEvent | TouchEvent) => {
      if (inside(event.target)) return;
      owner.handleOutsideClick(event);
    };
    document.addEventListener('mousedown', press);
    document.addEventListener('touchstart', press);
    cleanups.push(() => {
      document.removeEventListener('mousedown', press);
      document.removeEventListener('touchstart', press);
    });

    // escape
    const keydown = (event: KeyboardEvent) => {
      if (event.key !== 'Escape' || event.defaultPrevented) return;
      if (!inside(event.target) && !inside(document.activeElement)) return;
      owner.args.onEscapeKey?.(event);
    };
    document.addEventListener('keydown', keydown);
    cleanups.push(() => document.removeEventListener('keydown', keydown));

    // `crossFrame` false (the default): focus may move into an iframe that
    // is outside the trap, so the trap pauses while that iframe has focus
    // and resumes when focus returns to the page.
    if (!owner.args.crossFrame) {
      let paused = false;
      const focusin = (event: FocusEvent) => {
        const trap = owner.trap;
        if (!trap) return;
        const target = event.target;
        if (
          target instanceof HTMLIFrameElement &&
          !inside(target) &&
          !paused
        ) {
          paused = true;
          trap.pause();
        } else if (paused && !(target instanceof HTMLIFrameElement)) {
          paused = false;
          trap.unpause();
        }
      };
      const refocus = () => {
        if (!paused) return;
        paused = false;
        owner.trap?.unpause();
      };
      window.addEventListener('focusin', focusin, true);
      window.addEventListener('focus', refocus);
      cleanups.push(() => {
        window.removeEventListener('focusin', focusin, true);
        window.removeEventListener('focus', refocus);
        if (paused) owner.trap?.unpause();
      });
    }

    if (owner.args.scrollLock) {
      cleanups.push(lockBodyScroll(owner.args.gapMode ?? 'padding'));
    }

    if (owner.args.noIsolation === false) {
      cleanups.push(
        isolateOutside([
          element,
          ...(owner.args.shards ?? [])
            .map(resolve)
            .filter((el): el is HTMLElement => Boolean(el))
        ])
      );
    }

    return () => cleanups.forEach((fn) => fn());
  }
);

/** Keeps the trap's containers in sync with `@shards`. */
const syncShards = modifier(
  (element: HTMLElement, [owner]: [EuiFocusTrapComponent]) => {
    const shards = owner.resolvedShards;
    if (owner.trap) setFocusTrapContainers(owner.trap, [element, ...shards]);
  }
);

/** Resets a click-outside disable when `@disabled` goes back to false. */
const resetOnEnable = modifier(
  (_el: HTMLElement, [owner]: [EuiFocusTrapComponent]) => {
    const disabled = Boolean(owner.args.disabled);
    const was = owner.lastDisabled;
    owner.lastDisabled = disabled;
    if (was && !disabled) {
      queueMicrotask(() => (owner.disabledByClick = false));
    }
  }
);

/**
 * Keeps keyboard focus inside its content (focus-trap, through
 * ember-focus-trap). Portalled surfaces opened from inside the trap, such as
 * popovers and combo box lists, stay usable.
 */
export default class EuiFocusTrapComponent extends Component<EuiFocusTrapSignature> {
  @tracked disabledByClick = false;
  trap: FocusTrap | undefined;
  lastDisabled = false;
  private mouseupCleanup: (() => void) | undefined;

  private outsideClickTimer: ReturnType<typeof setTimeout> | undefined;

  willDestroy() {
    super.willDestroy();
    this.mouseupCleanup?.();
    clearTimeout(this.outsideClickTimer);
  }

  get enabled() {
    return !this.args.disabled && !this.disabledByClick;
  }

  get resolvedShards() {
    return (this.args.shards ?? [])
      .map(resolve)
      .filter((el): el is HTMLElement => Boolean(el));
  }

  @cached
  get classes() {
    return this.args.css
      ? euiClass(getEuiThemeContext(this), this.args.css)
      : undefined;
  }

  createTrap = (elements: HTMLElement | HTMLElement[], options = {}) => {
    const base = Array.isArray(elements) ? elements : [elements];
    const trap = createRegisteredFocusTrap(
      [...base, ...this.resolvedShards],
      options
    );
    this.trap = trap;
    return trap;
  };

  get createTrapFactory() {
    return this.createTrap as unknown as () => void;
  }

  handleOutsideClick = (event: MouseEvent | TouchEvent) => {
    if (this.args.clickOutsideDisables) this.disabledByClick = true;
    if (!this.args.onClickOutside) return;
    if (!this.args.closeOnMouseup) {
      this.args.onClickOutside(event);
      return;
    }
    this.mouseupCleanup?.();
    const release = (e: MouseEvent | TouchEvent) => {
      this.mouseupCleanup?.();
      // Gives a toggling consumer precedence, like upstream.
      clearTimeout(this.outsideClickTimer);
      this.outsideClickTimer = setTimeout(() => this.args.onClickOutside?.(e));
    };
    document.addEventListener('mouseup', release);
    document.addEventListener('touchend', release);
    this.mouseupCleanup = () => {
      document.removeEventListener('mouseup', release);
      document.removeEventListener('touchend', release);
      this.mouseupCleanup = undefined;
    };
  };

  @cached
  get focusTrapOptions() {
    const { args } = this;
    const returnFocus = args.returnFocus;

    const options: Record<string, unknown> = {
      allowOutsideClick: true,
      clickOutsideDeactivates: false,
      escapeDeactivates: false,
      onPostActivate: () => {
        if (this.container) args.onActivation?.(this.container);
      },
      onPostDeactivate: () => args.onDeactivation?.(),
      fallbackFocus: () => {
        const el = this.container as HTMLElement;
        if (!el.hasAttribute('tabindex')) el.setAttribute('tabindex', '-1');
        return el;
      }
    };

    if (args.autoFocus === false) {
      options['initialFocus'] = false;
    } else if (args.initialFocus) {
      options['initialFocus'] = () =>
        resolve(args.initialFocus) ?? this.autofocusTarget();
    } else {
      options['initialFocus'] = () => this.autofocusTarget();
    }

    if (returnFocus === false) {
      options['returnFocusOnDeactivate'] = false;
    } else if (typeof returnFocus === 'function') {
      options['setReturnFocus'] = (previous: HTMLElement) =>
        this.applyReturn(returnFocus(previous), previous);
    } else if (returnFocus && typeof returnFocus === 'object') {
      options['setReturnFocus'] = (previous: HTMLElement) =>
        this.applyReturn(returnFocus, previous);
    }

    return options;
  }

  container: HTMLElement | undefined;

  autofocusTarget() {
    // `data-autofocus` is react-focus-on's API; undefined falls back to the
    // first tabbable element.
    return (
      this.container?.querySelector<HTMLElement>('[data-autofocus]') ??
      undefined
    );
  }

  applyReturn(
    result: boolean | FocusOptions,
    previous: HTMLElement
  ): HTMLElement | false {
    if (result === false) return false;
    if (result === true) return previous;
    previous.focus(result);
    return false;
  }

  capture = modifier((element: HTMLElement) => {
    this.container = element;
  });

  <template>
    <div
      class={{this.classes}}
      data-focus-lock-disabled={{if this.enabled "false" "disabled"}}
      ...attributes
      {{this.capture}}
      {{focusTrap
        _createFocusTrap=this.createTrapFactory
        isActive=this.enabled
        focusTrapOptions=this.focusTrapOptions
      }}
      {{trapEffects this}}
      {{syncShards this}}
      {{resetOnEnable this}}
    >{{yield}}</div>
  </template>
}
