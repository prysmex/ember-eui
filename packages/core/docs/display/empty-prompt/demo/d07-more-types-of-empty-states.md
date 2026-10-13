---
order: 7
---

# More types of empty states

<EuiText>

**EuiEmptyPrompt** can be used for more than just **empty** pages. The following example showcases different types of empty states that you can create with the **EuiEmptyPrompt**. For a full list see the usage guidelines below.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButton, EuiButtonEmpty, EuiEmptyPrompt, EuiFormLabel, EuiImage, EuiLink, EuiSelect, EuiSpacer, EuiTitle } from '@ember-eui/core/components';
import { array } from '@ember/helper';
import { on } from '@ember/modifier';
import { eq } from 'ember-truth-helpers';

const ActionButton1 = <template><EuiButton @color="primary">Home</EuiButton></template>;
const ActionButton2 = <template><EuiButtonEmpty @color="primary" @iconType="arrowLeft" @flush="both">Go back</EuiButtonEmpty></template>;
const ActionButton3 = <template><EuiButton @color="primary">Home</EuiButton></template>;
const ActionButton4 = <template><EuiButtonEmpty @color="primary" @iconType="arrowLeft" @flush="both">Go back</EuiButtonEmpty></template>;
const ActionButton5 = <template><EuiButton @color="primary">Upgrade</EuiButton></template>;
const ActionButton6 = <template><EuiButtonEmpty>Start a free trial</EuiButtonEmpty></template>;

const svg =
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 240">' +
  '<rect width="400" height="240" rx="16" fill="#E6F1FA"/>' +
  '<circle cx="110" cy="90" r="50" fill="#BFDBFF"/>' +
  '<circle cx="300" cy="150" r="30" fill="#0B64DD"/>' +
  '<text x="200" y="215" font-size="32" text-anchor="middle" fill="#1750BA">404</text></svg>';

export default class EmptyPromptTypesDemo extends Component {
  @tracked selected = 'errorPages';

  illustration = `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`;

  types = [
    { value: 'errorPages', text: 'Page not found' },
    { value: 'noPrivileges', text: 'No permission' },
    { value: 'licenseUpgrade', text: 'License upgrade' },
  ];

  @action setType(event) {
    this.selected = event.target.value;
  }

  <template>
    <EuiSelect
      @value={{this.selected}}
      @options={{this.types}}
      aria-label="Empty prompt examples"
      {{on "change" this.setType}}
    >
      <:prepend as |classes|>
        <EuiFormLabel class={{classes}}>Examples</EuiFormLabel>
      </:prepend>
    </EuiSelect>
    <EuiSpacer @size="l" />
    {{#if (eq this.selected "errorPages")}}
      <EuiEmptyPrompt
        @color="subdued"
        @layout="vertical"
        @title="Page not found"
        @body="We can't find the page you're looking for. It might have been removed, renamed, or it didn't exist in the first place."
        @actions={{array
          ActionButton1
          ActionButton2
        }}
      >
        <:icon>
          <EuiImage
            @size="fullWidth"
            @src={{this.illustration}}
            alt="An outer space illustration. In the background is a large moon and two planets. In the foreground is an astronaut floating in space and the numbers '404'."
          />
        </:icon>
      </EuiEmptyPrompt>
    {{else if (eq this.selected "noPrivileges")}}
      <EuiEmptyPrompt
        @color="subdued"
        @layout="vertical"
        @title="Access denied"
        @body="Sorry to rain on your parade, but you don't have permissions to access this page."
        @actions={{array
          ActionButton3
          ActionButton4
        }}
      >
        <:icon>
          <EuiImage @size="fullWidth" @src={{this.illustration}} alt="" />
        </:icon>
      </EuiEmptyPrompt>
    {{else}}
      <EuiEmptyPrompt
        @color="subdued"
        @iconType="logoKibana"
        @title="Do more with Kibana!"
        @layout="vertical"
        @hasBorder={{true}}
        @body="Start a free trial or upgrade your license to use anomaly detection."
        @actions={{array
          ActionButton5
          ActionButton6
        }}
      >
        <:footer>
          <EuiTitle @size="xxs"><h3>Want to learn more?</h3></EuiTitle>
          <EuiLink @href="#" @target="_blank">Read the docs</EuiLink>
        </:footer>
      </EuiEmptyPrompt>
    {{/if}}
  </template>
}
```

