---
order: 1
---

# Description list

<EuiText>

**EuiDescriptionList** is a component for listing pairs of information together. You can use the component on its own, passing in an array of items as `@listItems`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiDescriptionList, EuiDescriptionListDescription, EuiDescriptionListTitle, EuiSpacer, EuiText } from '@ember-eui/core/components';

export default class DescriptionListDemo extends Component {
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
    <EuiDescriptionList @listItems={{this.favoriteVideoGames}} />
    <EuiSpacer />
    <EuiText>
      <p>You can also use the <strong>EuiDescriptionListTitle</strong> and <strong>EuiDescriptionListDescription</strong> components separately to build a list manually.</p>
    </EuiText>
    <EuiSpacer />
    <EuiDescriptionList>
      <EuiDescriptionListTitle>
        The Elder Scrolls: Morrowind
      </EuiDescriptionListTitle>
      <EuiDescriptionListDescription>
        The opening music alone evokes such strong memories.
      </EuiDescriptionListDescription>
      <EuiDescriptionListTitle>TIE Fighter</EuiDescriptionListTitle>
      <EuiDescriptionListDescription>
        The sequel to XWING, join the dark side and fly for the Emperor.
      </EuiDescriptionListDescription>
      <EuiDescriptionListTitle>Quake 2</EuiDescriptionListTitle>
      <EuiDescriptionListDescription>
        The game that made me drop out of college.
      </EuiDescriptionListDescription>
    </EuiDescriptionList>
  </template>
}
```

