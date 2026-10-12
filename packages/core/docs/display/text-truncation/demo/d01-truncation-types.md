---
order: 1
---

# Truncation types

<EuiText>

Drag the slider to change the available width. Each type keeps a different
part of the text visible. Hover truncated text to see it in full.

</EuiText>

```hbs template
<EuiRange
  @min={{60}}
  @max={{600}}
  @value={{this.width}}
  @onChange={{this.setWidth}}
  @showInput={{true}}
  aria-label="Available width in pixels"
/>
<EuiSpacer />
<div style={{this.boxStyle}}>
  {{#each this.types as |type|}}
    <EuiText @size="s"><strong>{{type}}</strong></EuiText>
    <EuiTextTruncate @text={{this.text}} @truncation={{type}} />
    <EuiSpacer @size="s" />
  {{/each}}
</div>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { htmlSafe } from '@ember/template';

export default class TruncationTypes extends Component {
  @tracked width = 260;

  types = ['end', 'start', 'middle', 'startEnd'];
  text = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua';

  get boxStyle() {
    return htmlSafe(`width: ${this.width}px; max-width: 100%`);
  }

  @action
  setWidth(event) {
    this.width = Number(event.target.value);
  }
}
```
