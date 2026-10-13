---
order: 5
---

# Wrapping

<EuiText>
  <p>
    By default, the <EuiCode>@whiteSpace</EuiCode> property is set to <EuiCode>pre-wrap</EuiCode>. This makes the text wrap when needed. You can, however, pass <EuiCode>pre</EuiCode> to the <EuiCode>@whiteSpace</EuiCode> argument and the text won't wrap unless line breaks are in the content.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiCodeBlock } from '@ember-eui/core/components';

export default class Wrapping extends Component {
  code = `export default () => (
  <div>In this example, the whiteSpace property is set to pre. All the whitespaces will be kept as is and the text only wraps when line breaks are in the content.</div>
);`;

  <template>
    <EuiCodeBlock
      @language='jsx'
      @fontSize='m'
      @paddingSize='m'
      @overflowHeight={{300}}
      @isCopyable={{true}}
      @whiteSpace='pre'
    >
      {{this.code}}
    </EuiCodeBlock>
  </template>
}
```

