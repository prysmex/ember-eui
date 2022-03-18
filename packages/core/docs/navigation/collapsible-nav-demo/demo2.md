---
order: 2
---

# Collapsible nav group

<EuiText>
	<p>
		An <strong>EuiCollapsibleNavGroup</strong> adds some basic borders and <EuiCode>background</EuiCode> color of <EuiCode>none</EuiCode>, <EuiCode>light</EuiCode>, or <EuiCode>dark</EuiCode>. Give each section a heading by providing an optional <EuiCode>title</EuiCode> and <EuiCode>iconType</EuiCode>. Make the section collapsible (accordion style) with <EuiCode>isCollapsible=true</EuiCode>.
	</p>
	<p>
    	When in <EuiCode>isCollapsible</EuiCode> mode, a <EuiCode>title</EuiCode> and <EuiCode>initialIsOpen:boolean</EuiCode> is required.
	</p>

</EuiText>

```hbs template
<EuiCollapsibleNavGroup>
  <:content>
    <EuiText @size='s' @color='subdued'>
      <p>This is a basic group without any modifications</p>
    </EuiText>
  </:content>
</EuiCollapsibleNavGroup>
<EuiCollapsibleNavGroup @title='Nav group' @iconType='logoElastic'>
  <:content>
    <EuiText @size='s' @color='subdued'>
      <p>
        This is a nice group with a heading supplied via{' '}
        <EuiCode>title</EuiCode>
        and
        <EuiCode>iconType</EuiCode>.
      </p>
    </EuiText>
  </:content>
</EuiCollapsibleNavGroup>
<EuiCollapsibleNavGroup
  @background='light'
  @title='Nav group'
  @isCollapsible={{true}}
  @iconType='logoElastic'
  @initialIsOpen={{true}}
>
  <:content>
    <EuiText @size='s' @color='subdued'>
      <p>
        This group is
        <EuiCode>collapsible</EuiCode>
        and set with
        <EuiCode>initialIsOpen</EuiCode>. It has a heading that is the
        collapsing button via
        <EuiCode>title</EuiCode>
        and
        <EuiCode>iconType</EuiCode>.
      </p>
    </EuiText>
  </:content>
</EuiCollapsibleNavGroup>
<EuiCollapsibleNavGroup
  @title='Nav group'
  @iconType='logoGCPMono'
  @iconSize='xxl'
  @titleSize='s'
  @isCollapsible={{true}}
  @initialIsOpen={{false}}
  @background='dark'
>
  <:content>
    <EuiText @size='s'>
      <p>
        This is a
        <EuiCode>dark</EuiCode>
        <EuiCode>collapsible</EuiCode>
        group that is initally set to closed,
        <EuiCode>iconSize=&quot;xxl&quot;</EuiCode>
        and
        <EuiCode>titleSize=&quot;s&quot;</EuiCode>.
      </p>
    </EuiText>
  </:content>
</EuiCollapsibleNavGroup>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoCollapsibleNavComponent extends Component {
  @tracked collNavIsOpen = false;
  @tracked navIsDocked = false;

  @action
  openCollapsibleNav() {
    this.collNavIsOpen = true;
  }

  @action
  closeCollapsibleNav() {
    this.collNavIsOpen = false;
  }

  @action
  toggleDockedNav() {
    this.navIsDocked = !this.navIsDocked;
  }
}
```
