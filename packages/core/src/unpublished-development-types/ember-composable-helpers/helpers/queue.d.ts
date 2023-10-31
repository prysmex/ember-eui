declare module 'ember-composable-helpers/helpers/queue' {
  import Helper from '@ember/component/helper';

  export default class QueueHelper extends Helper<{
    Args: {
      Positional: [...Function[]];
    };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    Return: any;
  }> {}
}
