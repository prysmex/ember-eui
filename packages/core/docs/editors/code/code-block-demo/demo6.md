---
order: 6
---

# Line numbers highlighted

<EuiText>
  <p>
    You can also optionally change the starting number and/or visually highlight certain lines by passing a configuration object: <EuiCode>lineNumbers={ start: 32, highlight: "32, 34-37, 40" }</EuiCode>.
  </p>
</EuiText>

```hbs template
<EuiPanel>
  <EuiCodeBlock
    @language='json'
    @fontSize='m'
    @paddingSize='m'
    @lineNumbers={{hash start=32 highlight='32, 34-37, 40'}}
  >
    {{this.jsonCode}}
  </EuiCodeBlock>
</EuiPanel>
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
