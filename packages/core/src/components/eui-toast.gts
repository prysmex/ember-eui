import { on } from '@ember/modifier';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import screenReaderOnly from '../modifiers/screen-reader-only.ts';
import EuiIcon from './eui-icon.gts';
import EuiMarkdownFormat from './eui-markdown-format.gts';
import EuiText from './eui-text.gts';

import type { EuiIconSignature } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface IEuiToast {
  /**
   * The title of the toast.
   */
  title?: string;
  /**
   * The body text of the toast (markdown with `useMarkdownFormat`).
   */
  body?: string;
  /**
   * `'primary'`, `'success'`, `'warning'`, `'danger'` or `'none'`.
   * Defaults to `'none'`.
   */
  color?: 'primary' | 'success' | 'warning' | 'danger' | 'none';
  /**
   * Icon before the title, e.g. `'check'` or `'alert'`.
   */
  iconType?: EuiIconSignature['Args']['type'];
  /**
   * Shows a close button calling this function.
   */
  onClose?: () => void;
  /**
   * Renders `body` as markdown (EuiMarkdownFormat).
   */
  useMarkdownFormat?: boolean;
}

/**
 * A notification card. Usually shown through the `euiToaster` service and
 * EuiGlobalToastList rather than rendered directly.
 */
export interface EuiToastSignature {
  Element: HTMLDivElement;
  Args: IEuiToast;
}

const EuiToast: TemplateOnlyComponent<EuiToastSignature> = <template>
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
