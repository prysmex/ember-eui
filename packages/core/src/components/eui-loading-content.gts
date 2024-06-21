import repeat from 'ember-composable-helpers/helpers/repeat';
import { gt, lt } from 'ember-truth-helpers';

import classNames from '../helpers/class-names.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiLoadingContentSignature {
  Element: HTMLSpanElement;
  Args: {
    lines?: number;
    singleLineClasses?: string;
  };
  Blocks: {
    default: [];
  };
}

const EuiLoadingContent: TemplateOnlyComponent<EuiLoadingContentSignature> =
  <template>
    <span class="euiLoadingContent" ...attributes>
      {{#each (repeat (if (gt @lines 10) 10 (if (lt @lines 1) 1 @lines)))}}
        <span
          class={{classNames
            "euiLoadingContent__singleLine"
            @singleLineClasses
          }}
        >
          <span class="euiLoadingContent__singleLineBackground" />
        </span>
      {{/each}}
    </span>
  </template>;

export default EuiLoadingContent;
