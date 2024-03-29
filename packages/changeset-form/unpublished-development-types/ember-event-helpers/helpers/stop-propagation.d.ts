declare module 'ember-event-helpers/helpers/stop-propagation' {
  import Helper from '@ember/component/helper';

  export default class StopPropagationHelper extends Helper<{
    Args: {
      Positional: [callback: Function];
    };

    Return: (event: Event) => any;
  }> {}
}
