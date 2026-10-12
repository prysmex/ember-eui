import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { comboBoxBoxReset } from '../../utils/eui/combo-box.ts';
import { euiComboBoxOptionListStyles } from '../../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import EuiText from '../eui-text.gts';

/**
 * Upstream empty state of the options list: `.euiComboBoxOptionsList`
 * around an xs `EuiText.euiComboBoxOptionsList__empty`. The empty state
 * styles (padding, centered, word breaks) are composed into the wrapper so
 * EuiText keeps a single Emotion class.
 */
export function comboBoxMessageClass(component: object): string {
  const context = getEuiThemeContext(component);
  const styles = useEuiBorealisStyles(context, euiComboBoxOptionListStyles);

  return euiClass(
    context,
    comboBoxBoxReset,
    styles.euiComboBoxOptionList,
    styles.euiComboBoxOptionsList__empty
  );
}

/** @private Shown in EuiComboBox's options list. */
interface Signature {
  Element: HTMLDivElement;
  Args: {
    /** EuiComboBox's `@noMatchesMessage`. */
    noMatchesMessage?: string;
  };
}

export default class NoMatchesMessageComponent extends Component<Signature> {
  @cached
  get classes(): string {
    return comboBoxMessageClass(this);
  }

  <template>
    {{#if @noMatchesMessage}}
      <div class="euiComboBoxOptionsList {{this.classes}}" ...attributes>
        <EuiText @size="xs" class="euiComboBoxOptionsList__empty">
          <p>
            {{@noMatchesMessage}}
          </p>
        </EuiText>
      </div>
    {{/if}}
  </template>
}
