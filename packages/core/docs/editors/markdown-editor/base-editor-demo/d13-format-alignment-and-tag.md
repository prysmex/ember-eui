---
order: 13
---

# Format: alignment, width and tag

<EuiText>

<strong>EuiMarkdownFormat</strong> also takes <strong>EuiText</strong>'s <EuiCode>@textAlign</EuiCode>, <EuiCode>@grow</EuiCode> (<EuiCode>false</EuiCode> caps lines at a readable width) and <EuiCode>@component</EuiCode> (the root tag: <EuiCode>div</EuiCode>, <EuiCode>span</EuiCode> or <EuiCode>p</EuiCode>; only a <EuiCode>div</EuiCode> can hold block content). <strong>EuiMarkdownEditor</strong> forwards them to its preview through <EuiCode>@markdownFormatProps</EuiCode>.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { EuiMarkdownFormat, EuiSpacer } from '@ember-eui/core/components';

export default class FormatAlignment extends Component {
  centered = `### Centered

This content is centered and doesn't grow past a readable line length, however wide its container is.`;

  inline = 'An **inline** span with `code`';

  <template>
    <EuiMarkdownFormat @textAlign="center" @grow={{false}} @value={{this.centered}} />
    <EuiSpacer />
    <p>Before, <EuiMarkdownFormat @component="span" @value={{this.inline}} />, after.</p>
  </template>
}
```
