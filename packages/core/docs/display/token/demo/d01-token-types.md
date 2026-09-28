---
order: 1
---

# Token types

<EuiText>

Each `token*` icon has its own shape and color. Hover a token to see its
name.

</EuiText>

```hbs template
<EuiFlexGrid @columns={{4}} @gutterSize="s">
  {{#each this.types as |type|}}
    <EuiFlexItem>
      <EuiFlexGroup @gutterSize="s" @alignItems="center" @responsive={{false}}>
        <EuiFlexItem @grow={{false}}>
          <EuiToken @iconType={{type}} @title={{type}} />
        </EuiFlexItem>
        <EuiFlexItem>
          <EuiText @size="xs"><code>{{type}}</code></EuiText>
        </EuiFlexItem>
      </EuiFlexGroup>
    </EuiFlexItem>
  {{/each}}
</EuiFlexGrid>
```

```js component
import Component from '@glimmer/component';

export default class TokenTypes extends Component {
  types = [
    'tokenString',
    'tokenKeyword',
    'tokenText',
    'tokenNumber',
    'tokenBoolean',
    'tokenDate',
    'tokenGeo',
    'tokenIP',
    'tokenNested',
    'tokenObject',
    'tokenArray',
    'tokenBinary',
    'tokenFunction',
    'tokenClass',
    'tokenVariable',
    'tokenConstant',
  ];
}
```
