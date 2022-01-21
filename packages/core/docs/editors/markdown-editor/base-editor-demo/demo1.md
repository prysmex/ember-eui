---
order: 1
---

# Demo

```hbs template
<EuiMarkdownEditor @value={{this.value}} @onChange={{set this 'value'}} />
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiMarkdownEditor1 extends Component {
  @tracked value = `## 👋 Hello there!

I'm a **EuiMarkdownEditor** with:

- a \`height\` set to \`200\`
- my parent container is a flex item


### Things you should know

When my content is very long 😅

The preview height is automatically adjusted 😉

To avoid a scrollbar 😌

### That's why I look good 😍

- [ ] First Checkbox
- [ ] Second Checkbox
- [x] Third Checkbox

\`\`\`ts
class Human {
   get fullName() {
     return \`${this.name} ${this.lastName}\`;
   }
}
\`\`\`

\`\`\`golang
package main

import \"fmt\"

func main() {

	// \`var\` declares 1 or more variables.
	var a = "initial"
	fmt.Println(a)

	// You can declare multiple variables at once.
	var b, c int = 1, 2
	fmt.Println(b, c)

	// Go will infer the type of initialized variables.
	var d = true
	fmt.Println(d)

	// Variables declared without a corresponding
	// initialization are _zero-valued_. For example, the
	// zero value for an \`int\` is \`0\`.
	var e int
	fmt.Println(e)

	// The \`:=\` syntax is shorthand for declaring and
	// initializing a variable, e.g. for
	// \`var f string = "apple"\` in this case.
	f := "apple"
	fmt.Println(f)
}

\`\`\`

`;
}
```
