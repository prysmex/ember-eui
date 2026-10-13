---
order: 6
---

# Customizing screen reader announcements

<EuiText>

**EuiSkeleton** components assume that the page starts as loading and transitions to loaded, and the default screen reader experience is set up accordingly (`@announceLoadedStatus={{true}}`).

In scenarios where that is not the case (i.e., transitioning to loading), you can customize what statuses are announced to screen readers by setting `@announceLoadingStatus` to true, or `@announceLoadedStatus` to false. Submitting the below example announces a loading status, but not a loaded status.

As an optional escape hatch, `@ariaLiveProps` is also available and accepts any [**EuiScreenReaderLive**](/docs/utilities/accessibility) props.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { registerDestructor } from '@ember/destroyable';
import { EuiButton, EuiFieldText, EuiFlexGroup, EuiFlexItem, EuiSkeletonLoading, EuiSkeletonRectangle } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

export default class SkeletonAnnouncementsDemo extends Component {
  @tracked isLoading = false;

  // Allows customizing the aria-live region
  ariaLiveProps = { role: 'alert' };
  timer = null;

  constructor(owner, args) {
    super(owner, args);
    registerDestructor(this, () => clearTimeout(this.timer));
  }

  @action
  simulateLoading(event) {
    event.preventDefault();
    this.isLoading = true;
    this.timer = setTimeout(() => {
      this.isLoading = false;
    }, 3000);
  }

  <template>
    <EuiSkeletonLoading
      @isLoading={{this.isLoading}}
      @announceLoadedStatus={{false}}
      @announceLoadingStatus={{true}}
      @ariaLiveProps={{this.ariaLiveProps}}
      @contentAriaLabel="Demo form"
    >
      <:loadingContent as |loading|>
        <EuiSkeletonRectangle
          @width="100%"
          @height={{40}}
          role={{loading.role}}
          aria-label={{loading.ariaLabel}}
        />
      </:loadingContent>
      <:loadedContent>
        <form {{on "submit" this.simulateLoading}}>
          <EuiFlexGroup @alignItems="center" @gutterSize="s" @responsive={{false}}>
            <EuiFlexItem>
              <EuiFieldText
                @fullWidth={{true}}
                @value="Replaced with a loading skeleton on submit"
                aria-label="Input that transitions to loading"
              />
            </EuiFlexItem>
            <EuiFlexItem @grow={{false}}>
              <EuiButton @type="submit" @fill={{true}}>Submit</EuiButton>
            </EuiFlexItem>
            <EuiFlexItem @grow={{false}}>
              <EuiButton>Cancel</EuiButton>
            </EuiFlexItem>
          </EuiFlexGroup>
        </form>
      </:loadedContent>
    </EuiSkeletonLoading>
  </template>
}
```

