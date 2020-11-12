import Controller from '@ember/controller';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class DemoCardController extends Controller {

  @tracked selectedIconButton = false;
  @tracked button1On = false;
  @tracked button2On = false;
  @tracked button3On = false;

  @action
  toggleIconButton () {
    this.toggleProperty('selectedIconButton');
  }

  @action
  clickedButton () {
    alert('You clicked a button!');
  }

  @action
  toggleButtonState (btn) {
    this.toggleProperty(btn);
  }
}