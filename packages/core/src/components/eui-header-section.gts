import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass } from '../utils/eui/styles.ts';
import { euiHeaderSectionStyles } from '../utils/eui/styles.generated.ts';

/** A group of `EuiHeaderSectionItem`s on one side of the header. */
export interface EuiHeaderSectionSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * `'left'` or `'right'`. A right section is pushed to the end with
     * `margin-inline-start: auto` (start/end in RTL). Defaults to `'left'`.
     */
    side?: 'left' | 'right';
    /** Takes the remaining space, e.g. for a search bar. Defaults to `false`. */
    grow?: boolean;
  };
  Blocks: {
    /** The `EuiHeaderSectionItem`s. */
    default: [];
  };
}

// Upstream calls this factory without a theme: its styles are static.
const styles = euiHeaderSectionStyles();

/** Upstream `EuiHeaderSection` (`euiHeaderSectionStyles`). */
export default class EuiHeaderSection extends Component<EuiHeaderSectionSignature> {
  @cached
  get classes(): string {
    return euiClass(
      getEuiThemeContext(this),
      { boxSizing: 'border-box' },
      styles.euiHeaderSection,
      this.args.grow && styles.grow,
      styles[this.args.side ?? 'left']
    );
  }

  <template>
    <div class="euiHeaderSection {{this.classes}}" ...attributes>
      {{yield}}
    </div>
  </template>
}
