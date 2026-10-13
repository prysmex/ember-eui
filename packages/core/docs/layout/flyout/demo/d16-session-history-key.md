---
order: 16
---

# Scoping history with historyKey

<EuiCallOut @title="Beta: flyout session management may change in the future." @color="accent" @iconType="beta" @size="s" />

<EuiSpacer />

<EuiText>

Several areas of a product can open `@session="start"` flyouts on their
own. By default each of them has its own history. Below, the two **Alerts**
buttons share a `@historyKey`, so their flyouts form one history group: use
the Back button or the history popover to move between them. **Logs** uses
another key, so its history is independent. Because `Symbol` identity is
compared, pass the **same** `Symbol` to every flyout of a group (create it
once, e.g. at module scope). `@historyKey` only matters on main flyouts;
children belong to their main flyout's session.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import {
  EuiButton,
  EuiCode,
  EuiFlexGroup,
  EuiFlexItem,
  EuiFlyout,
  EuiFlyoutBody,
  EuiFlyoutHeader,
  EuiText,
  EuiTitle
} from '@ember-eui/core/components';

const alertsKey = Symbol('alerts');
const logsKey = Symbol('logs');

export default class FlyoutHistoryKeyComponent extends Component {
  alertsKey = alertsKey;
  logsKey = logsKey;
  @tracked showAlertOverview = false;
  @tracked showAlertDetail = false;
  @tracked showLogs = false;

  @action openOverview() { this.showAlertOverview = true; }
  @action closeOverview() { this.showAlertOverview = false; }
  @action openDetail() { this.showAlertDetail = true; }
  @action closeDetail() { this.showAlertDetail = false; }
  @action openLogs() { this.showLogs = true; }
  @action closeLogs() { this.showLogs = false; }

  <template>
  <EuiFlexGroup @gutterSize="s" @responsive={{false}}>
    <EuiFlexItem @grow={{false}}>
      <EuiButton @iconType="bell" @isDisabled={{this.showAlertOverview}} {{on "click" this.openOverview}}>Alert overview</EuiButton>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiButton @iconType="bell" @isDisabled={{this.showAlertDetail}} {{on "click" this.openDetail}}>Alert detail</EuiButton>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiButton @iconType="logstashOutput" @isDisabled={{this.showLogs}} {{on "click" this.openLogs}}>Logs</EuiButton>
    </EuiFlexItem>
  </EuiFlexGroup>

  {{#if this.showAlertOverview}}
    <EuiFlyout
      @session="start"
      @size="s"
      @ownFocus={{false}}
      @historyKey={{this.alertsKey}}
      @flyoutMenuProps={{hash title="Alert overview" iconType="bell"}}
      @onClose={{this.closeOverview}}
      aria-labelledby="alertOverviewHeading"
    >
      <EuiFlyoutHeader>
        <EuiTitle><h2 id="alertOverviewHeading">Alert overview</h2></EuiTitle>
      </EuiFlyoutHeader>
      <EuiFlyoutBody>
        <EuiText>
          <p>
            This flyout shares a <EuiCode>@historyKey</EuiCode> with
            <strong>Alert detail</strong>. Open both to see them appear in the
            same history group.
          </p>
        </EuiText>
      </EuiFlyoutBody>
    </EuiFlyout>
  {{/if}}

  {{#if this.showAlertDetail}}
    <EuiFlyout
      @session="start"
      @size="s"
      @ownFocus={{false}}
      @historyKey={{this.alertsKey}}
      @flyoutMenuProps={{hash title="Alert detail" iconType="bell"}}
      @onClose={{this.closeDetail}}
      aria-labelledby="alertDetailHeading"
    >
      <EuiFlyoutHeader>
        <EuiTitle><h2 id="alertDetailHeading">Alert detail</h2></EuiTitle>
      </EuiFlyoutHeader>
      <EuiFlyoutBody>
        <EuiText>
          <p>
            This flyout shares a <EuiCode>@historyKey</EuiCode> with
            <strong>Alert overview</strong>. They form a single history group,
            connected by the Back button.
          </p>
        </EuiText>
      </EuiFlyoutBody>
    </EuiFlyout>
  {{/if}}

  {{#if this.showLogs}}
    <EuiFlyout
      @session="start"
      @size="s"
      @ownFocus={{false}}
      @historyKey={{this.logsKey}}
      @flyoutMenuProps={{hash title="Logs" iconType="logstashOutput"}}
      @onClose={{this.closeLogs}}
      aria-labelledby="logsHeading"
    >
      <EuiFlyoutHeader>
        <EuiTitle><h2 id="logsHeading">Logs</h2></EuiTitle>
      </EuiFlyoutHeader>
      <EuiFlyoutBody>
        <EuiText>
          <p>
            This flyout uses a different <EuiCode>@historyKey</EuiCode> than the
            Alerts flyouts. Its history is completely independent.
          </p>
        </EuiText>
      </EuiFlyoutBody>
    </EuiFlyout>
  {{/if}}
  </template>
}
```
