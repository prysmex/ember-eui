---
order: 2
---

# Reverse style

<EuiText>

Setting the `@textStyle` argument to `reverse` will reverse the text styles of the title and description elements so that the description is more prominent. This works best for key/value type content.

Adding this argument to the `inline` type will not change anything.

</EuiText>

```hbs template
<EuiDescriptionList @textStyle="reverse" @listItems={{this.favoriteVideoGame}} />
```

```js component
import Component from '@glimmer/component';

export default class DescriptionListReverseDemo extends Component {
  favoriteVideoGame = [
    { title: 'Name', description: 'The Elder Scrolls: Morrowind' },
    { title: 'Game style', description: 'Open-world, fantasy, action role-playing' },
    { title: 'Release date', description: '2002' },
  ];
}
```
