import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';


/**
 * Tracks the text content of an element, e.g. to use a truncated label's
 * full text as its `title`.
 */
export interface EuiInnerTextSignature {
  Args: {
    /** Text used when the element's text cannot be read. Defaults to `''`. */
    fallback?: string;
  };

  Blocks: {
    /**
     * Yields a function to call with the element to track (e.g. with
     * `did-insert`) and its current text.
     */
    default: [(ref: HTMLElement) => void, string];
  };
}

export default class EuiImage extends Component<EuiInnerTextSignature> {
  @tracked ref: HTMLElement | null = null;
  @tracked innerText = '';
  observer: MutationObserver | null = null;

  get innerTextFallback() {
    return this.args.fallback ?? '';
  }

  setupObserver() {
    this.observer?.disconnect();
    this.observer = new MutationObserver((mutationsList) => {
      if (mutationsList.length) this.updateInnerText(this.ref);
    });

    if (this.ref) {
      this.updateInnerText(this.ref);
      this.observer.observe(this.ref, {
        characterData: true,
        subtree: true,
        childList: true
      });
    }
  }

  updateInnerText(node: HTMLElement | null) {
    if (!node) return;
    this.setInnerText(
      // Check for `innerText` implementation rather than a simple OR check
      // because in real cases the result of `innerText` could correctly be `null`
      // while the result of `textContent` could correctly be non-`null` due to
      // differing reliance on browser layout calculations.
      // We prefer the result of `innerText`, if available.
      'innerText' in node
        ? node.innerText
        : (node as HTMLElement).textContent || this.innerTextFallback
    );
  }

  setInnerText(text: string) {
    this.innerText = text;
  }

  @action
  setRef(ref: HTMLElement): void {
    this.ref = ref;
    this.setupObserver();
  }

  willDestroy(): void {
    super.willDestroy();
    this.observer?.disconnect();
    this.ref = null;
  }

  <template>
    {{yield this.setRef this.innerText}}
  </template>
}
