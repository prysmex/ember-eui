---
order: 1
---

# Description list

<EuiText>
	<p>
	<strong>EuiDescriptionList</strong> is a component for listing pairs of information together. You can use the component on its own, passing in an object for the list, or use the <strong>EuiDescriptionListTitle</strong> and <strong>EuiDescriptionListDescription</strong> components separately to build a list manually.
  </p>

</EuiText>

```hbs template
<EuiFlexGroup>
  <EuiFlexItem>
    <EuiDescriptionList @listItems={{this.favoriteVideoGames}} />
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiDescriptionList>
      <EuiDescriptionListTitle>Dota 2</EuiDescriptionListTitle>
      <EuiDescriptionListDescription>
        A videogame that I have spent way too much time on over the years.
      </EuiDescriptionListDescription>
      <EuiDescriptionListTitle>Kings Quest VI</EuiDescriptionListTitle>
      <EuiDescriptionListDescription>
        The game that forced me to learn DOS.
      </EuiDescriptionListDescription>
    </EuiDescriptionList>
  </EuiFlexItem>
</EuiFlexGroup>
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
