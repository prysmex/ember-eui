import { eq } from 'ember-truth-helpers';
import EuiEmotionProvider from '@ember-eui/core/components/eui-emotion-provider';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * The site's outermost Borealis provider: upstream global styles, the theme
 * CSS variables, plus the light/dark mode and high contrast toggle picked in
 * the header (high contrast otherwise follows the OS). No legacy theme
 * stylesheet loads.
 */
const BorealisRoot: TemplateOnlyComponent<{
  Args: { colorMode?: string; highContrastMode?: boolean };
  Blocks: { default: [] };
}> = <template>
  <EuiEmotionProvider
    @colorMode={{if (eq @colorMode "dark") "dark" "light"}}
    @highContrastMode={{@highContrastMode}}
    @wrapper={{false}}
  >
    {{yield}}
  </EuiEmotionProvider>
</template>;

export default BorealisRoot;
