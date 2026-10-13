---
order: 1
---

# Inline

<EuiText>

<strong>EuiCode</strong> is for making inline code snippets that can work within or next to bodies of text.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiCode, EuiText } from '@ember-eui/core/components';

export default class InlineCode extends Component {
  htmlCode = `<!--I'm an example of HTML-->
<div>
  asdf
</div>`;

  <template>
    <EuiText>
      <p>
        Sometimes you need to emphasize
        <EuiCode>code</EuiCode>
        like this.
      </p>
      <p>
        You can also pass a language in like
        <EuiCode @language='html'>{{this.htmlCode}}</EuiCode>.
      </p>
      <p>
        Make the background transparent like this
        <EuiCode @language='html' @transparentBackground={{true}}>{{this.htmlCode}}</EuiCode>.
      </p>
    </EuiText>
  </template>
}
```

