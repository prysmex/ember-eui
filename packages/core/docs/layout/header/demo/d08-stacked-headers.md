---
order: 8
---

# Stacked headers

<EuiText>
  Stacking multiple headers provides a great way to separate global navigation concerns. However, the <EuiCode>position="fixed"</EuiCode> option will not be aware of the number of headers. If you do need fixed <strong>and</strong> stacked headers, you will need to apply the SASS helper mixin and pass in the correct height to afford for.
</EuiText>

```hbs template
<EuiFlexGroup @alignItems='center' @gutterSize='m'>
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch
      @label='Make header fixed position'
      @checked={{eq this.position 'fixed'}}
      @onChange={{this.setPosition}}
    />
  </EuiFlexItem>
</EuiFlexGroup>

<EuiSpacer />

<!-- header 1 -->
<EuiHeader @position={{this.position}} @theme='dark'>
  <EuiHeaderSection @side='left'>
    <EuiHeaderSectionItem @border='right'>
      <EuiHeaderLogo>Elastic</EuiHeaderLogo>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
  <EuiHeaderSection @side='right'>
    <EuiHeaderSectionItem>
      <EuiHeaderSectionItemButton
        aria-label='Account menu'
      >
        <EuiAvatar
          @name='John Username'
          @type='user'
          @initialLength={{2}}
          @size='s'
        />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
</EuiHeader>

<!-- header 2 -->
<EuiHeader @position={{this.position}}>
  <EuiHeaderSection @side='left'>
    <EuiHeaderSectionItem>
      <EuiHeaderSectionItemButton
        @border='right'
        aria-label='Account menu'
      >
        <EuiAvatar
          @name="Default Space"
          @type='space'
          @initialLength={{2}}
          @size='s'
        />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>

  <EuiHeaderBreadcrumbs
    aria-label='Header breadcrumbs example'
    @breadcrumbs={{this.breadcrumbs}}
  />

  <EuiHeaderSection @side='right'>
    <EuiHeaderSectionItem>
      <EuiHeaderSectionItemButton
        @notification={{true}}
        @notificationColor='accent'
        @ref={{set this 'cheerRef'}}
      >
        <EuiIcon @type='cheer' />
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
  @tracked position = 'static';

  breadcrumbs = [
    {
      text: 'Management',
      href: '#',
      onClick: this.breadcrumOnClick
    },
    {
      text: 'Users'
    }
  ];

  breadcrumOnClick(e) {
    e.preventDefault();
  } 

  setPosition = (e) => {
    if (e.target.checked) {
      this.position = 'fixed';
    } else {
      this.position = 'static';
    }
  };
}
```
