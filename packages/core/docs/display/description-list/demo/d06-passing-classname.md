---
order: 6
---

# Passing className

<EuiText>

When using the `@listItems` argument to pass an array of items and you need to also add a `className` (or other available attribute) to the individual pieces, you can use `@titleProps` and `@descriptionProps` to do so.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiDescriptionList } from '@ember-eui/core/components';
import { hash } from '@ember/helper';

export default class DescriptionListClassDemo extends Component {
  favoriteVideoGames = [
    {
      title: 'The Elder Scrolls: Morrowind',
      description: 'The opening music alone evokes such strong memories.',
    },
    {
      title: 'TIE Fighter',
      description:
        'The sequel to XWING, join the dark side and fly for the Emperor.',
    },
    {
      title: 'Quake 2',
      description: 'The game that made me drop out of college.',
    },
  ];

  <template>
    <div style="max-width: 400px;">
      <EuiDescriptionList
        @listItems={{this.favoriteVideoGames}}
        @type="column"
        @align="center"
        @titleProps={{hash className="eui-textTruncate"}}
        @descriptionProps={{hash className="eui-textTruncate"}}
      />
    </div>
  </template>
}
```

