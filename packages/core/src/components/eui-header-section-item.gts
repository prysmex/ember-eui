import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiHeaderSectionItemStyles } from '../utils/eui/styles.generated.ts';

/** One item of an EuiHeaderSection, e.g. a logo, links or a button. */
export interface EuiHeaderSectionItemSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * @deprecated Has no effect: latest EUI removed the item dividers
     * (`'left'`, `'right'`, `'none'`).
     */
    border?: 'left' | 'right' | 'none';
  };
  Blocks: {
    /** The item's content. Without a block nothing is rendered, as upstream. */
    default: [];
  };
}

/** Upstream `EuiHeaderSectionItem` (`euiHeaderSectionItemStyles`). */
export default class EuiHeaderSectionItem extends Component<EuiHeaderSectionItemSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiHeaderSectionItemStyles);
    return euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiHeaderSectionItem
    );
  }

  <template>
    {{#if (has-block)}}
      <div class="euiHeaderSectionItem {{this.classes}}" ...attributes>
        {{yield}}
      </div>
    {{/if}}
  </template>
}
