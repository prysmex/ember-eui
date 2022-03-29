---
order: 1
---

# Header

<EuiText>
  The header is made up of
  <strong>many</strong>
  individual components starting with
  <strong>EuiHeader</strong>
  as the container. You can manually configure your header with the following
  related components:
  <br />
  <br />

  <ul>
    <li><strong>EuiHeaderSection</strong>: Left/right containers with flex
      properties.</li>
    <li>
      <strong>EuiHeaderSectionItem</strong>: Containers for individual header
      items as flex items.</li>
    <li><strong>EuiHeaderSectionItemButton</strong>: Specialized button that
      extends EuiButtonEmpty but styled to fit the height of the header with
      additional
      <EuiCode>notification</EuiCode>
      props.</li>
    <li><strong>EuiHeaderLogo</strong>: A helpful component for creating a
      linked logo that fits within the header sizing.</li>
    <!-- <li><strong>EuiHeaderBreadcrumbs</strong>: A set of EuiBreadcrumbs
      specifically stylized to fit inside the header.</li> -->
  </ul>
</EuiText>

```hbs template
<EuiHeader>
  <EuiHeaderSection @side='left'>
    <EuiHeaderSectionItem @border='right'>
      <EuiHeaderLogo
        @iconType='logoElastic'
        href='#'
        @onClick={{this.onClick}}
        aria-label='Go to home page'
      />
    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem @border='right'>
      <EuiHeaderSectionItemButton>
        <EuiAvatar
          @name='Planta Prysmex'
          @type='space'
          @initialLength={{2}}
          @size='s'
        />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
  <EuiHeaderSection @side='right'>
    <EuiHeaderSectionItem @border='left'>
      <EuiHeaderSectionItemButton
        aria-controls='header1'
        aria-expanded={{this.isOpen}}
        aria-haspopup='true'
        aria-label='Account menu'
        onClick={{this.onMenuButtonClick}}
      >
        <EuiAvatar
          @name='David Martinez'
          @type='user'
          @initialLength={{2}}
          @size='s'
        />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem @border='left'>
      <EuiHeaderSectionItemButton @notification='3' @notificationColor='accent'>
        <EuiIcon @type='bell' @size='m' />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem @border='left'>
      <EuiHeaderSectionItemButton
        @disabled={{true}}
        aria-label='Apps menu with 1 new app'
        @notification='1'
      >
        <EuiIcon @type='apps' size='m' />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
</EuiHeader>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoHeaderComponent extends Component {
  @tracked isOpen = false;

  @action
  onClick(e) {
    e.preventDefault();
  }

  @action
  onMenuButtonClick(e) {
    e.preventDefault();
  }
}
```
