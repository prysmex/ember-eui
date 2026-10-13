---
order: 5
---

# Combining multiple skeletons

<EuiText>

**EuiSkeletonLoading** is a light wrapper around the **EuiSkeleton** components that handles loading accessibility and flipping between skeleton and loaded content.

As you may have noticed in the previous demos, toggling multiple skeletons to their loaded state all at once triggers multiple queued screen reader announcements, which can be annoying to screen reader users.

To circumvent this, use **EuiSkeletonLoading** to handle a single parent-level `@isLoading` state. **EuiSkeleton** children rendered in the `<:loadingContent>` block should not have their own `@isLoading` arguments or children.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiAvatar, EuiCard, EuiFlexGroup, EuiFlexItem, EuiPanel, EuiSkeletonCircle, EuiSkeletonLoading, EuiSkeletonRectangle, EuiSkeletonText, EuiSkeletonTitle, EuiSpacer, EuiSwitch, EuiText, EuiTitle } from '@ember-eui/core/components';

export default class SkeletonCombinedDemo extends Component {
  @tracked isLoading = true;

  @action
  toggleLoading() {
    this.isLoading = !this.isLoading;
  }

  <template>
    <EuiSwitch
      @label="Toggle loaded state"
      @checked={{this.isLoading}}
      @onChange={{this.toggleLoading}}
    />
    <EuiSpacer />
    <EuiSkeletonLoading @isLoading={{this.isLoading}} @contentAriaLabel="Demo loading section">
      <:loadingContent as |loading|>
        <EuiPanel role={{loading.role}} aria-label={{loading.ariaLabel}}>
          <EuiFlexGroup @alignItems="center" @gutterSize="s" @responsive={{false}}>
            <EuiFlexItem @grow={{false}}>
              <EuiSkeletonCircle @size="s" />
            </EuiFlexItem>
            <EuiFlexItem>
              <EuiSkeletonTitle @size="l" />
            </EuiFlexItem>
          </EuiFlexGroup>
          <EuiSpacer @size="s" />
          <EuiFlexGroup>
            <EuiFlexItem>
              <EuiSkeletonText @lines={{5}} />
            </EuiFlexItem>
            <EuiFlexItem>
              <EuiSkeletonRectangle @width="100%" @height={{148}} />
            </EuiFlexItem>
          </EuiFlexGroup>
        </EuiPanel>
      </:loadingContent>
      <:loadedContent>
        <EuiPanel>
          <EuiFlexGroup @alignItems="center" @gutterSize="s" @responsive={{false}}>
            <EuiAvatar @size="s" @name="Avatar" />
            <EuiTitle @size="l">
              <span>Example section title</span>
            </EuiTitle>
          </EuiFlexGroup>
          <EuiSpacer @size="s" />
          <EuiFlexGroup>
            <EuiFlexItem>
              <EuiText>
                <p>
                  This demo groups multiple skeleton types into a single loading
                  section by using <code>EuiSkeletonLoading</code>.
                </p>
                <p>
                  This is a significant usability improvement for screen readers as
                  only one loaded message is announced, as opposed to four.
                </p>
              </EuiText>
            </EuiFlexItem>
            <EuiFlexItem>
              <EuiCard
                @display="subdued"
                @icon="logoElastic"
                @title="Elastic Cloud"
                @description="Example card description."
              />
            </EuiFlexItem>
          </EuiFlexGroup>
        </EuiPanel>
      </:loadedContent>
    </EuiSkeletonLoading>
  </template>
}
```

