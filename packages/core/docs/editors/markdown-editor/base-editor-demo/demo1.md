---
order: 1
---

# Demo

```hbs template
<EuiMarkdownEditor @value={{this.value}} @onChange={{set this 'value'}} />
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
}
```
