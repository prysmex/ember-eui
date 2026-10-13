---
order: 5
---

# Customizing appearance

<EuiText>

#### Alignment & Compression

Utilize the `@align` and `@compressed` arguments to refine the presentation of your description list. These are compatible with both column and inline types.

#### Vertical spacing

Modify the `@rowGutterSize` argument to control the vertical spacing between **EuiDescriptionList** elements. This will not affect inline list types.

#### Horizontal spacing

Adjust the spacing between the title and description with the `@columnGutterSize` argument. This will not affect inline or row types.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButtonGroup, EuiDescriptionList, EuiFlexGroup, EuiFlexItem, EuiSpacer, EuiSwitch, EuiTitle } from '@ember-eui/core/components';

export default class DescriptionListAppearanceDemo extends Component {
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

  alignToggleButtons = [
    { id: 'left', label: 'Left' },
    { id: 'center', label: 'Center' },
  ];

  gutterOptions = [
    { id: 's', label: 'Small' },
    { id: 'm', label: 'Medium' },
  ];

  @tracked alignSelected = 'center';
  @tracked rowGutterSize = 'm';
  @tracked columnGutterSize = 'm';
  @tracked compressed = true;

  @action setAlign(id) {
    this.alignSelected = id;
  }

  @action setRowGutterSize(id) {
    this.rowGutterSize = id;
  }

  @action setColumnGutterSize(id) {
    this.columnGutterSize = id;
  }

  @action toggleCompressed() {
    this.compressed = !this.compressed;
  }

  <template>
    <div style="max-width: 400px;">
      <EuiFlexGroup>
        <EuiFlexItem>
          <EuiTitle @size="xxs"><h3>Align options</h3></EuiTitle>
          <EuiButtonGroup
            @legend="Toggle for the EuiDescription align argument"
            @options={{this.alignToggleButtons}}
            @idSelected={{this.alignSelected}}
            @onChange={{this.setAlign}}
          />
        </EuiFlexItem>

        <EuiFlexItem>
          <EuiTitle @size="xxs"><h3>Row gutter sizes</h3></EuiTitle>
          <EuiButtonGroup
            @legend="Toggle for the EuiDescription rowGutterSize argument"
            @options={{this.gutterOptions}}
            @idSelected={{this.rowGutterSize}}
            @onChange={{this.setRowGutterSize}}
          />
        </EuiFlexItem>

        <EuiFlexItem>
          <EuiTitle @size="xxs"><h3>Column gap sizes</h3></EuiTitle>
          <EuiButtonGroup
            @legend="Toggle for the EuiDescription columnGutterSize argument"
            @options={{this.gutterOptions}}
            @idSelected={{this.columnGutterSize}}
            @onChange={{this.setColumnGutterSize}}
          />
        </EuiFlexItem>

        <EuiFlexItem>
          <EuiTitle @size="xxs"><h3>Compressed</h3></EuiTitle>
          <EuiSwitch
            @label="Compressed"
            @checked={{this.compressed}}
            @onChange={{this.toggleCompressed}}
          />
        </EuiFlexItem>
      </EuiFlexGroup>

      <EuiSpacer />

      <EuiDescriptionList
        @listItems={{this.favoriteVideoGames}}
        @align={{this.alignSelected}}
        @compressed={{this.compressed}}
        @rowGutterSize={{this.rowGutterSize}}
      />

      <EuiSpacer @size="l" />

      <EuiDescriptionList
        @listItems={{this.favoriteVideoGames}}
        @type="column"
        @align={{this.alignSelected}}
        @compressed={{this.compressed}}
        @rowGutterSize={{this.rowGutterSize}}
        @columnGutterSize={{this.columnGutterSize}}
      />

      <EuiSpacer @size="l" />

      <EuiDescriptionList
        @listItems={{this.favoriteVideoGames}}
        @type="inline"
        @align={{this.alignSelected}}
        @compressed={{this.compressed}}
      />
    </div>
  </template>
}
```

