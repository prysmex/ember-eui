import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { argOrDefaultDecorator as argOrDefault } from '../../helpers/arg-or-default';
import { PaddingSize, FontSize } from '../eui-code-block';
//@ts-ignore
import hljs from 'highlight.js';
import { keys } from '../../utils/keys';
import { scheduleOnce } from '@ember/runloop';

type EuiCodeImplArgs = {
  fontSize?: FontSize;

  /**
   * Displays the passed code in an inline format. Also removes any margins set.
   */
  inline?: boolean;

  /**
   * Displays an icon button to copy the code snippet to the clipboard.
   */
  isCopyable?: boolean;

  /**
   * Sets the syntax highlighting for a specific language
   */
  language?: string;
  overflowHeight?: number;
  paddingSize?: PaddingSize;
  transparentBackground?: boolean;
  /**
   * Specify how `white-space` inside the element is handled.
   * `pre` respects line breaks/white space but doesn't force them to wrap the line
   * `pre-wrap` respects line breaks/white space but does force them to wrap the line when necessary.
   */
  whiteSpace?: 'pre' | 'pre-wrap';
};

export default class EuiAccordionAccordionComponent extends Component<EuiCodeImplArgs> {
  // Defaults
  @argOrDefault(false) declare transparentBackground: boolean;
  @argOrDefault('l') declare paddingSize: string;
  @argOrDefault('s') declare fontSize: string;
  @argOrDefault(false) declare isCopyable: boolean;
  @argOrDefault('pre-wrap') declare whiteSpace: string;

  @tracked isFullScreen: boolean = false;
  @tracked isPortalTargetReady: boolean = false;
  @tracked codeTarget: HTMLDivElement | null = null;
  @tracked code: HTMLElement | null = null;
  @tracked codeFullScreen: HTMLElement | null = null;

  observer: MutationObserver | null = null;

  constructor(owner: unknown, args: EuiCodeImplArgs) {
    super(owner, args);
    this.codeTarget = document.createElement('div');
    this.isPortalTargetReady = true;
    this.setupObserver();
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

  willDestroy(): void {
    this.observer?.disconnect();
  }

  @action
  update() {
    const render = () => {
      const language = this.args.language;
      const html = (
        this.isPortalTargetReady && this.codeTarget?.innerHTML
          ? this.codeTarget.innerHTML
          : ''
      ).trim();

      const code = this.code;

      if (code) {
        code.innerHTML = html;
      }

      if (language) {
        if (code) {
          hljs.highlightBlock(code);
        }
      }

      if (this.codeFullScreen) {
        this.codeFullScreen.innerHTML = html;
        if (language) {
          hljs.highlightBlock(this.codeFullScreen);
        }
      }
    };
    scheduleOnce('afterRender', this, render);
  }

  @action
  onKeyDown(event: KeyboardEvent): void {
    if (event.key === keys.ESCAPE) {
      event.preventDefault();
      event.stopPropagation();
      this.isFullScreen = false;
    }
  }
}
