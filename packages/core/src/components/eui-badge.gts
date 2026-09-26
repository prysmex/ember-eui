import { hash } from '@ember/helper';
import { on } from '@ember/modifier';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { and, not, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import inlineStyles from '../helpers/inline-styles.ts';
import simpleStyle from '../modifiers/simple-style.ts';
import EuiIcon from './eui-icon.gts';

import type {
  colorMapping,
  EuiBadgeColorType
} from '../utils/css-mappings/eui-badge.ts';
import type { EuiIconSignature } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiBadgeSignature {
  Element: HTMLButtonElement | HTMLAnchorElement | HTMLSpanElement;
  Args: {
    /**
     * `'default'`, `'hollow'`, `'primary'`, `'success'`, `'accent'`,
     * `'warning'`, `'danger'` or any hex color (`'#DA8B45'`); the text color
     * is picked for contrast. Defaults to `'default'`.
     */
    color?: keyof typeof colorMapping | EuiBadgeColorType | string;
    /**
     * Icon shown in the badge, anything `EuiIcon`'s `@type` accepts.
     */
    iconType?: EuiIconSignature['Args']['type'];
    /**
     * Side of the text the icon is on. Defaults to `'left'`.
     */
    iconSide?: 'left' | 'right';
    /**
     * Makes the icon a separate button calling this function, e.g. an "x" to
     * remove the badge. Requires `@iconType` and `@iconOnClickAriaLabel`.
     */
    iconOnClick?: () => void;
    /**
     * Accessible label (and hover title) of the `@iconOnClick` button.
     */
    iconOnClickAriaLabel?: string;
    /**
     * @deprecated Has no effect, see `EuiIcon`.
     */
    iconUseSvg?: boolean;
    /**
     * Disables the badge's buttons and links and greys it out.
     */
    isDisabled?: boolean;
    /**
     * Makes the badge (or its text, when it has an `@iconType`) a button
     * calling this function.
     */
    onClick?: () => void;
    /**
     * Accessible label of the `@onClick` button, when the text alone does not
     * describe the action.
     */
    onClickAriaLabel?: string;
    /**
     * Makes the badge (or its text, when it has an `@iconType`) a link.
     */
    href?: string;
    /**
     * `target` of the `@href` link, e.g. `'_blank'` (only without
     * `@iconType`).
     */
    target?: string;
    /**
     * Extra props for the `@iconOnClick` button.
     */
    closeButtonProps?: {
      tabIndex?: number;
      dataSelectedIconIndex?: number;
      iconClasses?: string;
    };
  };
  Blocks: {
    /** The badge's text. */
    default: [];
  };
}

const EuiBadge: TemplateOnlyComponent<EuiBadgeSignature> = <template>
  {{#if (and (or @onClick @href) (not @iconType))}}
    {{#if @onClick}}
      <button
        type="button"
        class={{classNames
          "euiBadge-isClickable"
          (if @isDisabled "euiBadge-isDisabled")
          componentName="EuiBadge"
          color=(argOrDefault @color "default")
        }}
        aria-label={{@onClickAriaLabel}}
        disabled={{@isDisabled}}
        ...attributes
        {{simpleStyle
          (inlineStyles
            componentName="EuiBadge"
            componentArgs=(hash badgeColor=(argOrDefault @color "default"))
          )
        }}
        {{on "click" (optional @onClick)}}
      >
        <span class="euiBadge__content">
          <span class="euiBadge__text">
            {{yield}}
          </span>
        </span>
      </button>
    {{else}}
      <a
        class={{classNames
          "euiBadge-isClickable"
          (if @isDisabled "euiBadge-isDisabled")
          componentName="EuiBadge"
          color=(argOrDefault @color "default")
        }}
        target={{@target}}
        href={{@href}}
        aria-label={{if @onClick @onClickAriaLabel}}
        disabled={{@isDisabled}}
        ...attributes
        {{simpleStyle
          (inlineStyles
            componentName="EuiBadge"
            componentArgs=(hash badgeColor=(argOrDefault @color "default"))
          )
        }}
      >
        <span class="euiBadge__content">
          <span class="euiBadge__text">
            {{yield}}
          </span>
        </span>
      </a>
    {{/if}}
  {{else if @iconType}}
    <span
      class={{classNames
        (if @isDisabled "euiBadge-isDisabled")
        componentName="EuiBadge"
        iconSide=(argOrDefault @iconSide "left")
        color=(argOrDefault @color "default")
      }}
      ...attributes
      {{simpleStyle
        (inlineStyles
          componentName="EuiBadge"
          componentArgs=(hash badgeColor=(argOrDefault @color "default"))
        )
      }}
    >
      <span class="euiBadge__content">
        {{#if (has-block)}}
          {{#if @onClick}}
            <button
              class="euiBadge__childButton"
              type="button"
              disabled={{@isDisabled}}
              {{on "click" (optional @onClick)}}
            >
              {{yield}}
            </button>
          {{else if @href}}
            <a
              class="euiBadge__childButton"
              href={{@href}}
              disabled={{@isDisabled}}
            >
              {{yield}}
            </a>
          {{else}}
            <span class="euiBadge__text">
              {{yield}}
            </span>
          {{/if}}
        {{/if}}
        {{#if @iconOnClick}}
          {{! template-lint-disable }}
          <button
            type="button"
            class="euiBadge__iconButton"
            aria-label={{@iconOnClickAriaLabel}}
            disabled={{@isDisabled}}
            title={{@iconOnClickAriaLabel}}
            tabindex={{@closeButtonProps.tabIndex}}
            data-selected-index={{@closeButtonProps.dataSelectedIconIndex}}
            {{on "click" (optional @iconOnClick)}}
          >
            <EuiIcon
              @color="inherit"
              @iconClasses={{classNames
                "euiBadge__icon"
                @closeButtonProps.iconClasses
              }}
              @type={{@iconType}}
              @useSvg={{@iconUseSvg}}
              @size={{if (has-block) "s" "m"}}
            />
          </button>
          {{! tempalte-lint-enable}}
        {{else}}
          <EuiIcon
            @color="inherit"
            @type={{@iconType}}
            @useSvg={{@iconUseSvg}}
            @size={{if (has-block) "s" "m"}}
            @iconClasses="euiBadge__icon"
          />
        {{/if}}
      </span>
    </span>
  {{else}}
    <span
      class={{classNames
        (if @isDisabled "euiBadge-isDisabled")
        componentName="EuiBadge"
        iconSide=(argOrDefault @iconSide "left")
        color=(argOrDefault @color "default")
      }}
      ...attributes
      {{simpleStyle
        (inlineStyles
          componentName="EuiBadge"
          componentArgs=(hash badgeColor=(argOrDefault @color "default"))
        )
      }}
    >
      <span class="euiBadge__content">
        <span class="euiBadge__text">
          {{yield}}
        </span>
      </span>
    </span>
  {{/if}}
</template>;

export default EuiBadge;
