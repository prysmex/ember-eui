import Controller from '@ember/controller';
import { action } from '@ember/object';

export default class DemoIconController extends Controller {

	@action
	punchIt() {
		console.log("You punched it into hyperspace!!");
  }

}