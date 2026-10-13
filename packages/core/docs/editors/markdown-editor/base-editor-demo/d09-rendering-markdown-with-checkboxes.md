---
order: 2
---

# Rendering markdown

<EuiText>

`EuiMarkdownFormat` renders markdown, e.g. content saved from an editor.
`@textSize` scales the text (`xs`, `s`, `m`, `relative`). To make task
list checkboxes clickable, handle `@replaceNode`: it receives the
checkbox's position in the source and its new text, to splice into your
value.

</EuiText>

```hbs template
<EuiPanel @hasBorder={{true}}>
  <EuiMarkdownFormat
    @value={{this.markdown}}
    @textSize="s"
    @replaceNode={{this.replaceNode}}
  />
</EuiPanel>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class MarkdownFormatDemo extends Component {
  @tracked markdown = `### Release checklist :rocket:

- [x] Update the changelog
- [ ] Tag the release
- [ ] Announce it

Questions? Ask in **#releases**.`;

  @action
  replaceNode(position, text) {
    const { start, end } = position;

    this.markdown =
      this.markdown.slice(0, start.offset) + text + this.markdown.slice(end.offset);
  }
}
```
