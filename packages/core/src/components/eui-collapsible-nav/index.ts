import Component from '@glimmer/component';
import { EuiBreakpointSize } from '../../utils/breakpoint';
import { tracked } from '@glimmer/tracking';
import { isWithinMinBreakpoint } from '../../utils/breakpoint';
import { throttle } from '@ember/runloop';
import { action } from '@ember/object';
import { modifier } from 'ember-modifier';

export type EuiCollapsibleNavArgs = {
  /**
   * ReactNode to render as this component's content
   */
  children?: Component;
  /**
   * Shows the navigation flyout
   */
  isOpen?: boolean;
  /**
   * Keeps navigation flyout visible and push `<body>` content via padding
   */
  isDocked?: boolean;
  /**
   * Named breakpoint or pixel value for customizing the minimum window width to enable docking
   */
  dockedBreakpoint?: EuiBreakpointSize | number;
  /**
   * Keeps the display of toggle button when in docked state
   */
  showButtonIfDocked?: boolean;

  as: string;

  size?: number;

  side?: 'left' | 'right';

  role?: null | string;

  ownFocus?: boolean;

  outsideClickCloses?: boolean;

  closeButtonPosition?: 'outside' | 'inside';

  paddingSize?: string;
};

const triggerHandlersModifier = modifier(
  (
    element: HTMLElement,
    _pos,
    { flyoutID, isOpen }: { flyoutID: string; isOpen: boolean }
  ) => {
    element.setAttribute('aria-controls', flyoutID);
    element.setAttribute('aria-expanded', isOpen ? 'true' : '');
    element.setAttribute('aria-pressed', isOpen ? 'true' : '');

    const fn = (e: Event) => {
      e.stopImmediatePropagation();
    };

    element.addEventListener('touchend', fn);
    element.addEventListener('mouseup', fn, true);
    return () => {
      element.removeEventListener('touchend', fn);
      element.removeEventListener('mouseup', fn, true);
    };
  }
);

const onWindowResizeModifier = modifier(
  (
    _ele: HTMLElement,
    _pos,
    {
      isDocked = false,
      functionToCallOnWindowResize
    }: { isDocked: boolean; functionToCallOnWindowResize: () => void }
  ) => {
    if (isDocked) {
      window.addEventListener('resize', functionToCallOnWindowResize);
    }

    return () => {
      if (isDocked) {
        window.removeEventListener('resize', functionToCallOnWindowResize);
      }
    };
  }
);

export default class EuiCollapsibleNavComponent extends Component<EuiCollapsibleNavArgs> {
  triggerHandlers = triggerHandlersModifier;
  onWindowResize = onWindowResizeModifier;
  @tracked windowIsLargeEnoughToPush = isWithinMinBreakpoint(
    typeof window === 'undefined' ? -Infinity : window.innerWidth,
    this.dockedBreakpoint
  );

  get isDocked() {
    return this.args.isDocked ?? false;
  }

  get navIsDocked() {
    return this.isDocked && this.windowIsLargeEnoughToPush;
  }

  get dockedBreakpoint() {
    return this.args.dockedBreakpoint ?? 'l';
  }

  get showButtonIfDocked() {
    return this.args.showButtonIfDocked ?? false;
  }

  get as() {
    return this.args.as ?? 'nav';
  }

  get size() {
    if (this.args.size && typeof this.args.size !== 'string') {
      return `${this.args.size}px`;
    }
    return this.args.size ?? '320px';
  }

  get side() {
    return this.args.side ?? 'left';
  }

  get role() {
    return this.args.role ?? null;
  }

  get ownFocus() {
    return this.args.ownFocus ?? true;
  }

  get outsideClickCloses() {
    return this.args.outsideClickCloses ?? true;
  }

  get closeButtonPosition() {
    return this.args.closeButtonPosition ?? 'outside';
  }

  get paddingSize() {
    return this.args.paddingSize ?? 'none';
  }

  @action
  functionToCallOnWindowResize() {
    throttle(() => {
      if (isWithinMinBreakpoint(window.innerWidth, this.dockedBreakpoint)) {
        this.windowIsLargeEnoughToPush = true;
      } else {
        this.windowIsLargeEnoughToPush = false;
      }
    }, 50);
  }
}
