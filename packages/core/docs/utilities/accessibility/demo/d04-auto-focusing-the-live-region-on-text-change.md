---
order: 4
---

# Auto-focusing the live region on text change

<EuiText>

The <EuiCode>@focusRegionOnTextChange</EuiCode> argument will automatically focus the <strong>EuiScreenReaderLive</strong> region (causing screen readers to read out the text content) whenever its content changes.

This is primarily useful for announcing navigation or page changes, when programmatically resetting focus location back to a certain part of the page (where the <strong>EuiScreenReaderLive</strong> is placed) is desired.

<em>Using a screen reader, click the following navigation links and notice that when the new page is announced, focus is also set to the top of the body content.</em>

</EuiText>

<EuiSpacer />

```hbs template
<EuiFlexGroup>
  <EuiFlexItem @grow={{false}} style='min-width: 200px'>
    <EuiSideNav @items={{this.sideNav}} @mobileBreakpoints={{array}} />
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiTitle @size='m'><h2>{{this.pageTitle}}</h2></EuiTitle>
    <EuiSpacer />
    <EuiScreenReaderLive @focusRegionOnTextChange={{true}}>
      {{this.pageTitle}}
    </EuiScreenReaderLive>
    <EuiButton>
      Clicking a nav link and then pressing tab should focus this button
    </EuiButton>
  </EuiFlexItem>
</EuiFlexGroup>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class FocusRegionOnTextChange extends Component {
  @tracked pageTitle = 'Home';

  get sideNav() {
    const setPage = (title) => () => (this.pageTitle = title);

    return [
      {
        name: 'Example side nav',
        id: 'focusRegionOnTextChange-root',
        items: ['Home', 'About', 'Docs', 'Contact'].map((title) => ({
          name: title,
          id: `focusRegionOnTextChange-${title}`,
          isSelected: this.pageTitle === title,
          onClick: setPage(title),
        })),
      },
    ];
  }
}
```
