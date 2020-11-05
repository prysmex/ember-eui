import Controller from '@ember/controller';
import { tracked } from '@glimmer/tracking';

export default class DemoIconController extends Controller {
  @tracked imageUrl = "https://source.unsplash.com/64x64/?cat"

}