---
order: 3
---

# Copying

<EuiText>

Adding the <EuiCode>@isCopyable</EuiCode> argument allows users to copy the text content of the code block.

</EuiText>

```hbs template
<EuiCodeBlock @language='html' @isCopyable={{true}}>
  {{this.htmlCode}}
</EuiCodeBlock>
```

```javascript component
import Component from '@glimmer/component';

export default class Copying extends Component {
  htmlCode = `<!-- I'm an example of HTML -->
<h1>Hello world!</h1>
<p>Lorem ipsum dolor sit amet.</p>`;
}
```
