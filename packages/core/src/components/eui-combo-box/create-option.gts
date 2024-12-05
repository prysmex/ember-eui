import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { get } from '@ember/object';
import { inject as service } from '@ember/service';
import { htmlSafe, isHTMLSafe } from '@ember/template';

import EuiBadge from '../eui-badge.gts';
import EuiText from '../eui-text.gts';

import type EuiI18n from '@ember-eui/core/services/eui-i18n';

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
  };
}

export default class EuiAccordionAccordionComponent extends Component<EuiComboBoxCreateOptionSignature> {
  @service declare euiI18n: EuiI18n;

  _regex = /\{\s*(.*?)\s*\}/g;

  get formattedString(): ReturnType<typeof htmlSafe> {
    let str = unwrap(
      this.args.customOptionText ||
        this.euiI18n.lookupToken(
          'euiComboBox.customOptionText',
          'Add&nbsp;<strong>{searchText}</strong>&nbsp;as custom option'
        )
    );

    let context = {
      searchText: this.args.select.searchText
    };

    return htmlSafe(
      str.replace(this._regex, (_s, p1, p2) => {
        return get(context, p1 || p2);
      })
    );
  }

  <template>
    <div
      role="button"
      class="euiComboBoxOptionsList__rowWrap"
      {{on "click" @onCreateOption}}
    >
      <EuiText class="euiComboBoxOptionsList__empty" @size="xs">
        <div class="euiComboBoxOption__contentWrapper">
          <p class="euiComboBoxOption__emptyStateText">
            {{this.formattedString}}
          </p>
          <EuiBadge
            @iconType="returnKey"
            class="euiComboBoxOption__enterBadge"
            @color="hollow"
          />
        </div>
      </EuiText>
    </div>
  </template>
}
