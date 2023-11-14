declare module 'ember-composable-helpers/helpers/pick' {
  import Helper from '@ember/component/helper';

  export default class PickHelper extends Helper<{
    Args: {
      Positional: [str: string, callback: (v: any) => unknown];
    };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    Return: <T>(e: T) => T[keyof T];
  }> {}
}
