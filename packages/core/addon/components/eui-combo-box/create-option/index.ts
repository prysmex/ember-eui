import Component from '@glimmer/component';
import { isHTMLSafe, htmlSafe } from '@ember/string';
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
}
