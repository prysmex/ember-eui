import Controller from '@ember/controller';
import { action } from '@ember/object';

export default class DemoSideNavController extends Controller {
  @action
  onMouseOut () {
    alert('I don\'t wanna go, I don\'t wanna go...');
  }
}
