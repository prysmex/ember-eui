import Controller from '@ember/controller';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class DemoIconController extends Controller {

  @tracked cardOneSelected = false;
  @tracked cardTwoSelected = false;
  @tracked cardThreeSelected = false;
  @tracked cardFourSelected = false;

  @tracked weaponLocked = true;

	@action
	punchIt() {
		console.log("You punched it into hyperspace!!");
  }

  @action
  selectToggle(card, event){
    this.toggleProperty(card);
    event.stopPropagation();
  }

}