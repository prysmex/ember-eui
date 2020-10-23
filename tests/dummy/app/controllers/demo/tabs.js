import Controller from '@ember/controller';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class DemoTabsController extends Controller {
  @tracked tabIndex2 = 0;

  constructor() {
    super(...arguments);

    this.tabsItems1 = [
      {
        id: 'example1',
        name: 'Example 1',
        content: 'Example 1 content.',
      },
      {
        id: 'example2',
        name: 'Example 2',
        content: 'Example 2 content.',
      },
    ];

    this.tabsItems2 = [
      {
        id: 'one',
        name: 'Click me 1!',
        content: 'Same ol\' 1 content.',
      },
      {
        id: 'two',
        name: 'Click me 2!',
        content: 'Same ol\' 2 content.',
      },
      {
        id: 'three',
        name: 'Click me 3!',
        content: 'Same ol\' 3 content.',
      }
    ];
  }

  sayMyName (tab) {
    alert(`I am ${tab.name || tab.id}`);
  }

  @action
  cycleTabs () {
    this.tabIndex2++;

    if (this.tabIndex2 >= this.tabsItems2.length) {
      this.tabIndex2 = 0;
    }
  }
}
