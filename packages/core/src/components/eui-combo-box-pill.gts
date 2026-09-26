import { hash } from '@ember/helper';
import { fn } from '@ember/helper';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';

import classNames from '../helpers/class-names.ts';
import EuiBadge from './eui-badge.gts';

import type { EuiBadgeSignature } from './eui-badge';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A selected option in EuiComboBox's input, as a badge or plain text. */
export interface EuiComboBoxPill {
  Element: EuiBadgeSignature['Element'];
  Args: {
    /** Renders the selection as plain text instead of a badge. */
    asPlainText?: boolean;

    /** Shows an "x" button calling this with `@option`, to remove it. */
    onClose?: (option: unknown) => void;

    /** Badge color, see `EuiBadge`. */
    color?: EuiBadgeSignature['Args']['color'];

    /** `data-selected-index` of the remove button, for keyboard navigation. */
    dataSelectedIconIndex?: number;

    /** Accessible label of the remove button, e.g. "Remove Apple from selection". */
    iconOnClickAriaLabel?: string;

    /** The selected option this pill shows. */
    option?: unknown;
  };
  Blocks: {
    /** The option's text. */
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
