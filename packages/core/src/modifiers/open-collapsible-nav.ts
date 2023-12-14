import { modifier } from 'ember-modifier';

let counter = 0;

export default modifier(function openCollapsibleNav(
  _,
  [navIsDocked]: [boolean]
) {
  counter++;

  if (navIsDocked) {
    document.body.classList.add('euiBody--collapsibleNavIsDocked');
  }

  document.body.classList.add('euiBody--collapsibleNavIsOpen');

  return (): void => {
    counter--;

    if (!counter) {
      if (navIsDocked) {
        document.body.classList.remove('euiBody--collapsibleNavIsDocked');
      }

      document.body.classList.remove('euiBody--collapsibleNavIsOpen');
    }
  };
});
