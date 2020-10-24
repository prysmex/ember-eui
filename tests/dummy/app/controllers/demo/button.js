import Controller from '@ember/controller';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class DemoCardController extends Controller {

  @tracked selectedIconButton = false;

  @action
  toggleIconButton () {
    this.toggleProperty('selectedIconButton');
  }

}