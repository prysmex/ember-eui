---
order: 1
---

# Component

```hbs template
<div style='max-width: 320px'>
  <EuiToast
    @title='Example of a good toast'
    @body='A good toast message is short and to the point. It should very rarely span multiple lines.'
    @onClose={{this.noop}}
  />
</div>
```

```js component
import Component from '@glimmer/component';

export default class extends Component {
  noop = () => {};
}
```
