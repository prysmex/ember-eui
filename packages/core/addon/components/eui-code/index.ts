import Component from '@glimmer/component';
import {
  EuiCodeSharedProps,
  getHtmlContent,
  checkSupportedLanguage
} from '../../utils/code/utils';
import { action } from '@ember/object';
import { highlight, RefractorNode } from 'refractor';
import { tracked } from '@glimmer/tracking';
import { scheduleOnce } from '@ember/runloop';

type EuiCodeArgs = EuiCodeSharedProps & {
  //comments
};

export default class EuiCodeComponent extends Component<EuiCodeArgs> {
  @tracked codeTarget: undefined | HTMLElement;
  @tracked code: undefined | HTMLElement;
  observer: MutationObserver | null = null;

  constructor(owner: unknown, args: EuiCodeArgs) {
    super(owner, args);
    this.codeTarget = document.createElement('div');
    this.setupObserver();
  }

  get language() {
    return checkSupportedLanguage(this.args.language || '');
  }

  setupObserver() {
    this.observer?.disconnect();
    this.observer = new MutationObserver((mutationsList) => {
      if (mutationsList.length) this.update();
    });
    if (this.codeTarget) {
      this.update();
      this.observer.observe(this.codeTarget, {
        characterData: true,
        subtree: true,
        childList: true
      });
    }
  }

  @action
  update() {
    const render = () => {
      const html = (
        this.codeTarget?.textContent ? this.codeTarget.textContent : ''
      ).trim();

      let data: RefractorNode[];
      if (typeof html !== 'string') {
        data = [];
      } else {
        data = highlight(html, this.language);
      }

      const code = this.code;

      if (code) {
        code.innerHTML = getHtmlContent(data).element.innerHTML;
      }
    };
    scheduleOnce('afterRender', this, render);
  }

  willDestroy(): void {
    super.willDestroy();
    this.observer?.disconnect();
  }
}
