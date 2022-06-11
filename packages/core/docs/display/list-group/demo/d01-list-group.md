---
order: 1
---

 <EuiText>
    <p>The <strong>EuiListGroup</strong> component is used to present <strong>EuiListGroupItems</strong> in a neatly formatted list. Use the <EuiCode>flush</EuiCode> and <EuiCode>bordered</EuiCode> properties for full-width and bordered presentations, respectively.
Adjust the <EuiCode>gutterSize</EuiCode> prop to increase or decrease the spacing between items.</p>
</EuiText>

```hbs template
<EuiFlexGroup>
  <EuiFlexItem>
    <EuiListGroup
      @bordered={{this.bordered}}
      @flush={{this.flush}}
      @maxWidth={{this.maxWidth}}
      @gutterSize={{this.gutterSize}}
    >
      <EuiListGroupItem
        @href={{if this.useHref '/'}}
        @onClick={{if this.useOnClick this.onClick}}
        @isActive={{this.isActive}}
        @isDisabled={{this.isDisabled}}
        @wrapText={{this.wrapText}}
        @size={{this.size}}
        @color={{this.color}}
        @iconType={{if this.useIconType 'bell'}}
      >
        {{#if this.wrapText}}
          First item with very long text with Lorem ipsum dolor sit amet,
          consectetur adipiscing elit
        {{else}}
          First item
        {{/if}}
      </EuiListGroupItem>
      <EuiListGroupItem>
        Second item
      </EuiListGroupItem>
      <EuiListGroupItem>
        Third item
      </EuiListGroupItem>
      <EuiListGroupItem>
        Fourth item
      </EuiListGroupItem>
    </EuiListGroup>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiFlexGroup>
      <EuiFlexItem>
        <EuiTitle @size='xs'>Group</EuiTitle>
        <div>
          <Input @type='checkbox' @checked={{this.bordered}} name='bordered' />
          <label for='bordered'>Bordered</label>
        </div>
        <div>
          <Input @type='checkbox' @checked={{this.flush}} name='flushed' />
          <label for='flushed'>Flush</label>
        </div>

      </EuiFlexItem>
    </EuiFlexGroup>
  </EuiFlexItem>
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoListGroupComponent extends Component {
  // Group config
  @tracked bordered = false;
  @tracked flush = false;
  @tracked gutterSize = 's';
  @tracked maxWidthType = 'bool';
  @tracked maxWidth = false;

  @action
  parseToNum(event) {
    this.maxWidth = Number(event.target.value);
  }

  @action
  onClick(event) {
    console.log('Item clicked');
  }

  //Item config
  @tracked useHref = false;
  @tracked useOnClick = false;
  @tracked isActive = false;
  @tracked isDisabled = false;
  @tracked wrapText = false;
  @tracked size = 'm';
  @tracked color = 'inherit';
  @tracked useIconType = false;
}
```
