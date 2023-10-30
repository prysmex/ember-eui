import Component from '@glimmer/component';
import { isHTMLSafe, htmlSafe } from '@ember/template';
import { get } from '@ember/object';

type EuiComboBoxCreateOptionArgs = {
  customOptionText?: string;
  select: { searchText: string };
};

function unwrap(input: string) {
  if (isHTMLSafe(input)) {
    return input.toString();
  }

  return input;
}

export default class EuiAccordionAccordionComponent extends Component<EuiComboBoxCreateOptionArgs> {
  _regex = /\{\s*(.*?)\s*\}/g;

  get formattedString(): ReturnType<typeof htmlSafe> {
    let str = unwrap(
      this.args.customOptionText ||
        'Add&nbsp;<strong>{searchText}</strong>&nbsp;as custom option'
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
    {{! @glint-nocheck: not typesafe yet }}
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
