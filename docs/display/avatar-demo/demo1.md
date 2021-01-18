```hbs template
<EuiAvatar @name="Alberto" {{on "click" this.hello}}/>
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