import { eq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** Colors its text content. */
interface Signature {
  Element: HTMLDivElement | HTMLSpanElement;
  Args: {
    /**
     * `'default'`, `'subdued'`, `'success'`, `'accent'`, `'danger'`,
     * `'warning'`, `'ghost'` or `'primary'`. Defaults to `'default'`.
     */
    color?: string;
    /** `'span'` (inline) or `'div'`. Defaults to `'span'`. */
    tagName?: string;
  };
  Blocks: {
    /** The content. */
    default: [];
  };
}

const EuiTextColor: TemplateOnlyComponent<Signature> = <template>
  {{#if (eq @tagName "div")}}
    <div
      class={{classNames
        componentName="EuiTextColor"
        color=(argOrDefault @color "default")
      }}
      ...attributes
    >
      {{yield}}
    </div>
  {{else}}
    <span
      class={{classNames
        componentName="EuiTextColor"
        color=(argOrDefault @color "default")
      }}
      ...attributes
    >
      {{yield}}
    </span>
  {{/if}}
</template>;

export default EuiTextColor;
