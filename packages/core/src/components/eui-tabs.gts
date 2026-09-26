import { eq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { displayMapping,sizeMapping } from '../utils/css-mappings/eui-tabs.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A row of `EuiTab`s; you track the selected one. See also EuiTabbedContent. */
export interface EuiTabsSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * `'default'`, or `'condensed'` (tighter, no bottom border).
     * Defaults to `'default'`.
     */
    display?: keyof typeof displayMapping;
    /** `'s'`, `'m'`, `'l'` or `'xl'`. Defaults to `'m'`. */
    size?: keyof typeof sizeMapping;
    /** Evenly stretches the tabs to fill the width. Defaults to `false`. */
    expand?: boolean;
    /** Border under the tabs. Defaults to `true` (not for `'condensed'`). */
    bottomBorder?: boolean;
    /** Extra class(es). */
    className?: string;
  };
  Blocks: {
    /** The `EuiTab`s. */
    default: [];
  };
}

const EuiTabs: TemplateOnlyComponent<EuiTabsSignature> = <template>
  {{#let
    (if (eq @display "condensed") false (argOrDefault @bottomBorder true))
    as |bottomBorder|
  }}
    <div
      role="tablist"
      class={{classNames
        (if (argOrDefault @expand false) "euiTabs--expand")
        (if bottomBorder "euiTabs--bottomBorder")
        @className
        componentName="EuiTabs"
        display=(argOrDefault @display "default")
        size=(argOrDefault @size "m")
      }}
      ...attributes
    >
      {{yield}}
    </div>
  {{/let}}
</template>;

export default EuiTabs;
