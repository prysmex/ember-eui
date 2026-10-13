---
order: 4
---

# Format: built in plugins

<EuiText>

<strong>EuiMarkdownFormat</strong> is a read-only way to render markdown-style content in a page. It is a peer component to <strong>EuiMarkdownEditor</strong> and has the ability to be modified by additional markdown plugins.

<strong>EuiMarkdownFormat</strong> is a wrapper that will render the Markdown provided in <EuiCode>@value</EuiCode>. It uses <a href="https://github.com/remarkjs/remark" target="_blank" rel="noopener noreferrer">Remark</a> by default. The translation layer automatically substitutes raw HTML output with their EUI equivalent. This means anchors, code blocks and horizontal rules will become <strong>EuiLink</strong>, <strong>EuiCodeBlock</strong> and <strong>EuiHorizontalRule</strong> components respectively.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { EuiMarkdownFormat } from '@ember-eui/core/components';

export default class FormatBuiltIn extends Component {
  markdownContent = `Beyond Remark's base syntax, **EuiMarkdownFormat** bundles these abilities by default:

\`:smile:\` we support emojis :smile:! But not :)

\`!{tooltip[anchor text](Tooltip content)}\` syntax can render !{tooltip[tooltips like this](I am Jack's helpful tooltip content)}

We also support checkboxes so that

\`\`\`
- [ ] Checkboxes
- [x] Can be filled
- [ ] Or empty
\`\`\`

turns into

- [ ] Checkboxes
- [x] Can be filled
- [ ] Or empty

Note that you'll need to use *EuiMarkdownEditor* to make those checkboxes dynamic.
`;

  <template>
    <EuiMarkdownFormat @value={{this.markdownContent}} />
  </template>
}
```

