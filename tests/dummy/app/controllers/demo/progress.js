import Controller from '@ember/controller';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { computed } from '@ember/object';

export default class DemoProgressController extends Controller {
  @tracked value1 = 0;

  @computed('value1')
  get value1Text() {
    if (this.value1 == 0) {
      return "Progress me!";
    }
    else if (this.value1 < 40) {
      return "Keep at it!";
    }
    else if (this.value1 >= 40 && this.value1 < 70) {
      return "Keep going!! Grind it!"
    }
    else if (this.value1 >= 70 && this.value1 < 100){
      return "Almost there!!"
    } else if (this.value1 == 100) {
      return "Nailed it!"
    }
  }

  @action
  increaseValue1() {
    if (this.value1 < 100) {
      this.value1 += 10;
    }
  }
}
