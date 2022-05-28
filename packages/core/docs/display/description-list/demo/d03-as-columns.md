---
order: 3
---

# As columns

<EuiText>
	<p>
	Using the arg <EuiCode>type</EuiCode> set to <EuiCode>column</EuiCode> description lists can be presented in an inline, column format.
  </p>
	<p>
	To return to the typical row format on smaller screens set <EuiCode>type</EuiCode> to <EuiCode>responsiveColumn</EuiCode>.
	</p>

</EuiText>

```hbs template
<EuiDescriptionList
  @type='column'
  @listItems={{this.favoriteVideoGames}}
  style='max-width:400px;'
/>
<EuiSpacer @size='xl' />
<EuiTitle @size='s'>
  <h3>
    The following list will become the typical row format on small screens
  </h3>
</EuiTitle>
<EuiSpacer />

<EuiDescriptionList
  @type='responsiveColumn'
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
