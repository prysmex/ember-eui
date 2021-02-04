import { modifier } from 'ember-modifier';

export default modifier(function openFlyout(_) {

  document.body.classList.add('euiBody--hasFlyout');

  return () => {
    document.body.classList.remove('euiBody--hasFlyout');
  };

});
