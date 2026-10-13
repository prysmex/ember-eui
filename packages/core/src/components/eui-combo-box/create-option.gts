import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { get } from '@ember/object';
import { service } from '@ember/service';
import { htmlSafe, isHTMLSafe } from '@ember/template';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { comboBoxBoxReset } from '../../utils/eui/combo-box.ts';
import {
  euiComboBoxOptionListStyles,
  euiListItemLayoutStyles
} from '../../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import EuiBadge from '../eui-badge.gts';
import EuiText from '../eui-text.gts';

import type EuiI18n from '../../services/eui-i18n';

/** The typed text is user input: escape it before building HTML with it. */
function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function unwrap(input: string) {
  if (isHTMLSafe(input)) {
    return input.toString();
  }

  return input;
}

/** @private The "add as custom option" row of EuiComboBox. */
export interface EuiComboBoxCreateOptionSignature {
  Args: {
    /** EuiComboBox's `@customOptionText`. */
    customOptionText?: string;
    /** ember-power-select's API, for the search text. */
    select: { searchText: string };
    /** Adds the typed text as an option. */
    onCreateOption: () => void;
    /** Rendered above matching options (`@alwaysShowCreateOption`). */
    alwaysShow?: boolean;
    /** EuiComboBox's `@delimiter`. */
    delimiter?: string;
  };
}

export default class EuiComboBoxCreateOptionComponent extends Component<EuiComboBoxCreateOptionSignature> {
  @service declare euiI18n: EuiI18n;

  /** The list keeps the focus in the input (upstream). */
  keepFocus = (event: MouseEvent) => event.preventDefault();

  _regex = /\{\s*(.*?)\s*\}/g;

  get createLabel() {
    return this.euiI18n.lookupToken('euiComboBox.createLabel', 'Create');
  }

  /**
   * Upstream: text with the delimiter will be split into several options,
   * so the message says so instead of offering it as one.
   */
  get hasDelimiter(): boolean {
    const { delimiter, select } = this.args;

    return Boolean(delimiter && (select.searchText ?? '').includes(delimiter));
  }

  get delimiterMessage(): ReturnType<typeof htmlSafe> {
    return htmlSafe(
      unwrap(
        this.euiI18n.lookupToken(
          'euiComboBoxOptionsList.delimiterMessage',
          'Add each item separated by {delimiter}',
          {
            delimiter: `<strong>${escapeHtml(this.args.delimiter ?? '')}</strong>`
          }
        )
      )
    );
  }

  get formattedString(): ReturnType<typeof htmlSafe> {
    if (
      this.args.customOptionText &&
      typeof this.args.customOptionText === 'string'
    ) {
      const str = unwrap(this.args.customOptionText);

      const searchText = escapeHtml(this.args.select.searchText ?? '');
      // `{searchText}` as typed; upstream's `{searchValue}` in bold
      const context = {
        searchText,
        searchValue: `<strong>${searchText}</strong>`
      };

      return htmlSafe(
        str.replace(this._regex, (_s, p1, p2) => {
          return get(context, p1 || p2);
        })
      );
    } else {
      const str = unwrap(
        this.euiI18n.lookupToken(
          'euiComboBox.customOptionText',
          'Add&nbsp;<strong>{searchText}</strong>&nbsp;as custom option',
          {
            searchText: escapeHtml(this.args.select.searchText ?? '')
          }
        )
      );

      return htmlSafe(str);
    }
  }

  /**
   * Upstream empty state with the "add" text and the enter badge. With
   * `@alwaysShow` it sits below the options as a row (start aligned, option
   * padding and hover) instead of the centered empty state.
   */
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiComboBoxOptionListStyles);
    const layout = useEuiBorealisStyles(context, euiListItemLayoutStyles);
    const size = context.upstream.euiTheme.size;

    return euiClass(
      context,
      comboBoxBoxReset,
      styles.euiComboBoxOptionList,
      styles.euiComboBoxOptionsList__empty,
      { cursor: 'pointer' },
      this.args.alwaysShow && [
        {
          paddingBlock: size.xs,
          paddingInline: size.s,
          textAlign: 'start',
          borderRadius: context.upstream.euiTheme.border.radius.control
        },
        layout.isInteractive
      ]
    );
  }

  <template>
    {{! template-lint-disable no-invalid-interactive }}
    <div
      class="euiComboBoxOptionsList euiComboBoxOptionsList__rowWrap
        {{this.classes}}"
      data-test-subj="comboBoxCreateOption"
      {{on "mousedown" this.keepFocus}}
      {{on "pointerup" @onCreateOption}}
    >
      <EuiText @size="xs" class="euiComboBoxOptionsList__empty">
        <div class="euiComboBoxOption__contentWrapper">
          {{#if this.hasDelimiter}}
            <p class="euiComboBoxOption__emptyStateText">
              {{this.delimiterMessage}}
            </p>
            <EuiBadge
              class="euiComboBoxOption__enterBadge"
              @color="hollow"
              @iconType="return"
              aria-hidden="true"
            />
          {{else}}
            <p class="euiComboBoxOption__emptyStateText">
              {{this.formattedString}}
            </p>

            <EuiBadge
              class="euiComboBoxOption__enterBadge"
              @color="hollow"
              @iconType={{unless @alwaysShow "return"}}
              aria-hidden={{unless @alwaysShow "true"}}
            >
              {{#if @alwaysShow}}
                {{this.createLabel}}
              {{/if}}
            </EuiBadge>
          {{/if}}
        </div>
      </EuiText>
    </div>
  </template>
}
