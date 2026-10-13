---
order: 2
---

# Code block

<EuiText>

<strong>EuiCodeBlock</strong> can be used to create multi-line code blocks with configurable font and padding sizes.

</EuiText>

```hbs template
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
```

```javascript component
import Component from '@glimmer/component';

export default class CodeBlock extends Component {
  jsCode = `/* I'm an example of JS */
import Component from '@glimmer/component';`;
}
```
