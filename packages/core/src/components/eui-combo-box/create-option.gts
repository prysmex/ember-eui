import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { get } from '@ember/object';
import { inject as service } from '@ember/service';
import { htmlSafe, isHTMLSafe } from '@ember/template';

import style from 'ember-style-modifier/modifiers/style';

import EuiBadge from '../eui-badge.gts';
import EuiText from '../eui-text.gts';

import type EuiI18n from '../../services/eui-i18n';

function unwrap(input: string) {
  if (isHTMLSafe(input)) {
    return input.toString();
  }

  return input;
}

export interface EuiComboBoxCreateOptionSignature {
  Args: {
    customOptionText?: string;
    select: { searchText: string };
    onCreateOption: () => void;
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
      let str = unwrap(this.args.customOptionText);

      let context = {
        searchText: this.args.select.searchText
      };

      return htmlSafe(
        str.replace(this._regex, (_s, p1, p2) => {
          return get(context, p1 || p2);
        })
      );
    } else {
      let str = unwrap(
        this.euiI18n.lookupToken(
          'euiComboBox.customOptionText',
          'Add&nbsp;<strong>{searchText}</strong>&nbsp;as custom option',
          {
            searchText: this.args.select.searchText
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
      {{on "click" @onCreateOption}}
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
