import { helper } from '@ember/component/helper';

const EVENT_TYPE = 'Event';
const KEYBOARD_EVENT = 'KeyboardEvent';
const INPUT_EVENT = 'InputEvent';
const MOUSE_EVENT = 'MouseEvent';
const DEFAULT_TRIGGER = 'click';

type Configuration = {
  eventType: string;
  trigger: string;
  config: EventInit;
};

export function createEvent([
  { eventType = EVENT_TYPE, trigger = DEFAULT_TRIGGER, config }
]: [Configuration]) {
  switch (eventType) {
    case KEYBOARD_EVENT:
      return new KeyboardEvent(trigger, config);
    case INPUT_EVENT:
      return new InputEvent(trigger, config);
    case MOUSE_EVENT:
      return new MouseEvent(trigger, config);
    default:
      return new Event(trigger, config);
  }
}

export default helper(createEvent);
