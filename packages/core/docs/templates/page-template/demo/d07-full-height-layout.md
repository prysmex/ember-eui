---
order: 7
---

# Full height layout

<EuiText>
  Full height is supported by the default and empty templates on medium screens
  and above (768px). This demo provides a 480px parent and sets minHeight to zero;
  otherwise the page defaults to a 460px minimum. A CSS height string is also
  accepted. On smaller screens, the content returns to normal page flow.
  Choose automatic scrolling, or noscroll with a child that manages its own
  scrolling. The centered templates ignore fullHeight.
</EuiText>
<EuiSpacer />
<EuiCallOut @iconType="accessibility">
  <:title>Give custom scroll regions an accessible name and tabindex="0" so keyboard users can reach them.</:title>
</EuiCallOut>

```hbs template
<EuiFlexGroup @gutterSize='s' @wrap={{true}}>
  <EuiFlexItem @grow={{false}}><EuiButton {{on 'click' (fn this.setMode true)}}>Automatic scrolling</EuiButton></EuiFlexItem>
  <EuiFlexItem @grow={{false}}><EuiButton {{on 'click' (fn this.setMode 'noscroll')}}>Child scrolling</EuiButton></EuiFlexItem>
  <EuiFlexItem @grow={{false}}><EuiButton {{on 'click' (fn this.setMode false)}}>Normal flow</EuiButton></EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<div style='height: 480px; display: flex; flex-direction: column; overflow: auto;'>
  <EuiPageTemplate @template='empty' @fullHeight={{this.mode}} @minHeight={{0}}>
    <div
      class={{if (eq this.mode 'noscroll') 'eui-yScroll'}}
      tabindex='0'
      role='region'
      aria-label='Example page content'
    >
      <EuiText><p>Scroll to the end of this content.</p></EuiText>
      <EuiText>
        {{#each this.paragraphs as |paragraph|}}
          <p>{{paragraph}}</p>
        {{/each}}
      </EuiText>
      <EuiSpacer />
      <EuiText><p>End of content.</p></EuiText>
    </div>
  </EuiPageTemplate>
</div>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class FullHeightDemo extends Component {
  @tracked mode = true;

  paragraphs = Array.from({ length: 30 }, (_, index) =>
    `Paragraph ${index + 1}: This content is taller than the example's parent. Scroll within the page or choose a different scrolling mode.`
  );

  setMode = (mode) => {
    this.mode = mode;
  };
}
```
