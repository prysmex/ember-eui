---
order: 3
---

# Nav groups with lists and other content

<EuiText>

**EuiCollapsibleNavGroups** can contain any children. They work well with **EuiListGroup**, **EuiPinnableListGroup** and simple **EuiText**.

Below are a few established patterns to use.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { EuiButton, EuiButtonIcon, EuiCollapsibleNavGroup, EuiLink, EuiListGroup, EuiPinnableListGroup, EuiSpacer, EuiText, EuiToolTip } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  deploymentsList = [
    { label: 'combining-binaries', iconType: 'logoAzureMono', size: 's' },
    { label: 'stack-monitoring', iconType: 'logoAWSMono', size: 's' }
  ];

  topNavLinks = [
    { label: 'Home', iconType: 'home', isActive: true, pinnable: false },
    { label: 'Dashboards', pinned: true },
    { label: 'Dev tools', pinned: true },
    { label: 'Maps', pinned: true }
  ];

  kibanaNavLinks = [
    { label: 'Discover' },
    { label: 'Visualize' },
    { label: 'Dashboards' },
    { label: 'Canvas' },
    { label: 'Maps' },
    { label: 'Machine Learning' },
    { label: 'Graph' }
  ];

  @action
  noop() {}

  <template>
    <EuiCollapsibleNavGroup
      @iconType="logoGCPMono"
      @iconSize="xl"
      @isCollapsible={{true}}
      @initialIsOpen={{false}}
      @background="dark"
    >
      <:title>
        <span>
          <small style="font-weight: normal">Deployment</small> <br />
          <strong>personal-databoard</strong>
        </span>
      </:title>
      <:content>
        <EuiListGroup @listItems={{this.deploymentsList}} @flush={{true}} />
        <EuiSpacer @size="s" />
        <EuiButton @fullWidth={{true}}>Manage deployments</EuiButton>
      </:content>
    </EuiCollapsibleNavGroup>

    <EuiCollapsibleNavGroup @background="light">
      <:content>
        <EuiPinnableListGroup
          @listItems={{this.topNavLinks}}
          @onPinClick={{this.noop}}
          @maxWidth="none"
          @color="text"
          @gutterSize="none"
          @size="s"
        />
      </:content>
    </EuiCollapsibleNavGroup>

    <EuiCollapsibleNavGroup
      @iconType="logoKibana"
      @isCollapsible={{true}}
      @initialIsOpen={{true}}
    >
      <:title>Kibana</:title>
      <:content>
        <EuiPinnableListGroup
          @listItems={{this.kibanaNavLinks}}
          @onPinClick={{this.noop}}
          @maxWidth="none"
          @color="subdued"
          @gutterSize="none"
          @size="s"
        />
      </:content>
    </EuiCollapsibleNavGroup>

    <EuiCollapsibleNavGroup
      @background="light"
      @iconType="logoSecurity"
      @isCollapsible={{true}}
      @initialIsOpen={{true}}
      @arrowDisplay="none"
    >
      <:title>Elastic Security</:title>
      <:extraAction>
        <EuiToolTip @content="Hide and never show again" @disableScreenReaderOutput={{true}}>
          <EuiButtonIcon @iconType="cross" aria-label="Hide and never show again" />
        </EuiToolTip>
      </:extraAction>
      <:content>
        <EuiText @size="s" @color="subdued" style="padding: 0 8px 8px">
          <p>
            Threat prevention, detection, and response with SIEM and endpoint
            security.
            <br />
            <EuiLink>Learn more</EuiLink>
          </p>
        </EuiText>
      </:content>
    </EuiCollapsibleNavGroup>
  </template>
}
```
