/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

const GROUP_NUMERIC = /^([\d.]+)(s|ms)/;

function getMilliseconds(value: string, unit: string): number {
  // Given the regex match and capture groups, we can assume `unit` to be either 's' or 'ms'
  const multiplier = unit === 's' ? 1000 : 1;

  return parseFloat(value) * multiplier;
}

// Find CSS `transition-duration` and `transition-delay` intervals
// and return the value of each computed property in 'ms'
export const getTransitionTimings = (
  element: Element
): { durationMatch: number; delayMatch: number } => {
  const computedStyle = window.getComputedStyle(element);

  const computedDuration = computedStyle.getPropertyValue(
    'transition-duration'
  );
  const durationMatchArray = computedDuration.match(GROUP_NUMERIC);
  const durationMatch = durationMatchArray
    ? getMilliseconds(durationMatchArray[1]!, durationMatchArray[2]!)
    : 0;

  const computedDelay = computedStyle.getPropertyValue('transition-delay');
  const delayMatchArray = computedDelay.match(GROUP_NUMERIC);
  const delayMatch = delayMatchArray
    ? getMilliseconds(delayMatchArray[1]!, delayMatchArray[2]!)
    : 0;

  return { durationMatch, delayMatch };
};

function isElementNode(element: Node): element is Element {
  return element.nodeType === document.ELEMENT_NODE;
}

// Uses `getTransitionTimings` to find the total transition time for
// all elements targeted by a MutationObserver callback
export const getWaitDuration = (records: MutationRecord[]): number => {
  return records.reduce((waitDuration, record) => {
    // only check for CSS transition values for ELEMENT nodes
    if (isElementNode(record.target)) {
      const { durationMatch, delayMatch } = getTransitionTimings(record.target);

      waitDuration = Math.max(waitDuration, durationMatch + delayMatch);
    }

    return waitDuration;
  }, 0);
};

// Uses `requestAnimationFrame` to perform a given callback after a specified waiting period
export const performOnFrame = (
  waitDuration: number,
  toPerform: () => void
): void => {
  if (waitDuration > 0) {
    const startTime = Date.now();
    const endTime = startTime + waitDuration;

    const onFrame = () => {
      toPerform();

      if (endTime > Date.now()) {
        requestAnimationFrame(onFrame);
      }
    };

    requestAnimationFrame(onFrame);
  }
};

// Convenience method for combining the result of 'getWaitDuration' directly with 'performOnFrame'
export const getDurationAndPerformOnFrame = (
  records: MutationRecord[],
  toPerform: () => void
): void => {
  performOnFrame(getWaitDuration(records), toPerform);
};
