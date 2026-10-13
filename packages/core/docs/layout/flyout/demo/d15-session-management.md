---
order: 15
---

# Session management

<EuiCallOut @title="Beta" @color="accent" @iconType="beta">
  Flyout session management is in beta upstream and may change in the future.
</EuiCallOut>

<EuiSpacer />

<EuiText>

`EuiFlyout` comes with opt-in flyout session management built in that lets
you create complex flyout compositions and journeys. It handles side-by-side
flyout rendering based on parent-child grouping, simple flyout transitions,
state sharing, and more.

#### Sessions

The `@session` argument is the key ingredient of managed flyouts. Each time
you set `@session="start"`, you create a new flyout session and mark the
rendered flyout as its **main** flyout. To create a **child** flyout (one
that belongs to the same session as the main flyout) either render it in
the main flyout's block, or set `@session="inherit"` while a main flyout is
open. A flyout nested in another flyout without `@session` joins the active
session automatically. `@session="never"`, or a flyout that is not nested,
keeps the standard behavior. As upstream, a standard flyout nested in a
managed flyout takes the session's stacking and Escape rules, and a pushed
one does not pad the page (only the active session's flyouts push).

Managed flyouts work alongside managed and standard flyouts across the
application. The state lives in the `eui-flyout-manager` service (upstream's
flyout manager store).

**Session title**: sessions are named in the history by `title` of
`@flyoutMenuProps`, else the flyout's `aria-label`, else a default title. The
title is visually hidden in the menu; use `EuiFlyoutHeader` for the visible
heading. **Session icon**: `iconType` of `@flyoutMenuProps` is shown next to
the title in the history popover.

**History** (`@historyKey`): every `@session="start"` flyout gets its own
history group unless flyouts share the same `Symbol` as `@historyKey`. A new
main flyout in the same group hides the previous one and adds a Back button
(and, from two entries, a history popover) to its menu. The example below
shares a key so Flyout B can go back to Flyout A. Closing a managed flyout
closes every flyout of its history group.

#### Main and child flyouts

Main flyouts are the backbone: they display primary information (like the
overview of an alert) and are what the history navigates between. Child
flyouts display secondary information next to their main flyout; they are
always overlays without their own mask or focus, default to `@size="s"`
(main flyouts to `"m"`), and `@hasChildBackground={{true}}` gives them the
subdued background. When there is not enough room (narrow windows or
containers) children stack over their main flyout. Main and child sizes are
validated like upstream: a child needs a named size, they cannot both be
`m` or both `fill`, and `l` requires the other to be `fill`.

#### Accessibility

Side by side, the main flyout and its child form one modal unit: the main
flyout carries `role="dialog"` and `aria-modal="true"`, the child defers to
it, and Tab moves between both. Stacked, the child is its own modal dialog.
Escape closes the child first, then the main flyout.

#### Closing behavior

Keep simple state: set your flag to `false` in `@onClose`. The flyout updates
the manager before it calls `@onClose`, and closing a main flyout closes its
children (each child's `@onClose` is called with
`{ reason: 'navigation-cascade' }`), so there is no need for manual cascade
logic. Back and history navigation call `@onClose` of the flyouts they leave
with `'navigation-back'` or `'navigation-cascade'`.

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
  EuiFieldText,
  EuiFlyout,
  EuiFlyoutBody,
  EuiFlyoutHeader,
  EuiFormRow,
  EuiSpacer,
  EuiText,
  EuiTitle
} from '@ember-eui/core/components';

// Flyouts A and B share a history group, so B can go back to A.
const journey = Symbol('journey');

export default class FlyoutSessionManagementComponent extends Component {
  journey = journey;
  @tracked isOpenFlyoutA = false;
  @tracked isOpenFlyoutB = false;
  @tracked isOpenFlyoutBChild = false;
  @tracked name = '';

  @action openA() {
    this.isOpenFlyoutA = true;
  }

  @action closeA() {
    this.isOpenFlyoutA = false;
  }

  @action openB() {
    this.isOpenFlyoutB = true;
  }

  @action closeB() {
    this.isOpenFlyoutB = false;
  }

  @action toggleBChild() {
    this.isOpenFlyoutBChild = !this.isOpenFlyoutBChild;
  }

  @action closeBChild() {
    this.isOpenFlyoutBChild = false;
  }

  @action closeAll() {
    this.isOpenFlyoutB = false;
    this.isOpenFlyoutA = false;
  }

  @action setName(event) {
    this.name = event.target.value;
  }

  <template>
  <EuiButton @isDisabled={{this.isOpenFlyoutA}} {{on "click" this.openA}}>Open Flyout A</EuiButton>

  {{#if this.isOpenFlyoutA}}
    <EuiFlyout
      @session="start"
      @historyKey={{this.journey}}
      @size="s"
      @flyoutMenuProps={{hash title="Flyout A"}}
      @onClose={{this.closeA}}
      aria-labelledby="welcomeHeading"
    >
      <EuiFlyoutHeader>
        <EuiTitle><h2 id="welcomeHeading">Welcome to the flyout session management journey!</h2></EuiTitle>
      </EuiFlyoutHeader>
      <EuiFlyoutBody>
        <EuiText>
          This is <strong>Flyout A</strong>. This flyout is rendered with
          <EuiCode>@session="start"</EuiCode>, which created a new flyout
          session and marks this flyout as main.
        </EuiText>
        <EuiSpacer />
        <EuiFormRow @label="What's your name?" @fullWidth={{true}}>
          <EuiFieldText @value={{this.name}} @fullWidth={{true}} {{on "input" this.setName}} />
        </EuiFormRow>
        <EuiSpacer />
        <EuiButton {{on "click" this.openB}}>Next step</EuiButton>
      </EuiFlyoutBody>
    </EuiFlyout>
  {{/if}}

  {{#if this.isOpenFlyoutB}}
    <EuiFlyout
      @session="start"
      @historyKey={{this.journey}}
      @size="m"
      @flyoutMenuProps={{hash title="Flyout B"}}
      @onClose={{this.closeB}}
      aria-labelledby="flyoutBHeading"
    >
      <EuiFlyoutHeader>
        <EuiTitle><h2 id="flyoutBHeading">Glad to meet you, {{if this.name this.name "stranger"}}!</h2></EuiTitle>
      </EuiFlyoutHeader>
      <EuiFlyoutBody>
        <EuiText>
          This is <strong>Flyout B</strong>. This flyout is also rendered with
          <EuiCode>@session="start"</EuiCode>, which creates a
          <strong>second flyout session</strong> and marks this flyout as main
          in that session.
          <br /><br />
          <strong>Flyout A</strong> exists but is hidden since this one took
          precedence. Both share a <EuiCode>@historyKey</EuiCode>, so you can
          jump back to it with the <i>Back</i> button above.
        </EuiText>
        <EuiSpacer />
        <EuiButton {{on "click" this.toggleBChild}}>
          {{if this.isOpenFlyoutBChild "Close child flyout" "Open child flyout"}}
        </EuiButton>
      </EuiFlyoutBody>
      {{#if this.isOpenFlyoutBChild}}
        <EuiFlyout @size="s" @onClose={{this.closeBChild}} aria-label="Child of Flyout B">
          <EuiFlyoutBody>
            <EuiText>
              This is a <strong>child flyout</strong> of Flyout B. It belongs
              to the same session as Flyout B because it's rendered in its
              block.
              <br /><br />
              If you close <i>Flyout B</i>, this flyout will close, too.
            </EuiText>
            <EuiSpacer />
            <EuiText>Try out the Back button to transition back to Flyout A.</EuiText>
            <EuiSpacer />
            <EuiButton {{on "click" this.closeAll}}>Close all</EuiButton>
          </EuiFlyoutBody>
        </EuiFlyout>
      {{/if}}
    </EuiFlyout>
  {{/if}}
  </template>
}
```
