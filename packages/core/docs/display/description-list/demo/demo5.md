---
order: 5
---

# Centered and compressed

<EuiText>
	<p>
	Using the <EuiCode>align</EuiCode> and <EuiCode>compressed</EuiCode> args you can further tailor the look of a description list. This works with column and inline types.
  </p>

</EuiText>

```hbs template
<div style='maxWidth: 400px;'>
  <EuiDescriptionList
    @listItems={{this.favoriteVideoGames}}
    @align='center'
    @compressed={{true}}
  />

  <EuiSpacer @size='l' />

  <EuiDescriptionList
    @listItems={{this.favoriteVideoGames}}
    @align='center'
    @type='column'
    @compressed={{true}}
  />

  <EuiSpacer @size='l' />

  <EuiDescriptionList
    @listItems={{this.favoriteVideoGames}}
    @align='center'
    @type='inline'
    @compressed={{true}}
  />
</div>
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
