import { modifier } from 'ember-modifier';

export default modifier(function openCollapsibleNav(_, [navIsDocked]) {

  if (navIsDocked) {
    document.body.classList.add('euiBody--collapsibleNavIsDocked');
  }
  document.body.classList.add('euiBody--collapsibleNavIsOpen');

  return () => {
    if (navIsDocked) {
      document.body.classList.remove('euiBody--collapsibleNavIsDocked');
    }
    document.body.classList.remove('euiBody--collapsibleNavIsOpen');
  };

});