---
order: 1
---

# Header

<EuiText>

The header is made up of **many** individual components starting with `EuiHeader` as the container. You can manually configure your header with the following related components:

- **`EuiHeaderSection`**: Left/right containers with flex properties.
- **`EuiHeaderSectionItem`**: Containers for individual header items as flex items.
- **`EuiHeaderSectionItemButton`**: Specialized button that extends `EuiButtonEmpty` but styled to fit the height of the header with additional `@notification` args.
- **`EuiHeaderLogo`**: A helpful component for creating a linked logo that fits within the header sizing.
- **`EuiHeaderBreadcrumbs`**: A set of `EuiBreadcrumbs` specifically stylized to fit inside the header.

</EuiText>

## Component

```hbs template
<EuiHeader>
  <EuiHeaderSection>
    <EuiHeaderSectionItem>
      <EuiHeaderLogo @iconType="logoElastic" @href="#" aria-label="Go to home page" {{on "click" this.preventDefault}} />
    </EuiHeaderSectionItem>

    {{! spaces menu }}
    <EuiHeaderSectionItem>
      <EuiPopover
        @isOpen={{this.spacesOpen}}
        @anchorPosition="downLeft"
        @closePopover={{this.closeSpaces}}
        @panelPaddingSize="none"
      >
        <:button>
          <EuiHeaderSectionItemButton
            aria-expanded={{this.spacesOpen}}
            aria-haspopup="true"
            aria-label="Spaces menu"
            @onClick={{this.toggleSpaces}}
          >
            <EuiAvatar @type="space" @name={{this.selectedSpace.label}} @size="s" />
          </EuiHeaderSectionItemButton>
        </:button>
        <:content>
          <EuiSelectable
            @options={{this.spaces}}
            @singleSelection="always"
            @searchable={{this.isListExtended}}
            @searchProps={{hash placeholder="Find a space" compressed=true}}
            @listProps={{hash rowHeight=40 showIcons=false}}
            @onChange={{this.selectSpace}}
            style="width: 300px;"
            as |parts|
          >
            <EuiPopoverTitle @paddingSize="s">
              {{#if parts.search}}
                <parts.search />
              {{else}}
                Your spaces
              {{/if}}
            </EuiPopoverTitle>
            <parts.list>
              <:optionPrepend as |space|>
                <EuiAvatar @type="space" @name={{space.label}} @size="s" />
              </:optionPrepend>
            </parts.list>
            <EuiPopoverFooter @paddingSize="s">
              <EuiButton
                @size="s"
                @fullWidth={{true}}
                @isDisabled={{this.isListExtended}}
                {{on "click" this.addMoreSpaces}}
              >
                Add more spaces
              </EuiButton>
            </EuiPopoverFooter>
          </EuiSelectable>
        </:content>
      </EuiPopover>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>

  <EuiHeaderBreadcrumbs
    aria-label="Header breadcrumbs example"
    @breadcrumbs={{this.breadcrumbs}}
  />

  <EuiHeaderSection @side="right">
    {{! sitewide search }}
    <EuiHeaderSectionItem>
      <EuiSelectableTemplateSitewide @options={{this.noOptions}}>
        <:popoverButton as |toggle|>
          <EuiHeaderSectionItemButton aria-label="Sitewide search" @onClick={{toggle}}>
            <EuiIcon @type="magnify" @size="m" />
          </EuiHeaderSectionItemButton>
        </:popoverButton>
      </EuiSelectableTemplateSitewide>
    </EuiHeaderSectionItem>

    {{! user menu }}
    <EuiHeaderSectionItem>
      <EuiPopover
        @isOpen={{this.userOpen}}
        @anchorPosition="downRight"
        @closePopover={{this.closeUser}}
        @panelPaddingSize="m"
      >
        <:button>
          <EuiHeaderSectionItemButton
            aria-expanded={{this.userOpen}}
            aria-haspopup="true"
            aria-label="Account menu"
            @onClick={{this.toggleUser}}
          >
            <EuiAvatar @name="John Username" @size="s" />
          </EuiHeaderSectionItemButton>
        </:button>
        <:content>
          <div style="width: 300px;">
            <EuiFlexGroup @gutterSize="m" @responsive={{false}}>
              <EuiFlexItem @grow={{false}}>
                <EuiAvatar @name="John Username" @size="xl" />
              </EuiFlexItem>

              <EuiFlexItem>
                <EuiText>
                  <p>John Username</p>
                </EuiText>

                <EuiSpacer @size="m" />

                <EuiFlexGroup>
                  <EuiFlexItem>
                    <EuiFlexGroup @justifyContent="spaceBetween">
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

    {{! apps menu }}
    <EuiHeaderSectionItem>
      <EuiPopover
        @isOpen={{this.appsOpen}}
        @anchorPosition="downRight"
        @closePopover={{this.closeApps}}
      >
        <:button>
          <EuiHeaderSectionItemButton
            aria-expanded={{this.appsOpen}}
            aria-haspopup="true"
            aria-label="Apps menu with 1 new app"
            @notification="1"
            @onClick={{this.toggleApps}}
          >
            <EuiIcon @type="apps" @size="m" />
          </EuiHeaderSectionItemButton>
        </:button>
        <:content>
          <EuiKeyPadMenu style="width: 288px;">
            {{#each this.apps as |app|}}
              <EuiKeyPadMenuItem @label={{app.label}} @betaBadgeLabel={{app.betaBadgeLabel}}>
                <EuiIcon @type={{app.type}} @size="l" />
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

const SPACES = [
  { label: 'Sales team', checked: 'on' },
  { label: 'Engineering' },
  { label: 'Security' },
  { label: 'Default' },
];

const ADDITIONAL_SPACES = [
  { label: 'Sales team 2' },
  { label: 'Engineering 2' },
  { label: 'Security 2' },
  { label: 'Default 2' },
];

export default class HeaderDemo extends Component {
  @tracked spacesOpen = false;
  @tracked userOpen = false;
  @tracked appsOpen = false;
  @tracked spaces = SPACES;

  noOptions = [];

  apps = [
    { label: 'Discover', type: 'discoverApp' },
    { label: 'Dashboard', type: 'dashboardApp' },
    { label: 'Dev Tools', type: 'devToolsApp' },
    { label: 'Machine Learning', type: 'machineLearningApp' },
    { label: 'Graph', type: 'graphApp' },
    { label: 'Visualize', type: 'visualizeApp' },
    { label: 'Timelion', type: 'timelionApp', betaBadgeLabel: 'Beta' },
  ];

  breadcrumbs = [
    { text: 'Management', href: '#', onClick: this.preventDefault },
    {
      text: 'Truncation test is here for a really long item',
      href: '#',
      onClick: this.preventDefault,
    },
    { text: 'Hidden', href: '#', onClick: this.preventDefault },
    { text: 'Users', href: '#', onClick: this.preventDefault },
    { text: 'Create' },
  ];

  get selectedSpace() {
    return this.spaces.find((space) => space.checked) ?? this.spaces[0];
  }

  get isListExtended() {
    return this.spaces.length > 4;
  }

  @action
  preventDefault(event) {
    event.preventDefault();
  }

  @action
  toggleSpaces() {
    this.spacesOpen = !this.spacesOpen;
  }

  @action
  closeSpaces() {
    this.spacesOpen = false;
  }

  @action
  selectSpace(options) {
    this.spaces = options;
    this.spacesOpen = false;
  }

  @action
  addMoreSpaces() {
    this.spaces = [...this.spaces, ...ADDITIONAL_SPACES];
  }

  @action
  toggleUser() {
    this.userOpen = !this.userOpen;
  }

  @action
  closeUser() {
    this.userOpen = false;
  }

  @action
  toggleApps() {
    this.appsOpen = !this.appsOpen;
  }

  @action
  closeApps() {
    this.appsOpen = false;
  }
}
```
