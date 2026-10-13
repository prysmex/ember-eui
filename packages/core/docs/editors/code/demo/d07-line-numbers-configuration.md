---
order: 7
---

# Line numbers configuration

<EuiText>

You can customize line number display further with a configuration object containing the following optional settings:

<ul>
<li><EuiCode>start</EuiCode>: Changes the starting number of the first line. Defaults to <EuiCode>1</EuiCode>.</li>
<li><EuiCode>highlight</EuiCode>: Visually highlights certain lines (e.g. <EuiCode>"3"</EuiCode>), or ranges of lines (e.g. <EuiCode>"5-10"</EuiCode>). Accepts a comma-separated string of lines or line ranges.</li>
<li><EuiCode>annotations</EuiCode>: Displays an informational icon next to certain line numbers, that provides more context via a popover. Pass an object of line numbers with corresponding annotation strings.</li>
</ul>

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiCodeBlock } from '@ember-eui/core/components';

export default class LineNumbersConfig extends Component {
  lineNumbers = {
    start: 32,
    highlight: '32, 34-37, 40',
    annotations: {
      34: 'Coordinates can be obtained from Elastic Maps',
      38: 'Allowed types: Point, Area',
    },
  };

  jsonCode = `"OriginLocation": [
  {
    "coordinates": [
      -97.43309784,
      37.64989853
    ],
    "type": "Point"
  }
],`;

  <template>
    <EuiCodeBlock
      @language='json'
      @fontSize='m'
      @paddingSize='m'
      @lineNumbers={{this.lineNumbers}}
    >
      {{this.jsonCode}}
    </EuiCodeBlock>
  </template>
}
```

