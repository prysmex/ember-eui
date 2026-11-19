declare module 'ember-set-body-class/helpers/set-body-class' {
  import Helper from '@ember/component/helper';

  export default class SetBodyClassHelper extends Helper<{
    Args: {
      Positional: [str: string];
    };
    Return: string;
  }> {}
}
