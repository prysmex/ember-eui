import classNames from '../../helpers/class-names';
import argOrDefault from '../../helpers/arg-or-default';
import EuiInnerText from '../eui-inner-text.gts';
import EuiIcon from '../eui-icon.gts';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiSideNavItemButtonSignature {
  Element: HTMLButtonElement;
  Args: {
    icon?: string;
    caret?: boolean;
    truncate?: boolean;
    buttonIconClasses?: string;
  };
  Blocks: {
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
