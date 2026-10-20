// Ember alone (a Glimmer component and a template): subtracted from every
// other entry.
import Component from '@glimmer/component';

class Probe extends Component {
  get greeting() {
    return 'hi';
  }

  <template>{{this.greeting}}{{yield}}</template>
}

console.log(Probe);
