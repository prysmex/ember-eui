---
order: 1
---

# Inline

```hbs template
<EuiText>
  <p>
    Sometimes you need to emphasize
    <EuiCode>Code</EuiCode>
    like this.
  </p>
  <p>
    You can also pass a language in like
    <EuiCode @language='html'>{{this.htmlCode}}</EuiCode>.
  </p>
  <p>
    Make the background transparent like this
    <EuiCode @transparentBackground={{true}} @language='html'>
      {{this.htmlCode}}
    </EuiCode>
    .
  </p>
</EuiText>
<EuiTextArea
  @value={{this.htmlCode}}
  {{on 'input' (pick 'target.value' (set this 'htmlCode'))}}
/>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiMarkdownEditor1 extends Component {
  @tracked value = `### hehe
  - [ ] hola
  - [ ] hola
  - [x] hola
  \`\`\`javascript
    class Human {}
  \`\`\`
  `;
  @tracked htmlCode = `<!--I'm an example of HTML-->
<div>
  asdf
</div>
`;
}
```
