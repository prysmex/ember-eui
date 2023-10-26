import { eq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

interface Signature {
  Element: HTMLDivElement | HTMLSpanElement;
  Args: {
    color?: string;
    tagName?: string;
  };
  Blocks: {
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

declare module '@glint/environment-ember-loose/registry' {
  export default interface Registry {
    EuiTextColor: typeof EuiTextColor;
  }
}
