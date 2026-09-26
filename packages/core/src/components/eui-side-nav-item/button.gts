import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import argOrDefault from '../../helpers/arg-or-default.ts';
import classNames from '../../helpers/class-names.ts';
import EuiIcon from '../eui-icon.gts';
import EuiInnerText from '../eui-inner-text.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private The button or link of an EuiSideNav item. */
export interface EuiSideNavItemButtonSignature {
  Element: HTMLButtonElement;
  Args: {
    /** Icon before the text. */
    icon?: string;
    /** Shows an arrow, for items with children. */
    caret?: boolean;
    /** Truncates long text. Defaults to `true`. */
    truncate?: boolean;
    /** Extra classes for the icon. */
    buttonIconClasses?: string;
  };
  Blocks: {
    /** The text. */
    default: [];
  };
}

const EuiSideNavItemButton: TemplateOnlyComponent<EuiSideNavItemButtonSignature> =
  <template>
    {{#let (argOrDefault @truncate true) as |truncate|}}
      <span class="euiSideNavItemButton__content">
        {{#if @icon}}
          <EuiIcon
            @type={{@icon}}
            @size="m"
            class={{classNames "euiSideNavItemButton__icon" @buttonIconClasses}}
          />
        {{/if}}

        <EuiInnerText as |setRef innerText|>
          <span
            class={{classNames
              "euiSideNavItemButton__label"
              (if truncate "euiSideNavItemButton__label--truncated")
            }}
            {{didInsert setRef}}
            title={{if truncate innerText}}
          >
            {{yield}}
          </span>
        </EuiInnerText>
        {{#if @caret}}
          <EuiIcon @type="arrowDown" @color="subdued" @size="s" />
        {{/if}}
      </span>
    {{/let}}
  </template>;

export default EuiSideNavItemButton;
