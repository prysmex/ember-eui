/**
 * The import screen's value map (v0.4 10, "Built-in column options"): for
 * a select or checkbox target, the column's distinct texts (up to 50) and
 * what each becomes: as in the file (the type reads it), an option (or
 * checked / unchecked), or no value. Prefilled by `suggestValueMap`.
 */
import Component from '@glimmer/component';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';

import EuiSelect from '@ember-eui/core/components/eui-select';

import { choiceOf } from './model.ts';

import type { SheetMessages } from '../../core/index.ts';
import type { ValueChoice } from './model.ts';

interface ImportValueMapSignature {
  Args: {
    /** The column's name, for the caption. */
    name: string;
    texts: string[];
    choices: ValueChoice[];
    map: Readonly<Record<string, unknown>>;
    disabled?: boolean;
    messages: SheetMessages;
    /** A text's new entry: the choice's `mapped` (`undefined`: none). */
    onChange: (text: string, mapped: unknown) => void;
  };
}

export default class ImportValueMap extends Component<ImportValueMapSignature> {
  get options(): Array<{ value: string; text: string }> {
    return this.args.choices.map((choice) => ({
      value: choice.value,
      text: choice.text
    }));
  }

  valueOf = (text: string): string =>
    choiceOf(this.args.choices, this.args.map[text]);

  shown = (text: string): string =>
    text === '' ? this.args.messages.importValueEmpty() : text;

  onChoice = (text: string, event: Event): void => {
    const value = (event.target as HTMLSelectElement).value;
    const choice = this.args.choices.find((c) => c.value === value);
    this.args.onChange(text, choice?.mapped);
  };

  <template>
    <table
      class="euiSheetImport__table euiSheetImport__valueMap"
      data-test-subj="euiSheetImportValueMap"
    >
      <caption>{{@messages.importValueMapFor @name}}</caption>
      <thead>
        <tr>
          <th scope="col">{{@messages.importValueInFile}}</th>
          <th scope="col">{{@messages.importValueBecomes}}</th>
        </tr>
      </thead>
      <tbody>
        {{#each @texts as |text|}}
          <tr data-test-subj="euiSheetImportValueRow">
            <th scope="row">{{this.shown text}}</th>
            <td>
              <EuiSelect
                @compressed={{true}}
                @options={{this.options}}
                @value={{this.valueOf text}}
                @disabled={{@disabled}}
                aria-label={{this.shown text}}
                data-test-subj="euiSheetImportValue"
                {{on "change" (fn this.onChoice text)}}
              />
            </td>
          </tr>
        {{/each}}
      </tbody>
    </table>
  </template>
}
