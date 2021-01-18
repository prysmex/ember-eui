```hbs template
<EuiAvatar @name="Juan" {{on "click" this.hello}}/>
```

```js component
import Component from '@glimmer/component';
import { action } from '@ember/object';

export default class MyDemo extends Component {
	@action
	hello() {
		alert('hello')
	}
}
```