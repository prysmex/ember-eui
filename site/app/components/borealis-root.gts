import { eq } from 'ember-truth-helpers';
import EuiEmotionProvider from '@ember-eui/core/components/eui-emotion-provider';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * The site's outermost Borealis provider: upstream global styles plus the
 * light/dark mode picked in the header. No legacy theme stylesheet loads.
 */
const BorealisRoot: TemplateOnlyComponent<{
  Args: { colorMode?: string };
  Blocks: { default: [] };
}> = <template>
  <EuiEmotionProvider
    @colorMode={{if (eq @colorMode "dark") "dark" "light"}}
    @wrapper={{false}}
  >
    {{yield}}
  </EuiEmotionProvider>
</template>;

export default BorealisRoot;
