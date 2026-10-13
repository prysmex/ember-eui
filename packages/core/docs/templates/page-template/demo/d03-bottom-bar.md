---
order: 3
---

# Showing a bottom bar

<EuiText>

Adding an `EuiBottomBar` can be tricky to use and account for any sidebars. `EuiPageTemplate` handles this nicely with a `<:bottomBar>` block for the contents of your bottom bar, which renders an `EuiBottomBar`.

It uses the `sticky` position so that it sticks to the bottom of and remains within the bounds of the page body. This way it will never overlap the sidebar, no matter the screen size. It also means not needing to accommodate for the height of the bar in the body element.

It will also keep its content constrained to the `@restrictWidth` value so the contents are always horizontally aligned.

Named blocks cannot be conditional, so the sidebar toggle below switches between two invocations of the template.

</EuiText>

```gjs component
import { EuiPageTemplate, EuiSkeletonText, EuiButton, EuiFlexGroup, EuiFlexItem, EuiText } from '@ember-eui/core/components';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class PageTemplateBottomBarDemo extends Component {
  @tracked showSidebar = true;

  @action
  toggle() {
    this.showSidebar = !this.showSidebar;
  }

  <template>
    {{#if this.showSidebar}}
      <EuiPageTemplate @grow={{false}} @restrictWidth={{false}} @bottomBarProps={{hash paddingSize="s"}}
        @pageHeader={{hash iconType="logoElastic" pageTitle="Page title" description="Header description."}}>
        <:pageSideBar><EuiSkeletonText @isLoading={{true}} @lines={{8}} /></:pageSideBar>
        <:pageHeaderRightSideItems as |Item|>
          <Item><EuiButton>Right side item</EuiButton></Item>
        </:pageHeaderRightSideItems>
        <:default><EuiSkeletonText @isLoading={{true}} @lines={{6}} /></:default>
        <:bottomBar>
          <EuiFlexGroup @alignItems="center" @justifyContent="spaceBetween" @responsive={{false}}>
            <EuiFlexItem @grow={{false}}><EuiText @size="s"><p>Bottom text</p></EuiText></EuiFlexItem>
            <EuiFlexItem @grow={{false}}>
              <EuiButton @color="text" @isSelected={{this.showSidebar}} {{on "click" this.toggle}}>Toggle Sidebar</EuiButton>
            </EuiFlexItem>
          </EuiFlexGroup>
        </:bottomBar>
      </EuiPageTemplate>
    {{else}}
      <EuiPageTemplate @grow={{false}} @restrictWidth={{false}} @bottomBarProps={{hash paddingSize="s"}}
        @pageHeader={{hash iconType="logoElastic" pageTitle="Page title" description="Header description."}}>
        <:pageHeaderRightSideItems as |Item|>
          <Item><EuiButton>Right side item</EuiButton></Item>
        </:pageHeaderRightSideItems>
        <:default><EuiSkeletonText @isLoading={{true}} @lines={{6}} /></:default>
        <:bottomBar>
          <EuiFlexGroup @alignItems="center" @justifyContent="spaceBetween" @responsive={{false}}>
            <EuiFlexItem @grow={{false}}><EuiText @size="s"><p>Bottom text</p></EuiText></EuiFlexItem>
            <EuiFlexItem @grow={{false}}>
              <EuiButton @color="text" @isSelected={{this.showSidebar}} {{on "click" this.toggle}}>Toggle Sidebar</EuiButton>
            </EuiFlexItem>
          </EuiFlexGroup>
        </:bottomBar>
      </EuiPageTemplate>
    {{/if}}
  </template>
}
```
