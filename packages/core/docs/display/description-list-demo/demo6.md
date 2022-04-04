---
order: 6
---

# Passing className

<EuiText>
	<p>
	When using the <EuiCode>listItems</EuiCode> arg to pass an array of items and you could also add a <EuiCode>className</EuiCode> (or other available arg) to the individual pieces throught the <EuiCode>titleProps</EuiCode> and <EuiCode>descriptionProps</EuiCode>
  </p>

</EuiText>

```hbs template
<div style='max-width: 400px;'>
  <EuiDescriptionList
    @listItems={{this.favoriteVideoGames}}
    @align='center'
    @type='column'
    @titleProps={{hash className='eui-textTruncate'}}
    @descriptionProps={{hash className='eui-textTruncate'}}
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
