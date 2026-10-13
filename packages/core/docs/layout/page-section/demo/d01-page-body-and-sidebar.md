---
order: 1
---

# Page, body, and sidebar

<EuiText>

`EuiPage` is simply a flex wrapper that will automatically `@grow` to fill the height of a flex container. You can also control the flex `@direction` and the maximum width using `@restrictWidth` which centers the page when it reaches the provided value (or `1200px` if set to `true`).

`EuiPageSidebar` doesn't contain many configurations itself, but it does dictate how the rest of the page contents should be displayed. Typically you'll want to wrap all your page contents in `EuiPageBody` and set `@panelled={{true}}` when you have a side bar.

The upstream fake sidebar and paragraph images are replaced here by skeleton text.

</EuiText>

```gjs component
import { EuiFlexGroup, EuiSwitch, EuiPage, EuiPageSidebar, EuiSkeletonText, EuiPageBody, EuiPageSection } from '@ember-eui/core/components';
import { fn } from '@ember/helper';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class PageBodySidebarDemo extends Component {
  @tracked sideBar = true;
  @tracked grow = true;
  @tracked column = false;
  @tracked restrictWidth = false;

  @action
  set(key, event) {
    this[key] = event.target.checked;
  }

  <template>
    <div style="overflow: hidden; height: 460px; display: flex; flex-direction: column;">
      <EuiFlexGroup @responsive={{false}} style="padding: 12px; flex-grow: 0;">
        <EuiSwitch @label="Sidebar" @checked={{this.sideBar}} @onChange={{fn this.set "sideBar"}} />
        <EuiSwitch @label="Grow" @checked={{this.grow}} @onChange={{fn this.set "grow"}} />
        <EuiSwitch @label="Column" @checked={{this.column}} @onChange={{fn this.set "column"}} />
        <EuiSwitch @label="Restrict width" @checked={{this.restrictWidth}} @onChange={{fn this.set "restrictWidth"}} />
      </EuiFlexGroup>
      <EuiPage
        @direction={{if this.column "column" "row"}}
        @grow={{this.grow}}
        @paddingSize="none"
        @restrictWidth={{if this.restrictWidth "75%" false}}
      >
        {{#if this.sideBar}}
          <EuiPageSidebar @paddingSize="l">
            <EuiSkeletonText @isLoading={{true}} @lines={{8}} />
          </EuiPageSidebar>
        {{/if}}
        <EuiPageBody @paddingSize="none" @panelled={{this.sideBar}}>
          <EuiPageSection>
            <EuiSkeletonText @isLoading={{true}} @lines={{10}} />
          </EuiPageSection>
        </EuiPageBody>
      </EuiPage>
    </div>
  </template>
}
```
