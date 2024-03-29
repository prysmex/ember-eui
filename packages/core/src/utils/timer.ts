import { cancel,later } from '@ember/runloop';
export default class Timer {
  // In a browser this is a number, but in node it's a NodeJS.Time (a
  // class). We don't care about this difference.
  id: ReturnType<typeof later> | undefined;
  callback: undefined | (() => void);
  finishTime: number | undefined;
  timeRemaining: number | undefined;

  constructor(callback: () => void, timeMs: number) {
    this.id = later(this.finish, timeMs);
    this.callback = callback;
    this.finishTime = Date.now() + timeMs;
    this.timeRemaining = undefined;
  }

  pause = (): void => {
    cancel(this.id as ReturnType<typeof later>);
    this.id = undefined;
    this.timeRemaining = (this.finishTime || 0) - Date.now();
  };

  resume = (): void => {
    this.id = later(this.finish, this.timeRemaining as number);
    this.finishTime = Date.now() + (this.timeRemaining || 0);
    this.timeRemaining = undefined;
  };

  clear = (): void => {
    cancel(this.id as ReturnType<typeof later>);
    this.id = undefined;
    this.callback = undefined;
    this.finishTime = undefined;
    this.timeRemaining = undefined;
  };

  finish = (): void => {
    if (this.callback) {
      this.callback();
    }

    this.clear();
  };
}
