import { and, not } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export type IEuiTab = {
  id?: string;
  href?: string;
  isSelected?: boolean;
  disabled?: boolean;
};

export interface EuiTabSignature {
  Element: HTMLButtonElement | HTMLAnchorElement;
  Args: {
    [K in keyof IEuiTab]: IEuiTab[K];
  };
  Blocks: {
    prepend: [];
    default: [];
    append: [];
  };
}

const EuiTab: TemplateOnlyComponent<EuiTabSignature> = <template>
  {{#let (argOrDefault @id (randomId)) as |id|}}
    {{#if (and @href (not @disabled))}}
      <a
        id={{id}}
        role="tab"
        aria-selected={{not (not @isSelected)}}
        class={{classNames
          "euiTab"
          (if @isSelected "euiTab-isSelected")
          (if @disabled "euiTab-isDisabled")
        }}
        href={{@href}}
        disabled={{@disabled}}
        ...attributes
      >
        {{#if (has-block "prepend")}}
          <span class="euiTab__prepend">
            {{yield to="prepend"}}
          </span>
        {{/if}}

        <span class="euiTab__content">
          {{yield}}
        </span>

        {{#if (has-block "append")}}
          <span class="euiTab__append">
            {{yield to="append"}}
          </span>
        {{/if}}
      </a>
    {{else}}
      <button
        id={{id}}
        role="tab"
        aria-selected={{not (not @isSelected)}}
        type="button"
        class={{classNames
          "euiTab"
          (if @isSelected "euiTab-isSelected")
          (if @disabled "euiTab-isDisabled")
        }}
        disabled={{@disabled}}
        ...attributes
      >
        {{#if (has-block "prepend")}}
          <span class="euiTab__prepend">
            {{yield to="prepend"}}
          </span>
        {{/if}}

        <span class="euiTab__content">
          {{yield}}
        </span>

        {{#if (has-block "append")}}
          <span class="euiTab__append">
            {{yield to="append"}}
          </span>
        {{/if}}
      </button>
    {{/if}}
  {{/let}}
</template>;

export default EuiTab;
