import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { get } from '@ember/object';
import { service } from '@ember/service';
import { htmlSafe, isHTMLSafe } from '@ember/template';

import style from 'ember-style-modifier/modifiers/style';

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
  };
}

export default class EuiComboBoxCreateOptionComponent extends Component<EuiComboBoxCreateOptionSignature> {
  @service declare euiI18n: EuiI18n;

  _regex = /\{\s*(.*?)\s*\}/g;

  get createLabel() {
    return this.euiI18n.lookupToken('euiComboBox.createLabel', 'Create');
  }

  get formattedString(): ReturnType<typeof htmlSafe> {
    if (
      this.args.customOptionText &&
      typeof this.args.customOptionText === 'string'
    ) {
      const str = unwrap(this.args.customOptionText);

      const context = {
        searchText: escapeHtml(this.args.select.searchText ?? '')
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

  get extraStyling() {
    if (this.args.alwaysShow) {
      return {
        container: {
          padding: '4px 12px',
          cursor: 'pointer'
        },
        content: {
          padding: '0px'
        }
      };
    }

    return {
      container: {
        cursor: 'pointer'
      }
    };
  }

  <template>
    <div
      class="euiComboBoxOptionsList__rowWrap"
      {{style this.extraStyling.container}}
      {{!template-lint-disable no-invalid-interactive}}
      {{on "pointerup" @onCreateOption}}
    >
      <EuiText
        class="euiComboBoxOptionsList__empty"
        @size="xs"
        {{style this.extraStyling.content}}
      >
        <div class="euiComboBoxOption__contentWrapper">
          <p class="euiComboBoxOption__emptyStateText">
            {{this.formattedString}}
          </p>

          <EuiBadge
            class="euiComboBoxOption__enterBadge"
            @color="hollow"
            @iconType={{unless @alwaysShow "returnKey"}}
          >
            {{#if @alwaysShow}}
              {{this.createLabel}}
            {{/if}}
          </EuiBadge>
        </div>
      </EuiText>
    </div>
  </template>
}
