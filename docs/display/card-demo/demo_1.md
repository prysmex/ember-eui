# Demo of Docfy Demos :D

```hbs template
This is my Demo: <EuiAvatar @name="Alberto" {{on "click" this.salute}}/>
```

```js component
import Component from '@glimmer/component';
import { action } from '@ember/object';

export default class MyDemo extends Component {
  @action
  salute() {
    alert('hey')
  }
}
```