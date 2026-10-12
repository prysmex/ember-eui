import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { fn } from '@ember/helper';
import { service } from '@ember/service';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiComboBoxPillStyles,
  euiFontSize,
  euiFormVariables
} from '../utils/eui/styles.generated.ts';
import { comboBoxOptionLabel } from '../utils/eui/combo-box.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiBadge from './eui-badge.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiCss } from '../utils/eui/styles.ts';
import type { EuiBadgeSignature } from './eui-badge';

/** A selected option in EuiComboBox's input, as a badge or plain text. */
export interface EuiComboBoxPill {
  Element: EuiBadgeSignature['Element'];
  Args: {
    /** Renders the selection as plain text instead of a badge. */
    asPlainText?: boolean;

    /** Shows an "x" button calling this with `@option`, to remove it. */
    onClose?: (option: unknown) => void;

    /** Badge color, see `EuiBadge`. Defaults to `'hollow'` (upstream). */
    color?: EuiBadgeSignature['Args']['color'];

    /** `data-selected-index` of the remove button, for keyboard navigation. */
    dataSelectedIconIndex?: number;

    /**
     * Accessible label of the remove button. Defaults to "Remove {label}
     * from selection in this group" when the option has a text (a string,
     * or its `@searchField` / `label`).
     */
    iconOnClickAriaLabel?: string;

    /** The selected option this pill shows. */
    option?: unknown;

    /** Key of object options holding their text (EuiComboBox's `@searchField`). */
    searchField?: string;
  };
  Blocks: {
    /** The option's text. */
    default: [];
  };
}

export default class EuiComboBoxPillComponent extends Component<EuiComboBoxPill> {
  @service declare euiI18n: EuiI18n;

  get color(): EuiBadgeSignature['Args']['color'] {
    return this.args.color ?? 'hollow';
  }

  get removeLabel(): string | undefined {
    if (this.args.iconOnClickAriaLabel) return this.args.iconOnClickAriaLabel;

    const label = comboBoxOptionLabel(this.args.option, this.args.searchField);

    if (!label) return undefined;

    return this.euiI18n.lookupToken(
      'euiComboBoxPill.removeSelection',
      'Remove {children} from selection in this group',
      { children: label }
    );
  }

  /**
   * Upstream `euiComboBoxPill`, the `css` EuiComboBoxPill passes to EuiBadge:
   * pill height, line height and a max width that leaves room for the input.
   */
  @cached
  get pillCss(): EuiCss {
    return useEuiBorealisStyles(getEuiThemeContext(this), euiComboBoxPillStyles)
      .euiComboBoxPill;
  }

  /**
   * EuiBadge has no `@css` yet, so the pill styles go in an extra class with
   * doubled specificity (`&&`), which wins over the badge's own class
   * whatever the insertion order. Switch to `@css={{this.pillCss}}` once
   * EuiBadge takes it.
   */
  @cached
  get pillClass(): string {
    return euiClass(getEuiThemeContext(this), { '&&': this.pillCss });
  }

  /**
   * Plain text single selection: upstream shows it as the input's text, so
   * it uses the form control text (size, color) and truncates.
   */
  @cached
  get plainTextClass(): string {
    const context = getEuiThemeContext(this);
    const form = useEuiBorealisStyles(context, euiFormVariables);

    return euiClass(context, {
      display: 'block',
      minInlineSize: 0,
      maxInlineSize: '100%',
      fontFamily: context.upstream.euiTheme.font.family,
      fontSize: euiFontSize(context.upstream, 's', undefined).fontSize,
      lineHeight: context.upstream.euiTheme.size.l,
      color: form.textColor,
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      whiteSpace: 'nowrap'
    });
  }

  <template>
    {{#if @onClose}}
      <EuiBadge
        class="euiComboBoxPill {{this.pillClass}}"
        data-test-subj="euiComboBoxPill"
        @closeButtonProps={{hash
          tabIndex=-1
          dataSelectedIconIndex=@dataSelectedIconIndex
        }}
        @color={{this.color}}
        @iconOnClick={{fn (optional @onClose) @option}}
        @iconOnClickAriaLabel={{this.removeLabel}}
        @iconSide="right"
        @iconType="cross"
        ...attributes
      >
        {{yield}}
      </EuiBadge>
    {{else if @asPlainText}}
      <span
        class="euiComboBoxPill euiComboBoxPill--plainText {{this.plainTextClass}}"
      >
        {{yield}}
      </span>
    {{else}}
      <EuiBadge
        class="euiComboBoxPill {{this.pillClass}}"
        data-test-subj="euiComboBoxPill"
        @color={{this.color}}
        @closeButtonProps={{hash dataSelectedIconIndex=@dataSelectedIconIndex}}
        ...attributes
      >
        {{yield}}
      </EuiBadge>
    {{/if}}
  </template>
}
