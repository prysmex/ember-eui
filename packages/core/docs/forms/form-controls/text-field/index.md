---
title: Text field
---
<EuiSpacer/>
<EuiPageHeader @pageTitle="Text field"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiFieldText` renders an `<input type="text">` styled for EUI, with
optional icon, clear button, loading spinner and content before or after
the input. Put it in an `EuiFormRow` to give it a label, help text and
errors.

```gjs
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiFieldText, EuiFormRow } from '@ember-eui/core/components';

export default class NameField extends Component {
  @tracked name = '';

  @action
  updateName(event) {
    this.name = event.target.value;
  }

  <template>
    <EuiFormRow @label="Name">
      <EuiFieldText @value={{this.name}} {{on "input" this.updateName}} />
    </EuiFormRow>
  </template>
}
```

The field shows `@value`; you keep the value and update it from the
`input` event (`event.target.value`). With the `pick` helper
(ember-composable-helpers) and `set` (ember-set-helper) that is a one-liner:
`{{on "input" (pick "target.value" (set this "name"))}}`.

Other attributes (`placeholder`, `maxlength`, `autocomplete`, `name`,
`required`…) go to the `<input>`.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiFieldText

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@id` | `string` | a random id | Id of the input, e.g. to match an `EuiFormRow`'s label. |
| `@value` | `string` |  | The value. Update it from `{{on "input" …}}` on the component. |
| `@placeholder` | `string` |  | Placeholder text. |
| `@icon` |  |  | Icon inside the input (left side), anything `EuiIcon`'s `@type` accepts. |
| `@fullWidth` | `boolean` |  | Stretches the input to its container's width. |
| `@isLoading` | `boolean` |  | Shows a spinner in the input. |
| `@compressed` | `boolean` |  | Shorter input, for dense forms. |
| `@readOnly` | `boolean` |  | Makes the input read-only. |
| `@disabled` | `boolean` |  | Disables the input. |
| `@clear` | `() => void` |  | Shows a clear ("x") button calling this function; empty the value there. |
| `@controlOnly` | `boolean` |  | Renders just the `<input>`, without the layout (icon, clear button, prepend/append). Best used inside EuiFormControlLayoutDelimited. |
| `@isInvalid` | `boolean` |  | Shows the invalid state and marks the input invalid for native form validation. |
| `@inputRef` | `(element: HTMLInputElement \| null) => void` |  | Called with the `<input>` element once rendered (only with `@controlOnly`). |

| Block | Description |
| --- | --- |
| `<:prepend>` | Content before the input, e.g. an `EuiFormLabel`; yields the class to put on it and the input id. |
| `<:append>` | Content after the input; yields the class to put on it and the input id. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<input>`.

</EuiText>
<!-- api:end -->
