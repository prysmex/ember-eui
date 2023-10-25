import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import createDetectElementResize from '@ember-eui/core/utils/detect-element-resize';
import style from 'ember-style-modifier/modifiers/style';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

type Size = {
  height: number;
  width: number;
};

interface EuiAutoSizerComponentArgs {
  /** Function responsible for rendering children.*/

  /** Optional custom CSS class name to attach to root AutoSizer element.  */
  className?: string;

  /** Default height to use for initial render; useful for SSR */
  defaultHeight?: number;

  /** Default width to use for initial render; useful for SSR */
  defaultWidth?: number;

  /** Disable dynamic :height property */
  disableHeight: boolean;

  /** Disable dynamic :width property */
  disableWidth: boolean;

  /** Nonce of the inlined stylesheet for Content Security Policy */
  nonce?: string;

  /** Callback to be invoked on-resize */
  onResize: (size: Size) => void;

  /** Optional inline style */
  style?: Record<string, string>;
}

type ResizeHandler = (element: HTMLElement, onResize: () => void) => void;

type DetectElementResize = {
  addResizeListener: ResizeHandler;
  removeResizeListener: ResizeHandler;
};

type DynamicStyle = {
  outerStyle: {
    height?: number | string;
    width?: number | string;
    overflow?: string;
  };
  childStyle?: {
    height?: number | string;
    width?: number | string;
  };
};
export default class EuiAutoSizerComponent extends Component<EuiAutoSizerComponentArgs> {
  _autoSizer?: HTMLElement;
  _parentNode?: HTMLElement;
  _window?: any; // uses any instead of Window because Flow doesn't have window type
  _detectElementResize?: DetectElementResize;

  @tracked height: number | undefined;
  @tracked width: number | undefined;

  get disableHeight() {
    return this.args.disableHeight ?? false;
  }

  get disableWidth() {
    return this.args.disableWidth ?? false;
  }

  get style() {
    let style: DynamicStyle = {
      outerStyle: { overflow: 'visible' },
      childStyle: {}
    };
    if (!this.disableHeight) {
      style.outerStyle.height = `0px`;
      if (style.childStyle) {
        style.childStyle.height = `${this.height}px`;
      }
    }

    if (!this.disableWidth) {
      style.outerStyle.width = `0px`;
      if (style.childStyle) {
        style.childStyle.width = `${this.width}px`;
      }
    }

    return style;
  }

  setup() {
    const { nonce } = this.args;
    if (
      this._autoSizer &&
      this._autoSizer.parentNode &&
      this._autoSizer.parentNode.ownerDocument &&
      this._autoSizer.parentNode.ownerDocument.defaultView &&
      this._autoSizer.parentNode instanceof
        this._autoSizer.parentNode.ownerDocument.defaultView.HTMLElement
    ) {
      // Delay access of parentNode until mount.
      // This handles edge-cases where the component has already been unmounted before its ref has been set,
      // As well as libraries like react-lite which have a slightly different lifecycle.
      this._parentNode = this._autoSizer.parentNode;
      this._window = this._autoSizer.parentNode.ownerDocument.defaultView;

      // Defer requiring resize handler in order to support server-side rendering.
      // See issue #41
      this._detectElementResize = createDetectElementResize(
        nonce,
        this._window
      );
      //@ts-expect-error element is HTMLElement
      this._detectElementResize.addResizeListener(
        this._parentNode,
        this._onResize
      );

      this._onResize();
    }
  }

  _onResize = () => {
    const { disableHeight, disableWidth } = this;

    if (this._parentNode) {
      // Guard against AutoSizer component being removed from the DOM immediately after being added.
      // This can result in invalid style values which can result in NaN values if we don't handle them.
      // See issue #150 for more context.

      const height = this._parentNode.offsetHeight || 0;
      const width = this._parentNode.offsetWidth || 0;

      const win = this._window || window;
      const style = win.getComputedStyle(this._parentNode) || {};
      const paddingLeft = parseInt(style.paddingLeft, 10) || 0;
      const paddingRight = parseInt(style.paddingRight, 10) || 0;
      const paddingTop = parseInt(style.paddingTop, 10) || 0;
      const paddingBottom = parseInt(style.paddingBottom, 10) || 0;

      const newHeight = height - paddingTop - paddingBottom;
      const newWidth = width - paddingLeft - paddingRight;

      if (
        (!disableHeight && this.height !== newHeight) ||
        (!disableWidth && this.width !== newWidth)
      ) {
        this.height = height - paddingTop - paddingBottom;
        this.width = width - paddingLeft - paddingRight;

        this.args.onResize?.({ height, width });
      }
    }
  };

  setRef = (ele: HTMLElement) => {
    this._autoSizer = ele;
    this.setup();
  };

  willDestroy(): void {
    super.willDestroy();
    if (this._detectElementResize && this._parentNode) {
      this._detectElementResize.removeResizeListener(
        this._parentNode,
        this._onResize
      );
    }
  }

  <template>
    <div
      {{didInsert this.setRef}}
      {{style this.style.outerStyle}}
      ...attributes
    >
      {{yield this.style.childStyle}}
    </div>
  </template>
}
