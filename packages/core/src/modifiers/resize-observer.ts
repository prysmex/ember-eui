import Modifier from 'ember-modifier';
import { action } from '@ember/object';
import { registerDestructor } from '@ember/destroyable';

// IE11 and Safari don't support the `ResizeObserver` API at the time of writing
const hasResizeObserver =
  typeof window !== 'undefined' &&
  typeof (window as any).ResizeObserver !== 'undefined';

export interface Observer {
  disconnect: () => void;
  observe: (element: Element, options?: { [key: string]: any }) => void;
}

const mutationObserverOptions = {
  // [MutationObserverInit](https://developer.mozilla.org/en-US/docs/Web/API/MutationObserverInit)
  attributes: true, // Account for style changes from `className` or `style`
  characterData: true, // Account for text content size differences
  childList: true, // Account for adding/removing child nodes
  subtree: true // Account for deep child nodes
};

interface ResizeObserverSignature {
  Element: Element;
  Args: {
    Positional: [('width' | 'height')] | [];
    Named: {
      onResize: (dimensions: { height: number; width: number }) => void;
    };
  }
}

const makeCompatibleObserver = (node: Element, callback: () => void) => {
  const observer = new MutationObserver(callback);
  //eslint-disable-next-line
  observer.observe(node, mutationObserverOptions);

  window.addEventListener('resize', callback);

  const _disconnect = observer.disconnect.bind(observer);
  observer.disconnect = () => {
    _disconnect();
    window.removeEventListener('resize', callback);
  };

  return observer;
};

const makeResizeObserver = (node: Element, callback: () => void) => {
  let observer: Observer | undefined;
  if (hasResizeObserver) {
    observer = new (window as any).ResizeObserver(callback);
    observer!.observe(node);
  } else {
    observer = makeCompatibleObserver(node, callback);
    requestAnimationFrame(callback); // Mimic ResizeObserver behavior of triggering a resize event on init
  }
  return observer;
};

export default class ResizeObserver extends Modifier<ResizeObserverSignature> {
  height: number = 0;
  width: number = 0;
  observer: Observer | null = null;

  element!: Element;
  named!: ResizeObserverSignature['Args']['Named'];
  positional!: ResizeObserverSignature['Args']['Positional'];

  @action
  setSize({ width, height }: { width: number; height: number }) {
    let [dimension] = this.positional;
    const doesWidthMatter = dimension !== 'height';
    const doesHeightMatter = dimension !== 'width';
    if (
      (doesWidthMatter && width !== this.width) ||
      (doesHeightMatter && height !== this.height)
    ) {
      this.width = width;
      this.height = height;
      this.named?.onResize({ width, height });
    }
  }


  modify(
    element: Element,
    positional: ResizeObserverSignature['Args']['Positional'] = [],
    named: ResizeObserverSignature['Args']['Named']
  ) {
    this.element = element;
    this.named = named;
    this.positional = positional;
    this._setup();
    registerDestructor(this, () => this._teardown());
  }

  _setup() {
    let { setSize, element } = this;
    if (element != null) {
      // ResizeObserver's first call to the observation callback is scheduled in the future
      // so find the element's initial dimensions now
      const boundingRect = element.getBoundingClientRect();
      setSize({
        width: boundingRect.width,
        height: boundingRect.height
      });

      this.observer = makeResizeObserver(element, () => {
        const boundingRect = element.getBoundingClientRect();
        setSize({
          width: boundingRect.width,
          height: boundingRect.height
        });
      })!;
    } else {
      setSize({
        width: 0,
        height: 0
      });
    }
  }

  _teardown() {
    this.observer?.disconnect();
  }
}
