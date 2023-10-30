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

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import set from 'ember-set-helper/helpers/set';

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

  <template>
    {{! @glint-nocheck: not typesafe yet }}
    {{#in-element this.codeTarget}}
      {{yield}}
    {{/in-element}}
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
