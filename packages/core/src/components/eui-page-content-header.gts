import Component from '@glimmer/component';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiPageBoxSizing } from '../utils/eui/page-layout.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiMaxBreakpoint,
  euiPageHeaderContentStyles
} from '../utils/eui/styles.generated.ts';

/**
 * A header row inside EuiPageContent. Upstream removed this component; it
 * now uses the layout of upstream's children-only `EuiPageHeaderContent`
 * (`childrenOnly`: a spaced-out row with a `size.base` gap).
 */
export interface EuiPageContentHeaderSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Stacks the sections (left-aligned) below the theme's `m` breakpoint
     * (767px in Borealis), like upstream's `responsive` header layout.
     */
    responsive?: boolean;
  };
  Blocks: {
    /** `EuiPageContentHeaderSection`s, e.g. a title and actions. */
    default: [];
  };
}

export default class EuiPageContentHeader extends Component<EuiPageContentHeaderSignature> {
  get classes() {
    const context = getEuiThemeContext(this);
    const upstream = context.upstream;
    const styles = useEuiBorealisStyles(context, euiPageHeaderContentStyles);
    return euiClass(
      context,
      euiPageBoxSizing,
      styles.childrenOnly.flex,
      styles.center,
      // Ember-only: the legacy header kept `size.l` between itself and the
      // content body; upstream has no standalone content header.
      { marginBlockEnd: upstream.euiTheme.size.l },
      this.args.responsive && {
        [euiMaxBreakpoint(upstream, 'm') as string]: styles.childrenOnly.responsive
      }
    );
  }

  <template>
    <div class="euiPageContentHeader {{this.classes}}" ...attributes>
      {{yield}}
    </div>
  </template>
}
