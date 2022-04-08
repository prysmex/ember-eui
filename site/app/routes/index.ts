import Route from '@ember/routing/route';

export default class Index extends Route {
  // normal class body definition here
  beforeModel() {
    this.replaceWith('docs.introduction');
  }
}
