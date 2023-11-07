import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiComboBoxGroupSignature {
  Element: HTMLDivElement;
  Args: {
    group: {
      groupName: string;
      disabled: boolean;
    };
  };
  Blocks: {
    default: [];
  };
}

const EuiComboBoxGroup: TemplateOnlyComponent<EuiComboBoxGroupSignature> =
  <template>
    <div
      class="ember-power-select-group"
      aria-disabled={{if @group.disabled "true"}}
      ...attributes
    >
      <div
        class="ember-power-select-group-name euiComboBoxTitle"
      >{{@group.groupName}}</div>
      {{yield}}
    </div>
  </template>;

export default EuiComboBoxGroup;
