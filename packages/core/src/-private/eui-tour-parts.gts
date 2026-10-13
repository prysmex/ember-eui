import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import EuiPopoverFooter from '../components/eui-popover-footer.gts';
import EuiPopoverTitle from '../components/eui-popover-title.gts';
import EuiTitle from '../components/eui-title.gts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiTourFooterStyles,
  euiTourHeaderStyles
} from '../utils/eui/styles.generated.ts';

/*
 * Upstream `_tour_header.js` / `_tour_footer.js`: EuiPopoverTitle,
 * EuiPopoverFooter and EuiTitle with the tour styles as their `css`.
 */

interface EuiTourHeaderSignature {
  Element: HTMLDivElement;
  Args: { title?: string; subtitle?: string };
}

/** @private Upstream `EuiTourHeader`: popover title without its border. */
export class EuiTourHeader extends Component<EuiTourHeaderSignature> {
  @cached
  get styles() {
    return useEuiBorealisStyles(getEuiThemeContext(this), euiTourHeaderStyles);
  }

  <template>
    <EuiPopoverTitle
      class="euiTourHeader"
      @css={{this.styles.euiTourHeader}}
      ...attributes
    >
      {{#if @subtitle}}
        <EuiTitle
          class="euiTourHeader__subtitle"
          @tagName="h2"
          @size="xxxs"
          @css={{this.styles.euiTourHeader__subtitle}}
        >{{@subtitle}}</EuiTitle>
        <EuiTitle
          class="euiTourHeader__title"
          @tagName="h3"
          @size="xxs"
          @css={{this.styles.euiTourHeader__title}}
        >{{@title}}</EuiTitle>
      {{else}}
        <EuiTitle
          class="euiTourHeader__title"
          @tagName="h2"
          @size="xxs"
          @css={{this.styles.euiTourHeader__title}}
        >{{@title}}</EuiTitle>
      {{/if}}
    </EuiPopoverTitle>
  </template>
}

interface EuiTourFooterSignature {
  Element: HTMLDivElement;
  Blocks: { default: [] };
}

/** @private Upstream `EuiTourFooter` box: popover footer + tour background. */
export class EuiTourFooter extends Component<EuiTourFooterSignature> {
  @cached
  get css() {
    return useEuiBorealisStyles(getEuiThemeContext(this), euiTourFooterStyles)
      .euiTourFooter;
  }

  <template>
    <EuiPopoverFooter class="euiTourFooter" @css={{this.css}} ...attributes>
      {{yield}}
    </EuiPopoverFooter>
  </template>
}
