---
order: 6
---

# Portal content in the header

<EuiText>
  <p>
    Use an <strong>EuiHeaderSectionItemButton</strong> to display additional information in <EuiLink @href="/docs/core/docs/layout/popover">popovers</EuiLink> or <EuiLink @href="/docs/core/docs/layout/flyout">flyouts</EuiLink>, such as a user profile or news feed. When using <EuiLink @href="/docs/core/docs/layout/flyout">EuiFlyout</EuiLink>, be sure to wrap it in a <EuiLink @href="/docs/core/docs/utilities/portal">EuiPortal</EuiLink>. When using an <EuiLink @href="">EuiPopover</EuiLink> in conjunction with a <strong>fixed</strong> header, be sure to add the <EuiCode>repositionOnScroll</EuiCode> prop to the popover.
  </p>
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

  <EuiFlexItem @grow={{false}}>
    <EuiSwitch
      @label='Change theme to dark'
      @checked={{eq this.theme 'dark'}}
      @onChange={{this.setTheme}}
    />
  </EuiFlexItem>
</EuiFlexGroup>

<EuiSpacer />
<EuiHeader @position={{this.position}} @theme={{this.theme}}>
  <EuiHeaderSection @side='left'>
    <EuiHeaderSectionItem @border='right'>
      <EuiHeaderLogo>Elastic</EuiHeaderLogo>
    </EuiHeaderSectionItem>
  </EuiHeaderSection>
  <EuiHeaderSection @side='right'>
    <EuiHeaderSectionItem>
      <EuiHeaderSectionItemButton
        @notification={{true}}
        aria-controls='headerFlyoutNewsFeed'
        aria-expanded={{this.flyout}}
        aria-haspopup='true'
        aria-label='Alerts feed: Updates available'
        {{on 'click' (set this 'flyout' true)}}
      >
        <EuiIcon @type='bell' />
      </EuiHeaderSectionItemButton>
    </EuiHeaderSectionItem>
    <EuiHeaderSectionItem>
      <EuiPopover
        @isOpen={{this.popover}}
        @closePopover={{set this 'popover' false}}
        @anchorPosition='leftCenter'
        @panelPaddingSize='none'
      >
        <:button>
          <EuiHeaderSectionItemButton
            @notification={{6}}
            aria-controls='headerPopoverNewsFeed'
            aria-expanded={{this.popover}}
            aria-haspopup='true'
            aria-label='News feed: Updates available'
            {{on 'click' (set this 'popover' (not this.popover))}}
          >
            <EuiIcon @type='cheer' />
          </EuiHeaderSectionItemButton>
        </:button>
        <:content>
          <EuiPopoverTitle @paddingSize='s'>What&apos;s new</EuiPopoverTitle>
          <div style='max-height:40vh; overflow-y: auto; padding: 4px'>
            <EuiSpacer size='s' />
            {{#each this.alerts as |alert|}}
              <EuiHeaderAlert>
                <:title>
                  {{alert.title}}
                </:title>
                <:action>
                  <EuiLink>{{alert.action}}</EuiLink>
                </:action>
                <:text>
                  {{alert.text}}
                </:text>
                <:date>
                  {{alert.date}}
                </:date>
                <:badge>
                  <EuiBadge @color={{alert.badgeColor}}>{{alert.badge}}</EuiBadge>
                </:badge>
              </EuiHeaderAlert>
            {{/each}}
          </div>
          <EuiPopoverFooter @paddingSize='s'>
            <EuiText @color='subdued' @size='s'>
              <p>Version 7.0</p>
            </EuiText>
          </EuiPopoverFooter>
        </:content>
      </EuiPopover>

    </EuiHeaderSectionItem>
  </EuiHeaderSection>
</EuiHeader>

{{#if this.flyout}}
  <EuiPortal>
    <EuiFlyout @onClose={{set this 'flyout' false}} @size='s'>
      <EuiFlyoutHeader @hasBorder={{true}}>
        <EuiTitle @size='s'>
          <h2>What&apos;s new</h2>
        </EuiTitle>
      </EuiFlyoutHeader>
      <EuiFlyoutBody>
        {{#each this.alerts as |alert|}}
          <EuiHeaderAlert>
            <:title>
              {{alert.title}}
            </:title>
            <:action>
              <EuiLink>{{alert.action}}</EuiLink>
            </:action>
            <:text>
              {{alert.text}}
            </:text>
            <:date>
              {{alert.date}}
            </:date>
            <:badge>
              <EuiBadge
                @color={{alert.badgeColor}}
              >
                {{alert.badge}}
              </EuiBadge>
            </:badge>
          </EuiHeaderAlert>
        {{/each}}
      </EuiFlyoutBody>
      <EuiFlyoutFooter>
        <EuiFlexGroup @justifyContent='spaceBetween' @alignItems='center'>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonEmpty
              @iconType='cross'
              @onClick={{set this 'flyout' false}}
              @flush='left'
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
  @tracked flyout = false;
  @tracked popover = false;
  @tracked position = 'static';
  @tracked theme = 'default';

  alerts = [
    {
      title: 'Control access to features',
      text: 'Show or hide applications and features per space in Kibana.',
      action: 'Learn about feature controls',
      date: '1 May 2019',
      badge: '7.1',
      badgeColor: 'default'
    },
    {
      title: 'Kibana 7.0 is turning heads',
      text: 'Simplified navigation, responsive dashboards, dark mode… pick your favorite.',
      action: 'Read the blog',
      date: '10 April 2019',
      badge: '7.0',
      badgeColor: 'hollow'
    },
    {
      title: 'Enter dark mode',
      text: 'Kibana now supports the easy-on-the-eyes theme across the entire UI.',
      action: 'Go to Advanced Settings',
      date: '10 April 2019',
      badge: '7.0',
      badgeColor: 'hollow'
    },
    {
      title: 'Pixel-perfect Canvas is production ready',
      text: 'Your creative space for visualizing data awaits.',
      action: 'Watch the webinar',
      date: '26 March 2019',
      badge: '6.7',
      badgeColor: 'hollow'
    },
    {
      title: '6.7 release notes',
      text: 'Stay up-to-date on the latest and greatest features.',
      action: 'Check out the docs',
      date: '26 March 2019',
      badge: '6.7',
      badgeColor: 'hollow'
    },
    {
      title: 'Rollups made simple in Kibana',
      text: 'Save space and preserve the integrity of your data directly in the UI.',
      action: 'Read the blog',
      date: '10 January 2019',
      badge: '6.5',
      badgeColor: 'hollow'
    }
  ];

  setPosition = (e) => {
    if (e.target.checked) {
      this.position = 'fixed';
    } else {
      this.position = 'static';
    }
  };

  setTheme = (e) => {
    if (e.target.checked) {
      this.theme = 'dark';
    } else {
      this.theme = 'default';
    }
  };
}
```
