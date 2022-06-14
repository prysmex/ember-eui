---
order: 4
---

# Copy

<EuiText>
  <p>
    Adding the <EuiCode>isCopyable</EuiCode> prop allows users to copy the text content of the code block.
  </p>
</EuiText>

```hbs template
<EuiCodeBlock
  @language='jsx'
  @fontSize='m'
  @paddingSize='m'
  @isCopyable={{true}}
>
  {{this.jsCode}}
</EuiCodeBlock>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiMarkdownEditor1 extends Component {
  jsCode = `
/* I'm an example of JS */ 
import Component from '@glimmer/component';
`;
}
```
