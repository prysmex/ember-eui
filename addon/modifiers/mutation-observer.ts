import { modifier } from 'ember-modifier';

const makeMutationObserver = (
  node: Element,
  _observerOptions: MutationObserverInit | undefined,
  callback: MutationCallback
) => {
  // IE11 and the MutationObserver polyfill used in Kibana (for Jest) implement
  // an older spec in which specifying `attributeOldValue` or `attributeFilter`
  // without specifying `attributes` results in a `SyntaxError`.
  // The following logic patches the newer spec in which `attributes: true` can be
  // implied when appropriate (`attributeOldValue` or `attributeFilter` is specified).
  const observerOptions: MutationObserverInit = {
    ..._observerOptions,
  };
  const needsAttributes =
    observerOptions.hasOwnProperty('attributeOldValue') ||
    observerOptions.hasOwnProperty('attributeFilter');
  if (needsAttributes && !observerOptions.hasOwnProperty('attributes')) {
    observerOptions.attributes = true;
  }

  const observer = new MutationObserver(callback);
  observer.observe(node, observerOptions);

  return observer;
};

export default modifier(function useMutationObserver(
  element: HTMLElement,
  _positional,
  {
    onMutation,
    observerOptions,
  }: { onMutation: MutationCallback; observerOptions: MutationObserverInit }
) {
  if (element != null) {
    const observer = makeMutationObserver(element, observerOptions, onMutation);
    return () => observer.disconnect();
  }
});
