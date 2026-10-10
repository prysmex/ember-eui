---
order: 2
---

# Restricting page width

<EuiText>
  The template defaults to the Amsterdam theme's 1200px maximum width.
  Use a number for pixels, a CSS string for another unit, or false for no limit.
  The header and content can also override this through their own props.
</EuiText>

```hbs template
<EuiFlexGroup @gutterSize='s' @wrap={{true}}>
  <EuiFlexItem @grow={{false}}><EuiButton {{on 'click' (fn this.setWidth true)}}>Default width</EuiButton></EuiFlexItem>
  <EuiFlexItem @grow={{false}}><EuiButton {{on 'click' (fn this.setWidth 840)}}>840px</EuiButton></EuiFlexItem>
  <EuiFlexItem @grow={{false}}><EuiButton {{on 'click' (fn this.setWidth '75%')}}>75%</EuiButton></EuiFlexItem>
  <EuiFlexItem @grow={{false}}><EuiButton {{on 'click' (fn this.setWidth false)}}>Full width</EuiButton></EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiPageTemplate
  @restrictWidth={{this.width}}
  @pageHeader={{hash pageTitle='Choose a page width'}}
>
  <:pageSideBar><EuiLoadingContent @lines={{8}} /></:pageSideBar>
  <:default><EuiLoadingContent @lines={{16}} /></:default>
</EuiPageTemplate>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class PageWidthDemo extends Component {
  @tracked width = true;

  setWidth = (width) => {
    this.width = width;
  };
}
```
