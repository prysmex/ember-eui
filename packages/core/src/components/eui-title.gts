import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import TextBlock from './text-block.gts';

import type { sizeMapping, transformMapping } from '../utils/css-mappings/eui-title.ts';
import type { TextBlockSignature } from './text-block';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * A heading styled with EUI's type scale:
 * `<EuiTitle @size="s" @tagName="h3">Settings</EuiTitle>`.
 */
export interface EuiTitleSignature {
  Element: HTMLHeadingElement;
  Args: {
    /**
     * The heading tag EuiTitle renders: `'h1'`–`'h6'`, `'p'` or `'legend'`.
     * Defaults to `'h2'`. Put the text directly inside EuiTitle; do not wrap
     * it in another heading.
     */
    tagName?: TextBlockSignature['Args']['tagName'];
    /**
     * `'xxxs'`, `'xxs'`, `'xs'`, `'s'`, `'m'` or `'l'`. Defaults to `'m'`.
     * Size is independent of the tag: pick the tag for the page outline and
     * the size for the look.
     */
    size?: keyof typeof sizeMapping;
    /** `'uppercase'` for all caps. */
    textTransform?: keyof typeof transformMapping;
  };
  Blocks: {
    /** The title's text. */
    default: [];
  };
}

const EuiTitle: TemplateOnlyComponent<EuiTitleSignature> = <template>
  <TextBlock
    @tagName={{argOrDefault @tagName "h2"}}
    class={{classNames
      componentName="EuiTitle"
      size=(argOrDefault @size "m")
      textTransform=@textTransform
    }}
    ...attributes
  >
    {{yield}}
  </TextBlock>
</template>;

export default EuiTitle;
