---
order: 4
---

# Configuration example

<EuiCallOut @title="EuiPageTemplate can handle all these configurations for you" @size="s" />

<EuiSpacer />

```gjs component
import { EuiFlexGroup, EuiSwitch, EuiPage, EuiPageSidebar, EuiSkeletonText, EuiPageBody, EuiPageSection, EuiPageHeader, EuiEmptyPrompt } from '@ember-eui/core/components';
import { fn } from '@ember/helper';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class PageConfigurationDemo extends Component {
  @tracked sideBar = true;
  @tracked pageHeader = true;
  @tracked emptyPrompt = false;

  get promptColor() {
    return this.pageHeader || this.sideBar ? 'subdued' : 'plain';
  }

  @action
  set(key, event) {
    this[key] = event.target.checked;
  }

  <template>
    <div style="overflow: hidden;">
      <EuiFlexGroup @responsive={{false}} style="padding: 12px;">
        <EuiSwitch @label="Sidebar" @checked={{this.sideBar}} @onChange={{fn this.set "sideBar"}} />
        <EuiSwitch @label="Page header" @checked={{this.pageHeader}} @onChange={{fn this.set "pageHeader"}} />
        <EuiSwitch @label="Empty prompt" @checked={{this.emptyPrompt}} @onChange={{fn this.set "emptyPrompt"}} />
      </EuiFlexGroup>
      <EuiPage @paddingSize="none">
        {{#if this.sideBar}}
          <EuiPageSidebar @paddingSize="l" @sticky={{true}}>
            <EuiSkeletonText @isLoading={{true}} @lines={{8}} />
          </EuiPageSidebar>
        {{/if}}
        <EuiPageBody @paddingSize="none" @panelled={{this.sideBar}}>
          {{#if this.pageHeader}}
            <EuiPageSection @bottomBorder={{if this.sideBar true "extended"}}>
              <EuiPageHeader @pageTitle="Page title" />
            </EuiPageSection>
          {{/if}}
          {{#if this.emptyPrompt}}
            <EuiPageSection
              @color={{if this.pageHeader "plain" "transparent"}}
              @alignment="center"
              @grow={{true}}
            >
              <EuiEmptyPrompt @title="No spice" @color={{this.promptColor}}>
                <:content>
                  <EuiSkeletonText @isLoading={{true}} @lines={{4}} />
                </:content>
              </EuiEmptyPrompt>
            </EuiPageSection>
          {{else}}
            <EuiPageSection @color="plain" @alignment="top" @grow={{true}}>
              <EuiSkeletonText @isLoading={{true}} @lines={{6}} />
            </EuiPageSection>
          {{/if}}
        </EuiPageBody>
      </EuiPage>
    </div>
  </template>
}
```
