---
order: 4
---

# Inline

<EuiText>

Using the argument `@type` set to `inline`, description lists can be presented in an inline, blob format. This is useful for JSON code blocks. Inline description lists are sized smaller than normal lists due to their compact nature.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiDescriptionList } from '@ember-eui/core/components';

export default class DescriptionListInlineDemo extends Component {
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
    <EuiDescriptionList
      @type="inline"
      @listItems={{this.favoriteVideoGames}}
      style="max-width: 400px;"
    />
  </template>
}
```

