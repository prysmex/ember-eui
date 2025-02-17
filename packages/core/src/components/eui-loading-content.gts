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

const repeat = (count: number) => Array.from({ length: count });

const getLength = (lines: number | undefined) => {
  if (lines === undefined) {
    return 1;
  }

  if (lines > 10) {
    return 10;
  } else if (lines < 1) {
    return 1;
  } else {
    return lines;
  }
};

const EuiLoadingContent: TemplateOnlyComponent<EuiLoadingContentSignature> =
  <template>
    <span class="euiLoadingContent" ...attributes>
      {{#each (repeat (getLength @lines))}}
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
