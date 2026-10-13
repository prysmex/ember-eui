import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import type { EuiCss } from '../../utils/eui/styles.ts';
import { euiPaginationButtonStyles } from '../../utils/eui/styles.generated.ts';
import EuiButtonIcon from '../eui-button-icon.gts';
import EuiToolTip from '../eui-tool-tip.gts';

import type EuiI18nService from '../../services/eui-i18n.ts';
import type { EuiButtonIconSignature } from '../eui-button-icon';

export type EuiPaginationArrowType = 'first' | 'previous' | 'next' | 'last';

// Upstream's icons.
const ICONS: Record<EuiPaginationArrowType, string> = {
  first: 'chevronLimitLeft',
  previous: 'chevronSingleLeft',
  next: 'chevronSingleRight',
  last: 'chevronLimitRight'
};

const LABELS: Record<EuiPaginationArrowType, [string, string]> = {
  first: ['euiPaginationButtonArrow.firstPage', 'First page'],
  previous: ['euiPaginationButtonArrow.previousPage', 'Previous page'],
  next: ['euiPaginationButtonArrow.nextPage', 'Next page'],
  last: ['euiPaginationButtonArrow.lastPage', 'Last page']
};

/** @private Upstream `EuiPaginationButtonArrow`: a first/previous/next/last page button. */
export interface EuiPaginationArrowButtonSignature {
  Element: EuiButtonIconSignature['Element'];
  Args: {
    type: EuiPaginationArrowType;
    disabled?: boolean;
    /** Id of the controlled content; an enabled arrow links to `#id`. */
    ariaControls?: string;
    onClick: () => void;
  };
}

export default class EuiPaginationArrowButton extends Component<EuiPaginationArrowButtonSignature> {
  @service declare euiI18n: EuiI18nService;

  get label(): string {
    const [token, fallback] = LABELS[this.args.type];
    return this.euiI18n.lookupToken(token, fallback);
  }

  get iconType(): string {
    return ICONS[this.args.type];
  }

  get linkTarget(): string | undefined {
    const { ariaControls, disabled } = this.args;
    return ariaControls && !disabled ? ariaControls : undefined;
  }

  get href(): string | undefined {
    return this.linkTarget ? `#${this.linkTarget}` : undefined;
  }

  @cached
  /** Upstream's `css` on EuiButtonIcon. */
  get css(): EuiCss {
    const context = getEuiThemeContext(this);
    return useEuiBorealisStyles(context, euiPaginationButtonStyles)
      .euiPaginationButton;
  }

  onClick = (event: MouseEvent) => {
    // The page change is handled here, not by following `href="#id"`.
    event.preventDefault();
    this.args.onClick();
  };

  <template>
    {{#if @disabled}}
      <EuiButtonIcon
        class="euiPaginationArrowButton"
        @css={{this.css}}
        @color="text"
        @iconType={{this.iconType}}
        @isDisabled={{true}}
        @href={{this.href}}
        aria-label={{this.label}}
        aria-controls={{this.linkTarget}}
        data-test-subj="pagination-button-{{@type}}"
        {{on "click" this.onClick}}
        ...attributes
      />
    {{else}}
      {{! upstream: the label doubles as a visual tooltip }}
      <EuiToolTip @content={{this.label}} @disableScreenReaderOutput={{true}}>
        <EuiButtonIcon
          class="euiPaginationArrowButton"
          @css={{this.css}}
          @color="text"
          @iconType={{this.iconType}}
          @href={{this.href}}
          aria-label={{this.label}}
          aria-controls={{this.linkTarget}}
          data-test-subj="pagination-button-{{@type}}"
          {{on "click" this.onClick}}
          ...attributes
        />
      </EuiToolTip>
    {{/if}}
  </template>
}
