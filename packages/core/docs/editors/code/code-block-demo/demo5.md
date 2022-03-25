---
order: 5
---

# Line numbers

<EuiText>
  <p>
    To render line numbers, you can add <EuiCode>lineNumbers</EuiCode> as boolean flag.
  </p>
</EuiText>

```hbs template
<EuiCodeBlock
  @language='json'
  @fontSize='m'
  @paddingSize='m'
  @lineNumbers={{true}}
>
  {{this.jsonCode}}
</EuiCodeBlock>
```

```javascript component
import Component from '@glimmer/component';

export default class EuiMarkdownEditor1 extends Component {
  jsonCode = `{
  "id": "1",
  "rawResponse": {
    "took": 19,
    "timed_out": false,
    "_shards": {
      "total": 1,
      "successful": 1,
      "skipped": 0,
      "failed": 0
    }
  }
}`;
}
```
