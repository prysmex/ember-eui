declare module 'ember-unique-id-helper-polyfill/helpers/unique-id' {
  import Helper from '@ember/component/helper';

  export default class UniqueIdHelper extends Helper<{
    Args: {
      Positional: [];
    };
    Return: string;
  }> {}
}
