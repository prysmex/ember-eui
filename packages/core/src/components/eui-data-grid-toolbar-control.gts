import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiDataGridToolbarControlStyles } from '../utils/eui/data-grid.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiTextTruncate } from '../utils/eui/styles.generated.ts';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiNotificationBadge from './eui-notification-badge.gts';

import type EuiI18n from '../services/eui-i18n.ts';
import type { EuiIconSignature } from './eui-icon.gts';
import type { EuiCss } from '../utils/eui/styles.ts';

const TEXT_TRUNCATE = euiTextTruncate();

export interface EuiDataGridToolbarControlSignature {
  Element: HTMLButtonElement | HTMLAnchorElement;
  Args: {
    /** Icon before the label. */
    iconType?: EuiIconSignature['Args']['type'];
    /** Count shown in a badge after the label (e.g. `5` or `'3/10'`). */
    badgeContent?: string | number;
    /** Disables the button. */
    isDisabled?: boolean;
    /** Extra styles composed last into the button class. */
    css?: EuiCss;
  };
  Blocks: {
    /** The control's label. */
    default: [];
  };
}

/**
 * Text button with an optional count badge, used by the data grid toolbar
 * (columns, sort fields) and available for custom toolbar controls.
 */
export default class EuiDataGridToolbarControl extends Component<EuiDataGridToolbarControlSignature> {
  @service declare euiI18n: EuiI18n;

  @cached
  get styles() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiDataGridToolbarControlStyles);
    return {
      interactive: [styles.interactive, this.args.css],
      badge: styles.badge,
      textClass: `euiDataGridToolbarControl__text eui-textTruncate ${euiClass(context, TEXT_TRUNCATE)}`
    };
  }

  get hasBadge(): boolean {
    return Boolean(this.args.badgeContent);
  }

  get badgeAriaLabel(): string {
    const content = this.args.badgeContent;
    // `5/10` reads better as "5 out of 10"
    const count =
      typeof content === 'string' ? content.replaceAll('/', ' out of ') : content;
    const label = this.euiI18n.lookupToken(
      'euiDataGridToolbarControl.badgeAriaLabel',
      'Active: {count}',
      { count }
    );
    // punctuation helps add pauses for screen readers
    return `- ${label}`;
  }

  <template>
    <EuiButtonEmpty
      class="euiDataGridToolbarControl"
      @size="xs"
      @color="text"
      @iconType={{@iconType}}
      @isDisabled={{@isDisabled}}
      @css={{this.styles.interactive}}
      ...attributes
    >
      <span class={{this.styles.textClass}}>{{yield}}</span>
      {{#if this.hasBadge}}
        {{! template-lint-disable no-redundant-role }}
        <EuiNotificationBadge
          class="euiDataGridToolbarControl__badge"
          @css={{this.styles.badge}}
          @color="subdued"
          aria-label={{this.badgeAriaLabel}}
          role="marquee"
        >{{@badgeContent}}</EuiNotificationBadge>
      {{/if}}
    </EuiButtonEmpty>
  </template>
}
