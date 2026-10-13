---
order: 2
---

# Page sections

<EuiText>

`EuiPageSection` is a stackable component that is essentially an `EuiPanel` with args for quickly creating common usages. It is meant to be a direct descendent of `EuiPageBody`. You'll need to set `@grow={{false}}` to any content that you don't want to stretch within the page.

To create dividers between contents, use the `@bottomBorder` arg. The `'extended'` version ensures the border touches the sides of the parent. It also supports `@restrictWidth` and `@alignment` to align with common usages.

</EuiText>

```gjs component
import { EuiFlexGroup, EuiSwitch, EuiPageHeader, EuiPageSection, EuiSkeletonText } from '@ember-eui/core/components';
import { fn } from '@ember/helper';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class PageSectionsDemo extends Component {
  @tracked extendedBorder = true;
  @tracked centeredContent = false;
  @tracked restrictWidth = false;

  get width() {
    return this.restrictWidth ? '75%' : false;
  }

  get bottomBorder() {
    return this.extendedBorder ? 'extended' : true;
  }

  @action
  set(key, event) {
    this[key] = event.target.checked;
  }

  <template>
    <div style="overflow: hidden;">
      <EuiFlexGroup @responsive={{false}} style="padding: 12px;">
        <EuiSwitch @label="Extended border" @checked={{this.extendedBorder}} @onChange={{fn this.set "extendedBorder"}} />
        <EuiSwitch @label="Centered content" @checked={{this.centeredContent}} @onChange={{fn this.set "centeredContent"}} />
        <EuiSwitch @label="Restrict width" @checked={{this.restrictWidth}} @onChange={{fn this.set "restrictWidth"}} />
      </EuiFlexGroup>
      <EuiPageHeader
        @paddingSize="l"
        @restrictWidth={{this.width}}
        @bottomBorder={{this.bottomBorder}}
        @pageTitle="Page title"
        @description="EuiPageHeader accepts similar border, restrict width and padding args as EuiPageSection."
      />
      <EuiPageSection @restrictWidth={{this.width}} @bottomBorder={{this.bottomBorder}}>
        Secondary content
      </EuiPageSection>
      <EuiPageSection
        @restrictWidth={{this.width}}
        @alignment={{if this.centeredContent "center" "top"}}
        @grow={{this.centeredContent}}
      >
        <EuiSkeletonText @isLoading={{true}} @lines={{6}} />
      </EuiPageSection>
    </div>
  </template>
}
```
