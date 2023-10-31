import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';


export interface EuiInnerTextSignature {
  Args: {
    fallback?: string;
  };

  Blocks: {
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
  }

  <template>
    {{yield this.setRef this.innerText}}
  </template>
}
