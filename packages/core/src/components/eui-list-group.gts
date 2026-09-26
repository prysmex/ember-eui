import { hash } from '@ember/helper';

import style from 'ember-style-modifier/modifiers/style';
import { and } from 'ember-truth-helpers';
import { eq,notEq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import inlineStyles from '../helpers/inline-styles.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A list of `EuiListGroupItem`s, e.g. navigation links in a side bar. */
export interface EuiListGroupSignature {
  Element: HTMLUListElement;
  Args: {
    /** `true` for EUI's default max width, or any CSS width. */
    maxWidth?: boolean | string;
    /** Adds a border around the list. */
    bordered?: boolean;
    /** Removes the list's padding. */
    flush?: boolean;
    /** Space between items: `'none'`, `'s'` or `'m'`. Defaults to `'s'`. */
    gutterSize?: string;
  };
  Blocks: {
    /** The `EuiListGroupItem`s. */
    default: [];
  };
}

const EuiListGroup: TemplateOnlyComponent<EuiListGroupSignature> = <template>
  {{#let
    (if
      (and @maxWidth (notEq @maxWidth true))
      (inlineStyles
        componentName="EuiListGroup" componentArgs=(hash maxWidth=@maxWidth)
      )
      (hash)
    )
    as |inlineStyles|
  }}
    <ul
      class={{classNames
        (if (eq @maxWidth true) "euiListGroup-maxWidthDefault")
        (if @bordered "euiListGroup-bordered")
        (if @flush "euiListGroup-flush")
        componentName="EuiListGroup"
        gutterSize=(argOrDefault @gutterSize "s")
      }}
      ...attributes
      {{style inlineStyles}}
    >
      {{yield}}
    </ul>
  {{/let}}
</template>;

export default EuiListGroup;
