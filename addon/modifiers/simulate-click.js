import { modifier } from 'ember-modifier';

export default modifier(function simulateClick(element, [targetId]) {

  function _targetClick (target) {
    element.querySelector(`#${targetId}`).click();
  }

  if (targetId) {
    element.addEventListener('click', _targetClick);
    return () => {
      element.removeEventListener('click', _targetClick)
    };
  }

});
