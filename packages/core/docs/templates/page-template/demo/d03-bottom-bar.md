---
order: 3
---

# Showing a bottom bar

<EuiText>

Adding an [`EuiBottomBar`](/docs/core/docs/layout/bottom-bar) can be tricky to use and account for any sidebars. `EuiPageTemplate` handles this nicely by yielding a `T.BottomBar` part for the contents of your bottom bar, which extends `EuiBottomBar`.

It uses the `sticky` position so that it sticks to the bottom of and remains within the bounds of the page body. This way it will never overlap the sidebar, no matter the screen size. It also means not needing to accommodate for the height of the bar in the body element.

It will also keep its content constrained to the `@restrictWidth` value so the contents are always horizontally aligned. Wherever you put it, it renders at the end of the main content, after the sections.

</EuiText>

<EuiSpacer />

<EuiCallOut @size="s" @color="warning" @title="Grow a section">
  <p>For proper alignment in case of short content, at least one <code>T.Section</code> must grow (<code>@grow</code>, true by default).</p>
</EuiCallOut>

```gjs component
import { EuiPageTemplate, EuiSkeletonText, EuiButton, EuiFlexGroup, EuiFlexItem, EuiText } from '@ember-eui/core/components';
import { on } from '@ember/modifier';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class PageTemplateBottomBarDemo extends Component {
  @tracked showSidebar = true;

  toggle = () => {
    this.showSidebar = !this.showSidebar;
  };

  <template>
    <EuiPageTemplate
      @restrictWidth={{false}}
      @bottomBorder="extended"
      @offset={{0}}
      @grow={{false}}
    >
      <:sidebar as |T|>
        {{#if this.showSidebar}}
          <T.Sidebar>
            <EuiSkeletonText @isLoading={{true}} @lines={{8}} />
          </T.Sidebar>
        {{/if}}
      </:sidebar>
      <:default as |T|>
        <T.Header
          @iconType="logoElastic"
          @pageTitle="Page title"
          @description="Header description."
        >
          <:rightSideItems as |Item|>
            <Item><EuiButton>Right side item</EuiButton></Item>
          </:rightSideItems>
        </T.Header>
        <T.Section>
          <EuiSkeletonText @isLoading={{true}} @lines={{6}} />
        </T.Section>
        <T.BottomBar @paddingSize="s">
          <EuiFlexGroup @alignItems="center" @justifyContent="spaceBetween" @responsive={{false}}>
            <EuiFlexItem @grow={{false}}>
              <EuiText @size="s"><p>Bottom text</p></EuiText>
            </EuiFlexItem>
            <EuiFlexItem @grow={{false}}>
              <EuiButton @color="text" @isSelected={{this.showSidebar}} {{on "click" this.toggle}}>
                Toggle Sidebar
              </EuiButton>
            </EuiFlexItem>
          </EuiFlexGroup>
        </T.BottomBar>
      </:default>
    </EuiPageTemplate>
  </template>
}
```
