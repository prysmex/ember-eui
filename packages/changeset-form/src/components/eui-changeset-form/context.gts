import { hash } from '@ember/helper';
import type { TemplateOnlyComponent } from '@ember/component/template-only';
import type { IEuiChangesetFormTheme } from '../eui-changeset-form.gts';

export interface ContextSignature {
  Args: {
    formId: string;
    changeset: any;
    theme: IEuiChangesetFormTheme;
  };
  Blocks: {
    default: [IEuiChangesetFormTheme];
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
