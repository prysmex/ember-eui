import Controller from '@ember/controller';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoHeaderController extends Controller {

  @tracked header1Fixed = false;
  @tracked header2Fixed = false;

  @action
  toggleHeaderPosition(header){
    this.toggleProperty(header);
  }

}