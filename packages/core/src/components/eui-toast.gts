import classNames from '../helpers/class-names';
import screenReaderOnly from '@ember-eui/core/modifiers/screen-reader-only';
import { on } from '@ember/modifier';
import EuiIcon from './eui-icon';
import EuiText from './eui-text';
import EuiMarkdownFormat from './eui-markdown-format';
import argOrDefault from '../helpers/arg-or-default';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiToastSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * The title of the toast
     */
    title?: string;
    /**
     * The body of the toast
     */
    body?: string;
    /**
     * The color of the toast
     */
    color?: 'primary' | 'success' | 'warning' | 'danger' | 'none';
    /**
     * The icon type of the toast
     */
    iconType?: string;
    /**
     * The callback function when the toast is closed
     */
    onClose?: () => void;
    /**
     * Whether to use markdown format for the body
     */
    useMarkdownFormat?: boolean;
  };
}

const EuiToast: TemplateOnlyComponent<EuiToastSignature> = <template>
  {{! @glint-nocheck: not typesafe yet }}
  <div
    class={{classNames
      componentName="EuiToast"
      color=(argOrDefault @color "none")
    }}
    ...attributes
  >
    {{! TODO: Translate strings when EuiI18n is available }}
    <p {{screenReaderOnly}}>
      A new notification appears
    </p>

    <div
      class={{classNames
        "euiToastHeader"
        (if @body "euiToastHeader--withBody")
      }}
      aria-label="Notification"
      data-test-subj="euiToastHeader"
    >
      {{#if @iconType}}
        <EuiIcon
          @iconClasses="euiToastHeader__icon"
          @type={{@iconType}}
          @size="m"
          aria-hidden="true"
        />
      {{/if}}

      <span class="euiToastHeader__title">
        {{@title}}
      </span>
    </div>

    {{#if @onClose}}
      <button
        type="button"
        class="euiToast__closeButton"
        aria-label="Dismiss toast"
        data-test-subj="toastCloseButton"
        {{on "click" @onClose}}
      >
        <EuiIcon @type="cross" @size="m" aria-hidden="true" />
      </button>
    {{/if}}

    {{#if @body}}
      {{#if @useMarkdownFormat}}
        <EuiMarkdownFormat @value={{@body}} />
      {{else}}
        <EuiText @size="s" class="euiToastBody">
          {{@body}}
        </EuiText>
      {{/if}}
    {{/if}}
  </div>
</template>;

export default EuiToast;
