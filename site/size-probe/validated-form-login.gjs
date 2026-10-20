// A login form: three text fields.
import ValidatedForm from '@ember-eui/validated-form/components/validated-form';

console.log(
  <template>
    <ValidatedForm as |form|>
      <form.FieldText @label="Email" @value="" @onChange={{@onChange}} />
      <form.FieldPassword @label="Password" @value="" @onChange={{@onChange}} />
      <form.FieldText @label="Code" @value="" @onChange={{@onChange}} />
    </ValidatedForm>
  </template>,
);
