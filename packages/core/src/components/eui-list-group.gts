import inlineStyles from '../helpers/inline-styles';
import { and } from 'ember-truth-helpers';
import { hash } from '@ember/helper';
import classNames from '../helpers/class-names';
import argOrDefault from '../helpers/arg-or-default';
import { notEq, eq } from 'ember-truth-helpers';
import style from 'ember-style-modifier/modifiers/style';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiListGroupSignature {
  Element: HTMLUListElement;
  Args: {
    maxWidth?: boolean | string;
    bordered?: boolean;
    flush?: boolean;
    gutterSize?: string;
  };
  Blocks: {
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
