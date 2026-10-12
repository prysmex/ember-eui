---
order: 5
---

# Text block truncate

<EuiText>

`EuiTextBlockTruncate` clamps text to `@lines` lines with an ellipsis. It
renders a `<div>`; with `@cloneElement={{true}}` it renders nothing itself
and yields a modifier that styles your own element instead (upstream's
`cloneElement`), e.g. a paragraph inside `EuiText`.

</EuiText>

```hbs template
<div style="max-width: 400px">
  <EuiTextBlockTruncate @lines={{2}}>
    {{this.text}}
  </EuiTextBlockTruncate>
  <EuiSpacer />
  <EuiText>
    <EuiTextBlockTruncate @lines={{3}} @cloneElement={{true}} as |clamp|>
      <p {{clamp}}>{{this.text}}</p>
    </EuiTextBlockTruncate>
  </EuiText>
</div>
```

```js component
import Component from '@glimmer/component';

export default class BlockTruncate extends Component {
  text = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.';
}
```
