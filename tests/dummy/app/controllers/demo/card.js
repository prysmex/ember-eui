import Controller from '@ember/controller';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class DemoIconController extends Controller {

  @tracked cardOne = false;

	@action
	punchIt() {
		console.log("You punched it into hyperspace!!");
  }

  @action
  selectToggle(card){
    card = !card;
  }

}