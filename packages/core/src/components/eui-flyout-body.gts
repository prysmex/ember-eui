import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiFlyoutBodyStyles } from '../utils/eui/styles.generated.ts';

/** The scrolling main content of an EuiFlyout. */
export interface EuiFlyoutBodySignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * `tabindex` of the scrolling wrapper, so keyboard users can scroll it.
     * Defaults to `0`; pass `-1` when the content has focusable elements.
     */
    scrollableTabIndex?: number;
  };
  Blocks: {
    /** Content pinned above the scrolling body, e.g. an `EuiCallOut`. */
    banner?: [];
    /** The body; same as the default block. */
    content?: [];
    /** The body. */
    default?: [];
  };
}

export default class EuiFlyoutBody extends Component<EuiFlyoutBodySignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFlyoutBodyStyles);
    const reset = { boxSizing: 'border-box' } as const;
    return {
      root: `euiFlyoutBody ${euiClass(context, reset, styles.euiFlyoutBody)}`,
      overflow: euiClass(
        context,
        reset,
        styles.overflow.euiFlyoutBody__overflow,
        styles.overflow.noBanner
      ),
      overflowWithBanner: euiClass(
        context,
        reset,
        styles.overflow.euiFlyoutBody__overflow,
        styles.overflow.hasBanner
      ),
      banner: `euiFlyoutBody__banner ${euiClass(
        context,
        reset,
        styles.euiFlyoutBody__banner
      )}`
    };
  }

  get scrollableTabIndex() {
    return this.args.scrollableTabIndex ?? 0;
  }

  <template>
    <div class={{this.classes.root}} ...attributes>
      <div
        tabindex={{this.scrollableTabIndex}}
        class="euiFlyoutBody__overflow
          {{if
            (has-block 'banner')
            this.classes.overflowWithBanner
            this.classes.overflow
          }}"
        data-test-subj="euiFlyoutBodyOverflow"
      >
        {{#if (has-block "banner")}}
          <div class={{this.classes.banner}}>
            {{yield to="banner"}}
          </div>
        {{/if}}
        <div class="euiFlyoutBody__overflowContent">
          {{#if (has-block)}}
            {{yield}}
          {{else}}
            {{yield to="content"}}
          {{/if}}
        </div>
      </div>
    </div>
  </template>
}
