import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import EuiText from '../eui-text.gts';
import { comboBoxMessageClass } from './no-matches-message.gts';

/** @private Shown in EuiComboBox's options list. */
interface Signature {
  Element: HTMLDivElement;
  Args: {
    /** EuiComboBox's `@searchMessage`. */
    searchMessage?: string;
  };
}

export default class SearchMessageComponent extends Component<Signature> {
  @cached
  get classes(): string {
    return comboBoxMessageClass(this);
  }

  <template>
    {{#if @searchMessage}}
      <div class="euiComboBoxOptionsList {{this.classes}}" ...attributes>
        <EuiText @size="xs" class="euiComboBoxOptionsList__empty">
          <p>
            {{@searchMessage}}
          </p>
        </EuiText>
      </div>
    {{/if}}
  </template>
}
