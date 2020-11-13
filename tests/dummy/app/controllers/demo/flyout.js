import Controller from '@ember/controller';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoHeaderController extends Controller {

  @tracked flyout1Open = false;
  @tracked flyout2Open = false;
  @tracked flyout3Open = false;
  @tracked notificationFlyoutOpen = false;

  notifications = [
    {
      title: "Heads up!",
      description: "This is a test notification, you can ignore it. But please checkout the rest of them",
      time: "1 hour ago"
    },
    {
      title: "New Report",
      description: "An accident has been reported near your zone. Do what is possible to help in any way.",
      time: "1 hour ago"
    },
    {
      title: "Waiting for Review",
      description: "Your review has been requested in GitHub, regarding the Ember EUI repository.",
      time: "2 hours ago"
    },
    {
      title: "All in!",
      description: "There's been a report of gambling in the office, that's prohibited! Anyway, care for a hand?",
      time: "1 day ago"
    }
  ]

  @action
  openFlyout(flyout){
    this.set(flyout, true);
  }

  @action
  closeFlyout(flyout){
    this.set(flyout, false);
  }

  @action
  toggleNotificationFlyout() {
    this.toggleProperty('notificationFlyoutOpen');
  }

}