---
title: HTML ID generator
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="HTML ID generator"/>
<EuiSpacer @size="l" />

<EuiText>

Use `htmlIdGenerator()()` from `@ember-eui/core/utils/html-id-generator` to generate unique ids for elements, with an optional `prefix` and/or `suffix`. The first call accepts the prefix and returns a second function which accepts the suffix and returns the id. Calls that pass a suffix to the same generator share one unique part, so you can create related ids (`label` and `input`) together. A prefix should start with a letter; without one the id starts with `i`. Whitespace in a prefix or suffix logs a warning, because it breaks `for`, `aria-controls` and `aria-labelledby`.

```js
import { htmlIdGenerator } from '@ember-eui/core/utils/html-id-generator';

const generate = htmlIdGenerator('test');
generate();         // test_<unique>
generate('label');  // test_<shared>_label
generate('input');  // test_<shared>_input
```

**Differences from upstream:** the unique part is a random id (upstream uses a uuid v1). There is no `useGeneratedHtmlId` hook in Ember, because components are not re-run on every render: for an id that stays the same for the life of a component use Ember's built in `{{unique-id}}` helper in a template or `guidFor(this)` from `@ember/object/internals` in a class.

```hbs
{{#let (unique-id) as |id|}}
  <label for={{id}}>Name</label>
  <input id={{id}} />
{{/let}}
```

</EuiText>

<EuiSpacer />
