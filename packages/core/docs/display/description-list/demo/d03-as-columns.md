---
order: 3
---

# As columns

<EuiText>

Using the argument `@type` set to `column`, description lists can be presented in an inline, column format.

</EuiText>

```hbs template
<EuiDescriptionList
  @type="column"
  @listItems={{this.favoriteVideoGames}}
  style="max-width: 400px;"
/>
<EuiSpacer @size="l" />
<EuiText>

To return to the typical row format on smaller screens set `@type` to `responsiveColumn`. The following list will only show the column format on larger screens.

</EuiText>
<EuiSpacer />
<EuiDescriptionList
  @type="responsiveColumn"
  @listItems={{this.favoriteVideoGames}}
  style="max-width: 400px;"
/>
<EuiSpacer @size="l" />
<EuiText>

The optional `@columnWidths` argument allows customizing specific column widths (e.g. `array "100px" "200px"`). The first value applies to the title column, and the second applies to the description column.

Passing numbers instead of CSS width strings will use a ratio of widths. For example, `(array 1 3)` will render a description column 3x the width of the title column. In other words, titles will have a width of 25% descriptions will have a width of 75%.

For advanced usage, column width strings also accept [CSS grid special units, sizing, keywords, and sizing functions](https://css-tricks.com/snippets/css/complete-guide-grid/#aa-special-units-functions).

</EuiText>
<EuiSpacer />
<EuiDescriptionList
  @listItems={{this.columnWidthItems}}
  @type="column"
  @columnWidths={{array 1 3}}
  style="max-inline-size: 400px;"
/>
```

```js component
import Component from '@glimmer/component';

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
}
```
