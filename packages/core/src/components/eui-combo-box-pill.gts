import { hash } from '@ember/helper';
import { fn } from '@ember/helper';

import optional from 'ember-composable-helpers/helpers/optional';

import classNames from '../helpers/class-names';
import EuiBadge from './eui-badge.gts';

import type { EuiBadgeSignature } from './eui-badge.gts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiComboBoxPill {
  Element: EuiBadgeSignature['Element'];
  Args: {
    /**
     * The color of the pill
     */
    asPlainText?: boolean;

    onClose?: (option: unknown) => void;

    color?: EuiBadgeSignature['Args']['color'];

    dataSelectedIconIndex?: number;

    iconOnClickAriaLabel?: string;

    option?: unknown;
  };
  Blocks: {
    default: [];
  };
}

const EuiComboBoxPill: TemplateOnlyComponent<EuiComboBoxPill> = <template>
  {{#let
    (classNames
      "euiComboBoxPill" (if @asPlainText "euiComboBoxPill--plainText")
    )
    (optional @onClose)
    as |classes onClose|
  }}
    {{#if @onClose}}
      <EuiBadge
        class={{classes}}
        @closeButtonProps={{hash
          tabIndex=-1
          dataSelectedIconIndex=@dataSelectedIconIndex
        }}
        @color={{@color}}
        @iconOnClick={{fn onClose @option}}
        @iconOnClickAriaLabel={{@iconOnClickAriaLabel}}
        @iconSide="right"
        @iconType="cross"
        ...attributes
      >
        {{yield}}
      </EuiBadge>
    {{else if @asPlainText}}
      <span class={{classes}}>
        {{yield}}
      </span>
    {{else}}
      <EuiBadge
        class={{classes}}
        @color={{@color}}
        @closeButtonProps={{hash dataSelectedIconIndex=@dataSelectedIconIndex}}
        ...attributes
      >
        {{yield}}
      </EuiBadge>
    {{/if}}
  {{/let}}
</template>;

export default EuiComboBoxPill;
