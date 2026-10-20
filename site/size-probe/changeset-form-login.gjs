// A login form: three text fields.
import EuiChangesetForm from '@ember-eui/changeset-form/components/eui-changeset-form';

console.log(
  <template>
    <EuiChangesetForm @changeset={{@changeset}} as |Form|>
      <Form.FieldText @fieldName="email" @label="Email" />
      <Form.FieldPassword @fieldName="password" @label="Password" />
      <Form.FieldText @fieldName="code" @label="Code" />
    </EuiChangesetForm>
  </template>,
);
