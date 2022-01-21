---
order: 1
---

# Demo

```hbs template
<div>
  <EuiCodeBlock
    @language={{this.language}}
    @isCopyable={{true}}
    @overflowHeight='500px'
  >
    {{this.htmlCode}}
  </EuiCodeBlock>
</div>
<EuiTextArea
  @value={{this.htmlCode}}
  {{on 'input' (pick 'target.value' (set this 'htmlCode'))}}
/>

<EuiSelect
  @value={{this.language}}
  @hasNoInitialSelection={{true}}
  @options={{array
    (hash value='javascript' text='javascript')
    (hash value='html' text='html')
    (hash value='golang' text='golang')
  }}
  @id={{selectId}}
  {{on 'change' (pick 'target.value' (set this 'language'))}}
>
  <:prepend as |classes|>
    <EuiFormLabel class={{classes}} for={{selectId}}>
      Choose a language
    </EuiFormLabel>
  </:prepend>
</EuiSelect>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiMarkdownEditor1 extends Component {
  @tracked language = 'html';
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
