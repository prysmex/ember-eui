import Controller from '@ember/controller';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoHeaderController extends Controller {

  @tracked flyout1Open = false;
  @tracked flyout2Open = false;
  @tracked flyout3Open = false;

  @action
  openFlyout(flyout){
    this.set(flyout, true);
  }

  @action
  closeFlyout(flyout){
    this.set(flyout, false);
  }

}