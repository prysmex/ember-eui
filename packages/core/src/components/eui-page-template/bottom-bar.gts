import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import EuiBottomBar from '../eui-bottom-bar.gts';
import EuiPageSection from '../eui-page-section.gts';

import type {
  EuiPagePaddingSize,
  EuiPageRestrictWidth
} from '../../utils/eui/page-layout.ts';
import type { EuiCss } from '../../utils/eui/styles.ts';
import type { EuiBottomBarSignature } from '../eui-bottom-bar';

/** Upstream `_EuiPageBottomBar`: hides wide flex margins, never shrinks. */
const PAGE_BOTTOM_BAR_CSS = { overflow: 'hidden', flexShrink: 0 };

/**
 * `T.BottomBar` of `EuiPageTemplate` (upstream
 * `EuiPageTemplate.BottomBar`): a sticky `EuiBottomBar` at the end of the
 * page's main content, never over the sidebar, with its content aligned to
 * the template's `@restrictWidth` and `@paddingSize`.
 */
export interface EuiPageTemplateBottomBarSignature {
  Element: EuiBottomBarSignature['Element'];
  Args: Omit<EuiBottomBarSignature['Args'], 'paddingSize'> & {
    /**
     * Padding of the bar's content (an `EuiPageSection`): `'none'`,
     * `'xs'`, `'s'`, `'m'`, `'l'` or `'xl'`. Defaults to the template's
     * `@paddingSize`.
     */
    paddingSize?: EuiPagePaddingSize;
    /**
     * Max width of the bar's content, centered. Defaults to the
     * template's `@restrictWidth`.
     */
    restrictWidth?: EuiPageRestrictWidth;
    /**
     * Where the bar sits, see `EuiBottomBar`; `'sticky'` keeps it at the
     * bottom of the main content. Defaults to `'sticky'`.
     */
    position?: EuiBottomBarSignature['Args']['position'];
    /** Styles composed last into the bar's class (upstream's `css`). */
    css?: EuiCss;
  };
  Blocks: {
    /** The bar's content, e.g. buttons in an `EuiFlexGroup`. */
    default: [];
  };
}

/** Upstream `_EuiPageBottomBar` (page_template/bottom_bar). */
export default class EuiPageTemplateBottomBar extends Component<EuiPageTemplateBottomBarSignature> {
  @cached
  get css(): EuiCss {
    return this.args.css ? [PAGE_BOTTOM_BAR_CSS, this.args.css] : PAGE_BOTTOM_BAR_CSS;
  }

  <template>
    <EuiBottomBar
      @paddingSize="none"
      @position={{if @position @position "sticky"}}
      @usePortal={{@usePortal}}
      @affordForDisplacement={{@affordForDisplacement}}
      @bodyClassName={{@bodyClassName}}
      @landmarkHeading={{@landmarkHeading}}
      @top={{@top}}
      @right={{@right}}
      @left={{@left}}
      @bottom={{@bottom}}
      @css={{this.css}}
      ...attributes
    >
      <EuiPageSection
        @paddingSize={{@paddingSize}}
        @restrictWidth={{@restrictWidth}}
      >
        {{yield}}
      </EuiPageSection>
    </EuiBottomBar>
  </template>
}
