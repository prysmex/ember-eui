import { modifier } from 'ember-modifier';

export default modifier(function simulateEvent(element, eventName, {handler, targetElement}) {

  let _target = element.querySelector(targetElement);

  function _triggerEvent () {
    let _newEvent = _target[handler];
    typeof _newEvent === 'function' && _target[handler]();
  }

  if (targetElement) {
    element.addEventListener(eventName, _triggerEvent);
    return () => {
      element.removeEventListener(eventName, _triggerEvent);
      _target = null;
    };
  }

});
