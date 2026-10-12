import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiPaddingSize,
  euiPopoverFooterStyles,
  euiPopoverTitleStyles,
  euiTitleStyles,
  euiTourFooterStyles,
  euiTourHeaderStyles
} from '../utils/eui/styles.generated.ts';
import { euiPopoverPanelPadding } from './eui-popover-panel-context.ts';

import type { EuiThemeContext } from '../utils/emotion/context.ts';

/*
 * Upstream `_tour_header.js` / `_tour_footer.js` render EuiPopoverTitle,
 * EuiPopoverFooter and EuiTitle with a `css` prop. Those Ember components
 * have no `@css` yet, so the same upstream factories are composed here into
 * a single class per element (a second Emotion class on them would depend
 * on rule insertion order). Switch back to the components once they accept
 * `@css`.
 */

/** EuiTitle's scoped reset (no React global reset). */
function titleReset(context: EuiThemeContext) {
  return {
    boxSizing: 'border-box',
    margin: 0,
    padding: 0,
    fontFamily: context.upstream.euiTheme.font.family
  } as const;
}

interface EuiTourHeaderSignature {
  Element: HTMLDivElement;
  Args: { title?: string; subtitle?: string };
}

/** @private Upstream `EuiTourHeader`: popover title without its border. */
export class EuiTourHeader extends Component<EuiTourHeaderSignature> {
  @cached
  get classes(): {
    header: string;
    subtitle: string;
    title: string;
  } {
    const context = getEuiThemeContext(this);
    const popoverTitle = useEuiBorealisStyles(context, euiPopoverTitleStyles);
    const tour = useEuiBorealisStyles(context, euiTourHeaderStyles);
    const title = useEuiBorealisStyles(context, euiTitleStyles);
    const panelPadding = euiPopoverPanelPadding(this);
    const padding = euiPaddingSize(context.upstream, panelPadding);
    const reset = titleReset(context);

    return {
      header: `euiPopoverTitle euiTourHeader ${euiClass(
        context,
        popoverTitle.euiPopoverTitle,
        popoverTitle.panelPaddingSizes[panelPadding],
        padding && { padding },
        tour.euiTourHeader
      )}`,
      subtitle: `euiTitle euiTourHeader__subtitle ${euiClass(
        context,
        reset,
        title.euiTitle,
        title.xxxs,
        tour.euiTourHeader__subtitle
      )}`,
      title: `euiTitle euiTourHeader__title ${euiClass(
        context,
        reset,
        title.euiTitle,
        title.xxs,
        tour.euiTourHeader__title
      )}`
    };
  }

  <template>
    <div class={{this.classes.header}} ...attributes>
      {{#if @subtitle}}
        <h2 class={{this.classes.subtitle}}>{{@subtitle}}</h2>
        <h3 class={{this.classes.title}}>{{@title}}</h3>
      {{else}}
        <h2 class={{this.classes.title}}>{{@title}}</h2>
      {{/if}}
    </div>
  </template>
}

interface EuiTourFooterSignature {
  Element: HTMLDivElement;
  Blocks: { default: [] };
}

/** @private Upstream `EuiTourFooter` box: popover footer + tour background. */
export class EuiTourFooter extends Component<EuiTourFooterSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const footer = useEuiBorealisStyles(context, euiPopoverFooterStyles);
    const tour = useEuiBorealisStyles(context, euiTourFooterStyles);
    const panelPadding = euiPopoverPanelPadding(this);
    const padding = euiPaddingSize(context.upstream, panelPadding);

    return `euiPopoverFooter euiTourFooter ${euiClass(
      context,
      footer.euiPopoverFooter,
      footer.panelPaddingSizes[panelPadding],
      padding && { padding },
      tour.euiTourFooter
    )}`;
  }

  <template>
    <div class={{this.classes}} ...attributes>{{yield}}</div>
  </template>
}
