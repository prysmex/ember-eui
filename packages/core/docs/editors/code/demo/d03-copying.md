---
order: 3
---

# Copying

<EuiText>

Adding the <EuiCode>@isCopyable</EuiCode> argument allows users to copy the text content of the code block.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiCodeBlock } from '@ember-eui/core/components';

export default class Copying extends Component {
  htmlCode = `<!-- I'm an example of HTML -->
<h1>Hello world!</h1>
<p>Lorem ipsum dolor sit amet.</p>`;

  <template>
    <EuiCodeBlock @language='html' @isCopyable={{true}}>
      {{this.htmlCode}}
    </EuiCodeBlock>
  </template>
}
```

