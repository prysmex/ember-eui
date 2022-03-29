---
order: 5
---

```hbs template
<EuiTitle @size='s'>
  Portal content in the header
</EuiTitle>
<EuiSpacer />
<EuiText>
  Use an
  <strong>EuiHeaderSectionItemButton</strong>
  to display additional information in popovers or flyouts, such as a user
  profile or news feed. When using
  <strong>EuiFlyout</strong>, be sure to wrap it in a
  <strong>EuiPortal</strong>. When using an
  <strong>EuiPopover</strong>
  in conjunction with a
  <strong>fixed</strong>
  header, be sure to add the
  <EuiCode>repositionOnScroll</EuiCode>
  prop to the popover.
</EuiText>
<EuiSpacer />
<EuiFlexGroup @alignItems='center' @gutterSize='m'>
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch
      @label={{'Make header fixed position'}}
      @checked={{this.isFixedPosition}}
      @onChange={{this.toggleFixedPosition}}
    />
  </EuiFlexItem>

  <EuiFlexItem @grow={{false}}>
    <EuiSwitch
      @label={{'Change theme to dark'}}
      @checked={{this.isDarkTheme}}
      @onChange={{this.toggleDarkTheme}}
    />
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiHeader
  @position={{if this.isFixedPosition 'fixed'}}
  @theme={{if this.isDarkTheme 'dark'}}
>
  <EuiHeaderSection @side='left'>
    <EuiHeaderSectionItem @border='right'>
      <EuiHeaderLogo>Elastic</EuiHeaderLogo>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
  <EuiHeaderSection @side='right'>
    <EuiHeaderSectionItem @border='left'>
      <EuiHeaderSectionItemButton {{on 'click' (set this 'isFlyoutOpen' true)}} @notification='3' @notificationColor='accent'>
        <EuiIcon @type='bell' />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
    <EuiPopover
      @isOpen={{this.isNotificationPopoverOpen}}
      @anchorPosition='downCenter'
      @repositionOnScroll={{true}}
      @closePopover={{set this 'isNotificationPopoverOpen' false}}
    >
      <:button>
        <EuiHeaderSectionItem>
          <EuiHeaderSectionItemButton
            @onClick={{set
              this
              'isNotificationPopoverOpen'
              (not this.isNotificationPopoverOpen)
            }}
            @notification='1'
            @notificationColor='accent'
          >
            <EuiIcon
              @type='cheer'
              @notification='1'
              @notificationColor='accent'
            />
          </EuiHeaderSectionItemButton>
        </EuiHeaderSectionItem>
      </:button>
      <:content>
        <EuiPopoverTitle @paddingSize='m'>
          WHATS NEW
        </EuiPopoverTitle>
        <EuiText>
          Popover content will go here
        </EuiText>
        <EuiPopoverFooter @paddingSize='s'>
          <EuiText @color='subdued' @size='s'>
            <p>Version 7.0</p>
          </EuiText>
        </EuiPopoverFooter>
      </:content>
    </EuiPopover>
    <EuiPopover
      @isOpen={{this.isProfilePopoverOpen}}
      @anchorPosition='downCenter'
      @repositionOnScroll={{true}}
      @closePopover={{set this 'isProfilePopoverOpen' false}}
      @paddingSize='m'
    >
      <:button>
        <EuiHeaderSectionItem>
          <EuiHeaderSectionItemButton
            @onClick={{set
              this
              'isProfilePopoverOpen'
              (not this.isProfilePopoverOpen)
            }}
          >
            <EuiAvatar @name='John Doe' @initialLength={{2}} />
          </EuiHeaderSectionItemButton>
        </EuiHeaderSectionItem>
      </:button>
      <:content>
        <div style='width: 320;'>
          <EuiFlexGroup
            @gutterSize='m'
            @className='euiHeaderProfile'
            @responsive={{false}}
          >
            <EuiFlexItem @grow={{false}}>
              <EuiAvatar @name='John Doe' @size='xl' />
            </EuiFlexItem>

            <EuiFlexItem>
              <EuiText>
                <p>John Doe</p>
              </EuiText>

              <EuiSpacer @size='m' />

              <EuiFlexGroup>
                <EuiFlexItem>
                  <EuiFlexGroup @justifyContent='spaceBetween'>
                    <EuiFlexItem @grow={{false}}>
                      <EuiText>Edit profile</EuiText>
                    </EuiFlexItem>

                    <EuiFlexItem @grow={{false}}>
                      <EuiText>Log out</EuiText>
                    </EuiFlexItem>
                  </EuiFlexGroup>
                </EuiFlexItem>
              </EuiFlexGroup>
            </EuiFlexItem>
          </EuiFlexGroup>
        </div>
      </:content>
    </EuiPopover>
  </EuiHeaderSection>
</EuiHeader>
{{#if this.isFlyoutOpen}}
  <EuiPortal>
    <EuiFlyout @onClose={{set this 'isFlyoutOpen' false}} @size='s'>
      <EuiFlyoutHeader @hasBorder={{true}}>
        <EuiTitle @size='s'>
          WHATS NEW
        </EuiTitle>
      </EuiFlyoutHeader>
      <EuiFlyoutBody>
        Flyout body
      </EuiFlyoutBody>
      <EuiFlyoutFooter>
        <EuiFlexGroup @justifyContent='spaceBetween' @alignItems='center'>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonEmpty
              @iconType='cross'
              @flush='left'
              {{on 'click' (set this 'isFlyoutOpen' false)}}
            >
              Close
            </EuiButtonEmpty>
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiText @color='subdued' @size='s'>
              <p>Version 7.0</p>
            </EuiText>
          </EuiFlexItem>
        </EuiFlexGroup>
      </EuiFlyoutFooter>
    </EuiFlyout>
  </EuiPortal>
{{/if}}
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoHeaderComponent extends Component {
  @tracked header1Fixed = false;
  @tracked isFixedPosition = false;
  @tracked isDarkTheme = false;
  @tracked isProfilePopoverOpen = false;
  @tracked isNotificationPopoverOpen = false;
  @tracked isFlyoutOpen = false;

  @action
  toggleFixedPosition() {
    this.isFixedPosition = !this.isFixedPosition;
  }

  @action
  toggleDarkTheme() {
    this.isDarkTheme = !this.isDarkTheme;
  }
}
```
