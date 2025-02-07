---
order: 1
---

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

<TodoText @text="missing EuiSelectableTemplateSitewide and EuiSelectable components"/>
<EuiSpacer/>

<EuiHeader>

  <EuiHeaderSection @side='left'>
    <EuiHeaderSectionItem @border='right'>
      <EuiHeaderLogo @iconType='logoElastic' aria-label='Go to home page' />
    </EuiHeaderSectionItem>
    
    <!-- spaces -->
    <EuiHeaderSectionItem @border='right'>

      <!-- <EuiPopover
        @isOpen={{isOpen}}
        @anchorPosition="downLeft"
        @closePopover={{set this 'spacePopover' false}}
        @panelPaddingSize="none"
      >
        <EuiSelectable
          searchable={{this.listIsExtended}}
          searchProps={{this.todo}}
          options={{this.spaces}}
          singleSelection="always"
          style="width: 300"
          onChange={{onChange}}
          listProps={{this.todo}}
        >
          <:button>
            <EuiHeaderSectionItemButton
              aria-controls='header1'
              aria-expanded={{this.spacePopover}}
              aria-haspopup='true'
              aria-label='Account menu'
              @onClick={{this.onMenuButtonClick}}
            >
              <EuiAvatar
                @name={{this.space.label}}
                @type='space'
                @initialLength={{2}}
                @size='s'
              />
            </EuiHeaderSectionItemButton>
          </:button>
          <:content>
            <EuiPopoverTitle paddingSize="s">
              TODO: search
            </EuiPopoverTitle>
            TODO: list
            <EuiPopoverFooter paddingSize="s">
              <EuiButton
                size="s"
                @fullWidth={{true}}
                onClick={{this.addMoreSpaces}}
                disabled={{this.listIsExtended}}
              >
                Add more spaces
              </EuiButton>
            </EuiPopoverFooter>
          </:content>
        </EuiSelectable>
      </EuiPopover> -->

    </EuiHeaderSectionItem>
  </EuiHeaderSection>

  <EuiHeaderBreadcrumbs
    aria-label='Header breadcrumbs example'
    @breadcrumbs={{this.breadcrumbs}}
  />

  <EuiHeaderSection @side='right'>

    <!-- search -->
    <EuiHeaderSectionItem @border='left'>
      <EuiHeaderSectionItemButton
        @ref={{set this 'cheerRef'}}
      >
        <EuiIcon @type='search' />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>

    <!-- profile -->
    <EuiHeaderSectionItem @border='left'>
      <EuiPopover
        @isOpen={{this.userPopover}}
        @closePopover={{set this 'userPopover' false}}
      >
        <:button>

          <EuiHeaderSectionItemButton
            aria-controls='header1'
            aria-expanded={{this.userPopover}}
            aria-haspopup='true'
            aria-label='Account menu'
            @onClick={{this.onMenuButtonClick}}
          >
            <EuiAvatar
              @name={{this.name}}
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
                <EuiAvatar @name={{this.name}} @size='xl' />
              </EuiFlexItem>

              <EuiFlexItem>
                <EuiText>
                  <p>{{this.name}}</p>
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

    <!-- apps -->
    <EuiHeaderSectionItem @border='left'>
      <EuiPopover
        @isOpen={{this.appsPopover}}
        @closePopover={{set this 'appsPopover' false}}
        @anchorPosition="downRight"
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
          <EuiKeyPadMenu id='headerAppKeyPadMenuId' style="width: 288px">
            {{#each this.apps as |appObj|}}
              <EuiKeyPadMenuItem @label={{appObj.label}}>
                <EuiIcon @type={{appObj.type}} @size='l' />
              </EuiKeyPadMenuItem>
            {{/each}}
          </EuiKeyPadMenu>
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
  @tracked spacePopover = false;
  @tracked userPopover = false;
  @tracked appsPopover = false;
  @tracked btn;
  @tracked spaces = [
    {
      label: 'Sales Team'
    },
    {
      label: 'Engineering'
    },
    {
      label: 'Security'
    },
    {
      label: 'Default'
    }
  ];
  @tracked space = this.spaces[0];

  additionalSpaces = [
    {
      label: 'Sales Team 2'
    },
    {
      label: 'Engineering 2'
    },
    {
      label: 'Security 2'
    },
    {
      label: 'Default 2'
    }
  ];

  apps = [
    {
      label: 'Discover',
      type: 'discoverApp'
    },
    {
      label: 'Dashboard',
      type: 'dashboardApp'
    },
    {
      label: 'Dev Tools',
      type: 'devToolsApp'
    },
    {
      label: 'Machine Learning',
      type: 'machineLearningApp'
    },
    {
      label: 'Graph',
      type: 'graphApp'
    },
    {
      label: 'Visualize',
      type: 'visualizeApp'
    },
    {
      label: 'Timelion',
      type: 'timelionApp'
    }
  ]

  name = 'John Username'

  breadcrumbs = [
    {
      text: 'Management',
      href: '#',
      onClick: this.breadcrumOnClick
    },
    {
      text: 'Truncation test is here for a really long item',
      href: '#',
      onClick: this.breadcrumOnClick
    },
    {
      text: 'Hidden',
      href: '#',
      onClick: this.breadcrumOnClick
    },
    {
      text: 'Users',
      href: '#',
      onClick: this.breadcrumOnClick
    },
    {
      text: 'Create'
    }
  ];

  get listIsExtended() {
    return this.spaces.length > 4
  }

  breadcrumOnClick(e) {
    e.preventDefault();
  }

  @action
  onMenuButtonClick(e) {
    e.preventDefault();
    this.userPopover = true;
  }
}
```
