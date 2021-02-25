import { helper } from '@ember/component/helper';

export interface EuiRangeTick {
  value: number;
  label: string;
}

export function getRangeTick([ticks, tickValue, min, max, percentageWidth]: [
  EuiRangeTick[],
  number,
  number,
  number,
  number
]) {
  let tickStyle: string = '';
  let customTick;
  if (ticks) {
    customTick = ticks.find((o) => o.value === tickValue);

    if (customTick) {
      tickStyle = `left: ${((customTick.value - min) / (max - min)) * 100}%;`;
    }
  } else {
    tickStyle = `width: ${tickStyle} ${percentageWidth}%`;
  }

  return {
    style: tickStyle,
    customTick,
    label: customTick ? customTick.label : tickValue,
  };
}

export default helper(getRangeTick);
