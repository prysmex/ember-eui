---
order: 5
---

# Block (render prop)

<EuiText>

By default, `EuiTextTruncate` will automatically output the calculated truncated string. You can optionally override this by passing a block, which receives the truncated text and allows for more flexible text rendering.

The below example demonstrates a primary use case for the block and the `@truncationPosition` argument. If a user is searching for a specific word in truncated text, you can use `EuiHighlight` or `EuiMark` to highlight the search term, and passing the index of the found word to `@truncationPosition` ensures the search term is always visible to the user.

</EuiText>

<EuiCallOut @title='Keep the block content to the text' @color='warning' @iconType='warning'>
  Do not render excessive extra content alongside the text. The sizing logic will not account for it, and the truncation calculations will be off.
</EuiCallOut>

```hbs template
<EuiText>
  <EuiFormRow @label='Type to highlight text'>
    <EuiFieldText
      @value={{this.highlight}}
      @placeholder='For example, try typing "lazy", "mindful", "life", or "silly"'
      {{on 'input' this.setHighlight}}
    />
  </EuiFormRow>
  <EuiSpacer />
  <EuiPanel style='inline-size: 40ch; max-inline-size: 100%;'>
    <EuiTextTruncate
      @text={{this.text}}
      @truncation='startEnd'
      @truncationPosition={{this.highlightCenterPosition}}
      as |truncatedText|
    >
      {{#if (this.isLonger truncatedText)}}
        <EuiHighlight @search={{this.highlight}} @text={{truncatedText}} />
      {{else}}
        <EuiMark>{{truncatedText}}</EuiMark>
      {{/if}}
    </EuiTextTruncate>
  </EuiPanel>
</EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class extends Component {
  text =
    "But the dog wasn't lazy, it was just practicing mindfulness, so it had a greater sense of life-satisfaction than that fox with all its silly jumping.";

  @tracked highlight = '';

  get highlightCenterPosition() {
    const start = this.text.toLowerCase().indexOf(this.highlight.toLowerCase());
    return start + Math.floor(this.highlight.length / 2);
  }

  // Highlight everything if the search match is greater than the visible text
  isLonger = (truncatedText) => truncatedText.length > this.highlight.length;

  @action
  setHighlight(event) {
    this.highlight = event.target.value;
  }
}
```
