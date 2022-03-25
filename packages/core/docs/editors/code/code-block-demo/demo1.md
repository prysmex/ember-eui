---
order: 1
---

# Code block

<EuiText>
  <p>
    <strong>EuiCodeBlock</strong> can be used to create multi-line code blocks with configurable font and padding sizes
  </p>
</EuiText>

```hbs template
<EuiCodeBlock @language='jsx' @fontSize='m' @paddingSize='m'>
  {{this.jsCode}}
</EuiCodeBlock>
<EuiCodeBlock
  @language='jsx'
  @fontSize='m'
  @paddingSize='m'
  @transparentBackground={{true}}
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
