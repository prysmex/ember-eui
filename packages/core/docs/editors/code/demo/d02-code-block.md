---
order: 2
---

# Code block

<EuiText>

<strong>EuiCodeBlock</strong> can be used to create multi-line code blocks with configurable font and padding sizes.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiCodeBlock, EuiSpacer } from '@ember-eui/core/components';

export default class CodeBlock extends Component {
  jsCode = `/* I'm an example of JS */
`;

  <template>
    <EuiCodeBlock @language='jsx' @fontSize='m' @paddingSize='m'>
      {{this.jsCode}}
    </EuiCodeBlock>

    <EuiSpacer />

    <EuiCodeBlock
      @language='jsx'
      @paddingSize='none'
      @transparentBackground={{true}}
    >
      {{this.jsCode}}
    </EuiCodeBlock>
  </template>
}
```

