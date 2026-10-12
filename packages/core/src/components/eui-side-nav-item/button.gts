import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import classNames from '../../helpers/class-names.ts';
import EuiIcon from '../eui-icon.gts';
import EuiInnerText from '../eui-inner-text.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * @private The content of an EuiSideNav item's button or link: icon,
 * label and the accordion caret (upstream `euiSideNavItemButton__content`).
 */
export interface EuiSideNavItemButtonSignature {
  Element: HTMLButtonElement;
  Args: {
    /** Icon before the text. */
    icon?: string;
    /** Shows the accordion caret, for section items with children. */
    caret?: boolean;
    /** Points the caret down (open) instead of right (closed). */
    isOpen?: boolean;
    /** Truncates long text, with the full text as `title`. Defaults to `true`. */
    truncate?: boolean;
    /** Extra classes for the icon. */
    buttonIconClasses?: string;
    /** Class of the content span (upstream styles). */
    contentClass?: string;
    /** Class of the label span (upstream styles). */
    labelClass?: string;
  };
  Blocks: {
    /** The text. */
    default: [];
  };
}

const EuiSideNavItemButton: TemplateOnlyComponent<EuiSideNavItemButtonSignature> =
  <template>
    <span class="euiSideNavItemButton__content {{@contentClass}}">
      {{#if @icon}}
        <EuiIcon
          @type={{@icon}}
          @size="m"
          class={{classNames "euiSideNavItemButton__icon" @buttonIconClasses}}
        />
      {{/if}}

      <EuiInnerText as |setRef innerText|>
        <span
          class="euiSideNavItemButton__label {{@labelClass}}"
          {{didInsert setRef}}
          title={{if @truncate innerText}}
        >
          {{yield}}
        </span>
      </EuiInnerText>
      {{#if @caret}}
        <EuiIcon
          class="euiSideNavItemButton__caret"
          @type={{if @isOpen "chevronSingleDown" "chevronSingleRight"}}
          @size="s"
        />
      {{/if}}
    </span>
  </template>;

export default EuiSideNavItemButton;
