import { modifier } from 'ember-modifier';

const hasOwnProperty = function (obj: MutationObserverInit, name: string): boolean {
  return Object.prototype.hasOwnProperty.call(obj, name);
};

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
    ..._observerOptions
  };
  const needsAttributes =
    hasOwnProperty(observerOptions, 'attributeOldValue') ||
    hasOwnProperty(observerOptions, 'attributeFilter');
  if (needsAttributes && !hasOwnProperty(observerOptions, 'attributes')) {
    observerOptions.attributes = true;
  }

  const observer = new MutationObserver(callback);

  //eslint-disable-next-line
  observer.observe(node, observerOptions);

  return observer;
};

export default modifier(function useMutationObserver(
  element: HTMLElement,
  _positional,
  {
    onMutation,
    observerOptions
  }: { onMutation: MutationCallback; observerOptions: MutationObserverInit }
): void | (() => unknown) {
  if (element != null) {
    const observer = makeMutationObserver(element, observerOptions, onMutation);
    //eslint-disable-next-line
    return () => observer.disconnect();
  }
});
