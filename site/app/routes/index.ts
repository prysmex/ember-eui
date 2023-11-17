import Route from '@ember/routing/route';

class Index extends Route {
  // normal class body definition here
  beforeModel() {
    this.replaceWith('docs.introduction');
  }
}

export default Index;
