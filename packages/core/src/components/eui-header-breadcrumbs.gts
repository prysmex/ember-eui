import EuiBreadcrumbs from './eui-breadcrumbs.gts';

import type { EuiBreadcrumbsSignature } from './eui-breadcrumbs';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** EuiBreadcrumbs styled for the header. */
export interface EuiHeaderBreadcrumbsSignature {
  Element: EuiBreadcrumbsSignature['Element'];
  Args: {
    /** The breadcrumbs, see `EuiBreadcrumbs`'s `@breadcrumbs`. */
    breadcrumbs: EuiBreadcrumbsSignature['Args']['breadcrumbs'];
  };
  Blocks: {
    /** Unused. */
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
