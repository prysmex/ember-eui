import { modifier } from 'ember-modifier';

export default modifier(function openCollapsibleNav(_) {

  document.body.classList.add('euiBody--collapsibleNavIsOpen');

  return () => {
    document.body.classList.remove('euiBody--collapsibleNavIsOpen');
  };

});