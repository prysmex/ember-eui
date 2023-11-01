declare module 'ember-event-helpers/helpers/prevent-default' {
  import Helper from '@ember/component/helper';

  export default class PreventDefaultHelper extends Helper<{
    Args: {
      Positional: [callback: Function];
    };

    Return: (event: Event) => any;
  }> {}
}
