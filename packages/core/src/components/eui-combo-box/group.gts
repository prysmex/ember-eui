import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiSelectableListGroupLabelStyles } from '../../utils/eui/combo-box.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';

/**
 * @private Title row of an option group in EuiComboBox: upstream
 * `euiComboBoxTitle` with the selectable list group label styles (xxxs
 * title, divider line above every group but the first).
 */
export interface EuiComboBoxGroupSignature {
  Element: HTMLDivElement;
  Args: {
    /** The group: `{ groupName, disabled }`. */
    group: {
      groupName: string;
      disabled: boolean;
    };
    /**
     * @private The first row of the list. The virtualized list renders a
     * spacer before it, so upstream's `:first-child` (no divider) is set
     * from the row index instead.
     */
    isFirst?: boolean;
  };
  Blocks: {
    default: [];
  };
}

export default class EuiComboBoxGroup extends Component<EuiComboBoxGroupSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(
      context,
      euiSelectableListGroupLabelStyles
    );

    return euiClass(
      context,
      { boxSizing: 'border-box', margin: 0 },
      styles.groupLabel,
      this.args.isFirst && {
        '&:not(:first-child)': {
          paddingTop: context.upstream.euiTheme.size.s,
          '&::before': { content: 'none' }
        }
      }
    );
  }

  <template>
    <div
      class="ember-power-select-group euiComboBoxTitle {{this.classes}}"
      role="presentation"
      aria-disabled={{if @group.disabled "true"}}
      ...attributes
    >
      <span class="ember-power-select-group-name">{{@group.groupName}}</span>
      {{yield}}
    </div>
  </template>
}
