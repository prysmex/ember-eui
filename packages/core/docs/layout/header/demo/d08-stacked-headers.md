---
order: 8
---

# Stacked headers

<EuiText>

Stacking multiple headers provides a great way to separate global navigation concerns. Fixed headers stack automatically: each one sits below the previous ones and `--euiFixedHeadersOffset` always holds their combined height.

</EuiText>

```gjs component
import { EuiFlexGroup, EuiFlexItem, EuiSwitch, EuiSpacer, EuiHeader, EuiHeaderSection, EuiHeaderSectionItem, EuiHeaderLogo, EuiHeaderSectionItemButton, EuiAvatar, EuiHeaderBreadcrumbs, EuiIcon } from '@ember-eui/core/components';
import { eq } from 'ember-truth-helpers';
import { set } from 'ember-set-helper';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class StackedHeadersDemo extends Component {
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

  <template>
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
        <EuiHeaderSectionItem>
          <EuiHeaderLogo @iconType="logoElastic">Elastic</EuiHeaderLogo>
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
            <EuiIcon @type='popper' />
          </EuiHeaderSectionItemButton>
        </EuiHeaderSectionItem>
      </EuiHeaderSection>
    </EuiHeader>
  </template>
}
```
