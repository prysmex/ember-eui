import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { composedOver } from '../utils/eui/page-layout.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiHeaderBreadcrumbsStyles } from '../utils/eui/styles.generated.ts';
import EuiBreadcrumbs from './eui-breadcrumbs.gts';

import type { EuiBreadcrumbsSignature } from './eui-breadcrumbs';

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

/**
 * Upstream `EuiHeaderBreadcrumbs`: `EuiBreadcrumbs` with `max` 4 and
 * truncation, plus `euiHeaderBreadcrumbsStyles` composed over the
 * breadcrumbs' own styles (upstream passes them as `css`).
 */
export default class EuiHeaderBreadcrumbs extends Component<EuiHeaderBreadcrumbsSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiHeaderBreadcrumbsStyles);
    return euiClass(context, composedOver(styles.euiHeaderBreadcrumbs));
  }

  <template>
    <EuiBreadcrumbs
      @max={{4}}
      @truncate={{true}}
      @breadcrumbs={{@breadcrumbs}}
      class="euiHeaderBreadcrumbs {{this.classes}}"
      ...attributes
    />
  </template>
}
