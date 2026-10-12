import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
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
 * truncation, plus `euiHeaderBreadcrumbsStyles` as its `@css` (as upstream).
 */
export default class EuiHeaderBreadcrumbs extends Component<EuiHeaderBreadcrumbsSignature> {
  @cached
  get css(): EuiCss {
    const context = getEuiThemeContext(this);
    return useEuiBorealisStyles(context, euiHeaderBreadcrumbsStyles)
      .euiHeaderBreadcrumbs;
  }

  <template>
    <EuiBreadcrumbs
      @max={{4}}
      @truncate={{true}}
      @breadcrumbs={{@breadcrumbs}}
      class="euiHeaderBreadcrumbs"
      @css={{this.css}}
      ...attributes
    />
  </template>
}
