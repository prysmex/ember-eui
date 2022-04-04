---
order: 2
---

# Reverse style

<EuiText>
	<p>
	Setting the <EuiCode>textStyle</EuiCode> arg to <EuiCode>reverse</EuiCode> will reverse the text styles of the <EuiCode>title</EuiCode> and <EuiCode>description</EuiCode> elements so that the description is more prominent. This works best for key/value type content.
  </p>
	<p>
		Adding this property to the <EuiCode>inline</EuiCode> type will not change anything.
	</p>

</EuiText>

```hbs template
<EuiDescriptionList
  @textStyle='reverse'
  @listItems={{this.favoriteVideoGames}}
/>
```

```js component
import Component from '@glimmer/component';

export default class DemoComponent extends Component {
  favoriteVideoGames = [
    {
      title: 'Name',
      description: 'The Elder Scrolls: Morrowind'
    },
    {
      title: 'Game style',
      description: 'Open-world, fantasy, action role-playing'
    },
    {
      title: 'Release date',
      description: '2002'
    }
  ];
}
```
