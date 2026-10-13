---
order: 3
---

# As columns

<EuiText>

Using the argument `@type` set to `column`, description lists can be presented in an inline, column format.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiCode, EuiDescriptionList, EuiSpacer, EuiText } from '@ember-eui/core/components';
import { array } from '@ember/helper';

export default class DescriptionListColumnsDemo extends Component {
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

  columnWidthItems = [
    { title: '25% width', description: '75% width' },
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
      @type="column"
      @listItems={{this.favoriteVideoGames}}
      style="max-width: 400px;"
    />
    <EuiSpacer @size="l" />
    <EuiText>
      <p>To return to the typical row format on smaller screens set <EuiCode>@type</EuiCode> to <EuiCode>responsiveColumn</EuiCode>. The following list will only show the column format on larger screens.</p>
    </EuiText>
    <EuiSpacer />
    <EuiDescriptionList
      @type="responsiveColumn"
      @listItems={{this.favoriteVideoGames}}
      style="max-width: 400px;"
    />
    <EuiSpacer @size="l" />
    <EuiText>
      <p>The optional <EuiCode>@columnWidths</EuiCode> argument allows customizing specific column widths (e.g. <EuiCode>["100px", "200px"]</EuiCode>). The first array value applies to the title column, and the second applies to the description column.</p>
      <p>Passing numbers instead of CSS width strings will use a ratio of widths. For example, <EuiCode>[1, 3]</EuiCode> will render a description column 3x the width of the title column. In other words, titles will have a width of 25% descriptions will have a width of 75%.</p>
      <p>For advanced usage, column width strings also accept <a href="https://css-tricks.com/snippets/css/complete-guide-grid/#aa-special-units-functions">CSS grid special units, sizing, keywords, and sizing functions</a>.</p>
    </EuiText>
    <EuiSpacer />
    <EuiDescriptionList
      @listItems={{this.columnWidthItems}}
      @type="column"
      @columnWidths={{array 1 3}}
      style="max-inline-size: 400px;"
    />
  </template>
}
```

