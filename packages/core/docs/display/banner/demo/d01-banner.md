---
order: 1
---

# Sizes and colors

<EuiText>

The default `'m'` banner on the `'highlighted'` background, and a compact
`'s'` banner on `'plain'`. Dismiss the first one to remove it.

</EuiText>

```hbs template
{{#if this.isVisible}}
  <EuiBanner
    @title="Try the new dashboards"
    @text="Build visualizations faster with the new drag and drop editor."
    @actionProps={{hash
      primary=(hash children="Try it" onClick=this.dismiss)
      secondary=(hash children="Learn more" href="#")
    }}
    @onDismiss={{this.dismiss}}
  >
    <:media>{{{this.art}}}</:media>
  </EuiBanner>
{{else}}
  <EuiButton @size="s" {{on "click" this.show}}>Show the banner again</EuiButton>
{{/if}}
<EuiSpacer />
<EuiBanner
  @size="s"
  @color="plain"
  @title="Scheduled maintenance"
  @text="Saturday 02:00–04:00 UTC."
>
  <:media>{{{this.art}}}</:media>
</EuiBanner>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { htmlSafe } from '@ember/template';

export default class BannerDemo extends Component {
  @tracked isVisible = true;

  art = htmlSafe(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" role="presentation">' +
      '<rect width="80" height="80" rx="12" fill="#BFDBFF"/>' +
      '<rect x="14" y="40" width="12" height="26" rx="2" fill="#0B64DD"/>' +
      '<rect x="34" y="26" width="12" height="40" rx="2" fill="#1750BA"/>' +
      '<rect x="54" y="14" width="12" height="52" rx="2" fill="#0B64DD"/></svg>'
  );

  @action dismiss() {
    this.isVisible = false;
  }

  @action show() {
    this.isVisible = true;
  }
}
```
