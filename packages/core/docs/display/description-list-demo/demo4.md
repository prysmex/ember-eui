---
order: 4
---

# Inline

<EuiText>
	<p>
	Using a arg <EuiCode>type</EuiCode> set to <EuiCode>inline</EuiCode> description lists can be presented in an inline, blob format. This is useful for JSON code blocks. Inline description lists are sized smaller than normal lists due to their compact nature.
  </p>

</EuiText>

```hbs template
<EuiDescriptionList
  @type='inline'
  @listItems={{this.favoriteVideoGames}}
  style='max-width:400px;'
/>
```

```js component
import Component from '@glimmer/component';

export default class DemoComponent extends Component {
  favoriteVideoGames = [
    {
      title: 'The Elder Scrolls: Morrowind',
      description: 'The opening music alone evokes such strong memories.'
    },
    {
      title: 'TIE Fighter',
      description:
        'The sequel to XWING, join the dark side and fly for the Emporer.'
    },
    {
      title: 'Quake 2',
      description: 'The game that made me drop out of college.'
    }
  ];
}
```
