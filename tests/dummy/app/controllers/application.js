import Controller from '@ember/controller';
import { tracked } from '@glimmer/tracking';
import { inject as service } from '@ember/service';

export default class ApplicationController extends Controller {
  @service router;
  @tracked sideNavItems = [];
  @tracked isOpenMobile = true;

  createItem(name = '', data) {
    let onClick = data?.onClick ?? (() => {
      this.selectedItem = name;
    })
    return {
      ...data,
      id: data?.href ? data.href : name,
      name,
      ...(data?.href && { href: this.router.urlFor(data.href) }),
      onClick
    };
  }

  constructor() {
    super(...arguments);
    let createItem = this.createItem.bind(this);
    this.sideNavItems = [
      createItem('Layout', {
        onClick: false,
        items: [
          createItem('Accordion', {
            href: 'demo.accordion'
          }),
          createItem('Page', {
            href: 'demo.page'
          })
        ]
      }),
      createItem('Navigation', {
        onClick: false,
        items: [
          createItem('Side nav', {
            href: 'demo.side-nav',
          }),
          createItem('Button', {
            href: 'demo.button',
          }),
        ],
      }),
      createItem('Display', {
        onClick: false,
        items: [
          createItem('Avatar', {
            href: 'demo.avatar',
          }),
          createItem('Badge', {
            href: 'demo.badge',
          }),
          createItem('Callout', {
            href: 'demo.callout',
          }),
          createItem('Card', {
            href: 'demo.card',
          }),
          createItem('Icons', {
            href: 'demo.icon',
          }),
          createItem('Image', {
            href: 'demo.image',
          }),
          createItem('Loading', {
            href: 'demo.loading',
            items: [createItem('Spinner')],
          }),
          createItem('Text', {
            href: 'demo.text',
          }),
          createItem('Title', {
            href: 'demo.title',
          }),
        ],
      }),
      createItem('Utitilies', {
        onClick: false,
        items: [createItem('Overlay mask', { href: 'demo.overlay-mask' })],
      }),
    ];
  }
}