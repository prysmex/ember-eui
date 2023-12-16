import EuiBreadcrumbs from './eui-breadcrumbs.gts';

import type { EuiBreadcrumbsSignature } from './eui-breadcrumbs';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiHeaderBreadcrumbsSignature {
  Element: EuiBreadcrumbsSignature['Element'];
  Args: {
    breadcrumbs: EuiBreadcrumbsSignature['Args']['breadcrumbs'];
  };
  Blocks: {
    default: [];
  };
}

const EuiHeaderBreadcrumbs: TemplateOnlyComponent<EuiHeaderBreadcrumbsSignature> =
  <template>
    <EuiBreadcrumbs
      @max={{4}}
      @truncate={{true}}
      @breadcrumbs={{@breadcrumbs}}
      class="euiHeaderBreadcrumbs"
      ...attributes
    />
  </template>;

export default EuiHeaderBreadcrumbs;
