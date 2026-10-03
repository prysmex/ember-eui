import { and, not } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export type IEuiTab = {
  /** Id of the tab. Defaults to a random id. */
  id?: string;
  /** Makes the tab a link, e.g. to a route. */
  href?: string;
  /** Marks the tab as selected (`aria-selected`). */
  isSelected?: boolean;
  /** Disables the tab. */
  disabled?: boolean;
};

/** One tab of an EuiTabs. Add `{{on "click" …}}` to select it. */
export interface EuiTabSignature {
  Element: HTMLButtonElement | HTMLAnchorElement;
  Args: {
    [K in keyof IEuiTab]: IEuiTab[K];
  };
  Blocks: {
    /** Content before the label, e.g. an icon. */
    prepend: [];
    /** The tab's label. */
    default: [];
    /** Content after the label, e.g. a notification badge. */
    append: [];
  };
}

const EuiTab: TemplateOnlyComponent<EuiTabSignature> = <template>
  {{#let (argOrDefault @id (randomId)) as |id|}}
    {{#if (and @href (not @disabled))}}
      <a
        id={{id}}
        role="tab"
        aria-selected={{if @isSelected "true" "false"}}
        class={{classNames "euiTab" (if @isSelected "euiTab-isSelected")}}
        href={{@href}}
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
        aria-selected={{if @isSelected "true" "false"}}
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
