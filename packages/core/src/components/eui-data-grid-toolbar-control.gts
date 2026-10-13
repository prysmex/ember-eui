import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiDataGridToolbarControlStyles } from '../utils/eui/data-grid.ts';
import euiApplyProps, { propsClasses } from '../-private/eui-apply-props.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiTextTruncate } from '../utils/eui/styles.generated.ts';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiNotificationBadge from './eui-notification-badge.gts';

import type EuiI18n from '../services/eui-i18n.ts';
import type { EuiIconSignature } from './eui-icon.gts';
import type { EuiButtonEmptySignature } from './eui-button-empty';
import type { EuiElementProps } from '../-private/eui-apply-props.ts';
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
    /** EuiButtonEmpty color. Defaults to `'text'`. */
    color?: EuiButtonEmptySignature['Args']['color'];
    /** `class`, `css` and attributes of the content element, see `EuiButtonEmpty`. */
    contentProps?: EuiButtonEmptySignature['Args']['contentProps'];
    /**
     * `class`/`className`, `css` and attributes of the label element, which
     * always has `euiDataGridToolbarControl__text` and truncates.
     */
    textProps?: EuiElementProps;
    /** Pulls the button to an edge, see `EuiButtonEmpty`. */
    flush?: EuiButtonEmptySignature['Args']['flush'];
    /** Beta: `aria-disabled` instead of `disabled`, see `EuiButtonEmpty`. */
    hasAriaDisabled?: boolean;
    /** Side of the icon, see `EuiButtonEmpty`. */
    iconSide?: EuiButtonEmptySignature['Args']['iconSide'];
    /** Size of the icon, see `EuiButtonEmpty`. */
    iconSize?: EuiButtonEmptySignature['Args']['iconSize'];
    /** Shows a spinner and disables the button. */
    isLoading?: boolean;
    /** Sets `aria-pressed`, see `EuiButtonEmpty`. */
    isSelected?: boolean;
    /** `'xs'`, `'s'` or `'m'`. Defaults to `'xs'`. */
    size?: EuiButtonEmptySignature['Args']['size'];
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
      textClass: `euiDataGridToolbarControl__text eui-textTruncate ${propsClasses(this.args.textProps)} ${euiClass(context, TEXT_TRUNCATE, this.args.textProps?.css)}`
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
      @size={{if @size @size "xs"}}
      @color={{if @color @color "text"}}
      @contentProps={{@contentProps}}
      @flush={{@flush}}
      @hasAriaDisabled={{@hasAriaDisabled}}
      @iconSide={{@iconSide}}
      @iconSize={{@iconSize}}
      @isLoading={{@isLoading}}
      @isSelected={{@isSelected}}
      @iconType={{@iconType}}
      @isDisabled={{@isDisabled}}
      @css={{this.styles.interactive}}
      ...attributes
    >
      <span class={{this.styles.textClass}} {{euiApplyProps @textProps}}>{{yield}}</span>
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
