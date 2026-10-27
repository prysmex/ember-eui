import { hash } from '@ember/helper';

import type { EuiChangesetFormTheme } from '../eui-changeset-form';
import type { TemplateOnlyComponent } from '@ember/component/template-only';
import type { WithBoundArgs } from '@glint/template';

type Theme = EuiChangesetFormTheme;
type ContextArgs = 'formId' | 'changeset';

/** The theme's fields with the form's changeset and id bound. */
export interface ContextFields {
  FieldBase: WithBoundArgs<Theme['FieldBase'], ContextArgs>;
  FieldText: WithBoundArgs<Theme['FieldText'], ContextArgs>;
  FieldTextArea: WithBoundArgs<Theme['FieldTextArea'], ContextArgs>;
  FieldPassword: WithBoundArgs<Theme['FieldPassword'], ContextArgs>;
  FieldRadio: WithBoundArgs<Theme['FieldRadio'], ContextArgs>;
  FieldCheckbox: WithBoundArgs<Theme['FieldCheckbox'], ContextArgs>;
  FieldSwitch: WithBoundArgs<Theme['FieldSwitch'], ContextArgs>;
  FieldRadioGroup: WithBoundArgs<Theme['FieldRadioGroup'], ContextArgs>;
  FieldCheckboxGroup: WithBoundArgs<Theme['FieldCheckboxGroup'], ContextArgs>;
  FieldDualRangeSlider: WithBoundArgs<
    Theme['FieldDualRangeSlider'],
    ContextArgs
  >;
  FieldRangeSlider: WithBoundArgs<Theme['FieldRangeSlider'], ContextArgs>;
  FieldNumber: WithBoundArgs<Theme['FieldNumber'], ContextArgs>;
  FieldSelect: WithBoundArgs<Theme['FieldSelect'], ContextArgs>;
  FieldComboBox: WithBoundArgs<Theme['FieldComboBox'], ContextArgs>;
}

/** @private Binds the theme's fields to the form's changeset and id. */
export interface ContextSignature {
  Args: {
    /** Id of the form. */
    formId: string;
    /** The form's changeset. */
    changeset: any;
    /** The field components to bind. */
    theme: EuiChangesetFormTheme;
  };
  Blocks: {
    /** Yields the bound field components. */
    default: [ContextFields];
  };
}

const Context: TemplateOnlyComponent<ContextSignature> = <template>
  {{yield
    (hash
      FieldBase=(component @theme.FieldBase formId=@formId changeset=@changeset)
      FieldText=(component @theme.FieldText formId=@formId changeset=@changeset)
      FieldTextArea=(component
        @theme.FieldTextArea formId=@formId changeset=@changeset
      )
      FieldPassword=(component
        @theme.FieldPassword formId=@formId changeset=@changeset
      )
      FieldRadio=(component
        @theme.FieldRadio formId=@formId changeset=@changeset
      )
      FieldCheckbox=(component
        @theme.FieldCheckbox formId=@formId changeset=@changeset
      )
      FieldSwitch=(component
        @theme.FieldSwitch formId=@formId changeset=@changeset
      )
      FieldRadioGroup=(component
        @theme.FieldRadioGroup formId=@formId changeset=@changeset
      )
      FieldCheckboxGroup=(component
        @theme.FieldCheckboxGroup formId=@formId changeset=@changeset
      )
      FieldDualRangeSlider=(component
        @theme.FieldDualRangeSlider formId=@formId changeset=@changeset
      )
      FieldRangeSlider=(component
        @theme.FieldRangeSlider formId=@formId changeset=@changeset
      )
      FieldNumber=(component
        @theme.FieldNumber formId=@formId changeset=@changeset
      )
      FieldSelect=(component
        @theme.FieldSelect formId=@formId changeset=@changeset
      )
      FieldComboBox=(component
        @theme.FieldComboBox formId=@formId changeset=@changeset
      )
    )
  }}
</template>;

export default Context;
