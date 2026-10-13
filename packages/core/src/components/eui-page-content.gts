import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import type { EuiCss } from '../utils/eui/styles.ts';
import EuiPanel from './eui-panel.gts';

import type { EuiPanelSignature } from './eui-panel';

/** A panel holding the page's main content, inside EuiPageBody. */
export interface EuiPageContentSignature {
  Element: HTMLDivElement;
  Args: {
    /** `role` of the content. Defaults to `'main'`; pass `null` for none. */
    role?: string | null;
    /** Vertically centers (`'center'`) or bottom-aligns the content panel. */
    verticalPosition?: 'center' | 'bottom';
    /** Horizontally centers the content panel (e.g. an empty prompt). */
    horizontalPosition?: 'center';
    /** Adds a shadow. Defaults to `false`. */
    hasShadow?: boolean;
    /** Adds a border. Defaults to `true`. */
    hasBorder?: boolean;
    /** Padding, any `EuiPanel` padding size. Defaults to `'l'`. */
    paddingSize?: EuiPanelSignature['Args']['paddingSize'];
    /** Border radius: `'none'` or `'m'`. */
    borderRadius?: EuiPanelSignature['Args']['borderRadius'];
    /** Background, any `EuiPanel` color. */
    color?: EuiPanelSignature['Args']['color'];
    /** Fills the remaining height. */
    grow?: boolean;
  };
  Blocks: {
    /** `EuiPageContentHeader` and `EuiPageContentBody`, or any content. */
    default: [];
  };
}

export default class EuiPageContent extends Component<EuiPageContentSignature> {
  get role() {
    const { role } = this.args;
    if (role === null) return undefined;
    return role ?? 'main';
  }

  get grow() {
    if (this.args.grow !== undefined) return this.args.grow;
    return !(
      this.args.verticalPosition === 'center' ||
      this.args.horizontalPosition === 'center'
    );
  }

  /** Positions inside EuiPageBody's flex column (upstream removed this API). */
  @cached
  get positionCss(): EuiCss {
    const { verticalPosition, horizontalPosition } = this.args;
    return [
      verticalPosition === 'center' && {
        alignSelf: 'center',
        marginBlock: 'auto'
      },
      verticalPosition === 'bottom' && { marginBlockStart: 'auto' },
      horizontalPosition === 'center' && {
        marginInline: 'auto',
        inlineSize: 'auto',
        maxInlineSize: '100%'
      }
    ];
  }

  <template>
    <EuiPanel
      role={{this.role}}
      class="euiPageContent"
      @css={{this.positionCss}}
      @hasShadow={{@hasShadow}}
      @hasBorder={{@hasBorder}}
      @paddingSize={{if @paddingSize @paddingSize "l"}}
      @borderRadius={{@borderRadius}}
      @color={{@color}}
      @grow={{this.grow}}
      ...attributes
    >
      {{yield}}
    </EuiPanel>
  </template>
}
