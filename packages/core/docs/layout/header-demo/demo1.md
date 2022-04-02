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
      <EuiHeaderLogo @iconType='logoElastic' aria-label='Go to home page' />
    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem @border='right'>
      <EuiHeaderSectionItemButton @ref={{set this 'btn'}}>
        <EuiAvatar
          @name='Planta Prysmex'
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
    <EuiHeaderSectionItem @border='left'>
      <EuiPopover
        @isOpen={{this.userPopover}}
        @closePopover={{set this 'userPopover' false}}
      >
        <:button>
          <EuiHeaderSectionItemButton
            aria-controls='header1'
            aria-expanded={{this.isOpen}}
            aria-haspopup='true'
            aria-label='Account menu'
            @onClick={{this.onMenuButtonClick}}
          >
            <EuiAvatar
              @name='David Martinez'
              @type='user'
              @initialLength={{2}}
              @size='s'
            />
          </EuiHeaderSectionItemButton>
        </:button>
        <:content>
          <div style='width:320px;'>
            <EuiFlexGroup
              @gutterSize='m'
              class='euiHeaderProfile'
              @responsive={{false}}
            >
              <EuiFlexItem @grow={{false}}>
                <EuiAvatar @name='David Martinez' @size='xl' />
              </EuiFlexItem>

              <EuiFlexItem>
                <EuiText>
                  <p>David Martinez</p>
                </EuiText>

                <EuiSpacer @size='m' />

                <EuiFlexGroup>
                  <EuiFlexItem>
                    <EuiFlexGroup @justifyContent='spaceBetween'>
                      <EuiFlexItem @grow={{false}}>
                        <EuiLink>Edit profile</EuiLink>
                      </EuiFlexItem>

                      <EuiFlexItem @grow={{false}}>
                        <EuiLink>Log out</EuiLink>
                      </EuiFlexItem>
                    </EuiFlexGroup>
                  </EuiFlexItem>
                </EuiFlexGroup>
              </EuiFlexItem>
            </EuiFlexGroup>
          </div>
        </:content>
      </EuiPopover>

    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem @border='left'>
      <EuiHeaderSectionItemButton @notification='3' @notificationColor='accent'>
        <EuiIcon @type='bell' @size='m' />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem @border='left'>

      <EuiPopover
        @isOpen={{this.appsPopover}}
        @closePopover={{set this 'appsPopover' false}}
      >
        <:button>
          <EuiHeaderSectionItemButton
            aria-label='Apps menu with 1 new app'
            @notification='1'
            @onClick={{set this 'appsPopover' true}}
          >
            <EuiIcon @type='apps' size='m' />
          </EuiHeaderSectionItemButton>
        </:button>
        <:content>
          <div style='width:320px;'>
            <EuiFlexGroup
              @gutterSize='m'
              class='euiHeaderProfile'
              @responsive={{false}}
            >
              <EuiFlexItem @grow={{false}}>
                <EuiAvatar @name='David Martinez' @size='xl' />
              </EuiFlexItem>

              <EuiFlexItem>
                <EuiText>
                  <p>David Martinez</p>
                </EuiText>

                <EuiSpacer @size='m' />

                <EuiFlexGroup>
                  <EuiFlexItem>
                    <EuiFlexGroup @justifyContent='spaceBetween'>
                      <EuiFlexItem @grow={{false}}>
                        <EuiLink>Edit profile</EuiLink>
                      </EuiFlexItem>

                      <EuiFlexItem @grow={{false}}>
                        <EuiLink>Log out</EuiLink>
                      </EuiFlexItem>
                    </EuiFlexGroup>
                  </EuiFlexItem>
                </EuiFlexGroup>
              </EuiFlexItem>
            </EuiFlexGroup>
          </div>
        </:content>
      </EuiPopover>

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
  @tracked userPopover = false;
  @tracked appsPopover = false;
  @tracked btn;

  spacesValues = [
    {
      label: 'Sales team',
      prepend: {
        type: 'space',
        name: 'Sales Team',
        size: 's'
      },
      checked: 'on'
    },
    {
      label: 'Engineering',
      prepend: {
        type: 'space',
        name: 'Engineering',
        size: 's'
      }
    },
    {
      label: 'Security',
      prepend: {
        type: 'space',
        name: 'Security',
        size: 's'
      }
    },
    {
      label: 'Default',
      prepend: {
        type: 'space',
        name: 'Default',
        size: 's'
      }
    }
  ];

  additionalSpaces = [
    {
      label: 'Sales team 2',
      prepend: {
        type: 'space',
        name: 'Sales Team 2',
        size: 's'
      }
    },
    {
      label: 'Engineering 2',
      prepend: {
        type: 'space',
        name: 'Engineering 2',
        size: 's'
      }
    },
    {
      label: 'Security 2',
      prepend: {
        type: 'space',
        name: 'Security 2',
        size: 's'
      }
    },
    {
      label: 'Default 2',
      prepend: {
        type: 'space',
        name: 'Default 2',
        size: 's'
      }
    }
  ];

  animate = () => {
    this.btn?.euiAnimate?.();
  };

  breadcrumbs = [
    {
      text: 'Management',
      href: '#',
      onClick: (e) => {
        e.preventDefault();
      },
      'data-test-subj': 'breadcrumbsAnimals',
      className: 'customClass'
    },
    {
      text: 'Truncation test is here for a really long item',
      href: '#',
      onClick: (e) => {
        e.preventDefault();
      }
    },
    {
      text: 'Hidden',
      href: '#',
      onClick: (e) => {
        e.preventDefault();
      }
    },
    {
      text: 'Users',
      href: '#',
      onClick: (e) => {
        e.preventDefault();
      }
    },
    {
      text: 'Create'
    }
  ];

  @action
  onClick(e) {
    e.preventDefault();
  }

  @action
  onMenuButtonClick(e) {
    e.preventDefault();
    this.userPopover = true;
  }
}
```
