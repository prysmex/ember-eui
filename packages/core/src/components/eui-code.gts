import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import { scheduleOnce } from '@ember/runloop';
import type Owner from '@ember/owner';

import set from 'ember-set-helper/helpers/set';
import { highlight } from 'refractor';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import { checkSupportedLanguage,getHtmlContent } from '../utils/code/utils.ts';

import type { EuiCodeSharedProps } from '../utils/code/utils.ts';
import type { RefractorNode } from 'refractor';

export type EuiCodeArgs = EuiCodeSharedProps & {
  //comments
};

export interface EuiCodeSignature {
  Args: EuiCodeArgs;
  Blocks: {
    default: [];
  };
  Element: HTMLElement;
}

export default class EuiCodeComponent extends Component<EuiCodeSignature> {
  @tracked codeTarget?: HTMLElement;
  @tracked code?: HTMLElement;
  observer: MutationObserver | null = null;

  constructor(owner: Owner, args: EuiCodeArgs) {
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
    this.codeTarget = undefined;
    this.code = undefined;
  }

  <template>
    {{#if this.codeTarget}}
      {{#in-element this.codeTarget}}
        {{yield}}
      {{/in-element}}
    {{/if}}
    <code
      class={{classNames
        "euiCode"
        (if @transparentBackground "euiCode--transparentBackground")
      }}
      data-code-language={{argOrDefault @language "text"}}
      {{didInsert (set this "code")}}
      {{didInsert this.update}}
      {{didUpdate this.update this.language}}
      {{didUpdate this.update this.language}}
      ...attributes
    ></code>
  </template>
}
