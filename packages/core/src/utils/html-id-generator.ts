/*
 * Ported from @elastic/eui 123.1.0 `services/accessibility/html_id_generator.ts`
 * (`htmlIdGenerator`; uuid v1 is replaced by a random id, and the dev-only
 * whitespace warning by `console.warn`).
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 */
import { randomId } from '../-private/random-id.ts';

const warned = new Set<string>();

/**
 * IDs containing whitespace are invalid HTML and silently break attributes
 * that reference several ids (`aria-controls`, `aria-labelledby`, `for`).
 */
const warnOnWhitespace = (value?: string) => {
  if (value && /\s/.test(value) && !warned.has(value)) {
    warned.add(value);
    console.warn(
      `[EUI] Generated HTML ID: "${value}" contains whitespace, which generates an invalid HTML id and breaks attributes referencing it, such as \`aria-controls\` or \`for\`. Pass a static identifier instead of a human-readable or localized string.`
    );
  }
};

/**
 * Returns a function that generates unique ids with an optional `prefix`
 * (the argument of this call) and `suffix` (the argument of the returned
 * function). Calls that pass a suffix share one unique part, so related ids
 * (`foo_abc_label`, `foo_abc_input`) can be generated together. A prefix
 * should begin with a letter to be HTML4 compliant; without one the id
 * starts with `i`.
 */
export function htmlIdGenerator(idPrefix: string = '') {
  const staticId = randomId();
  warnOnWhitespace(idPrefix);
  return (idSuffix: string = '') => {
    warnOnWhitespace(idSuffix);
    const prefix = `${idPrefix}${idPrefix !== '' ? '_' : 'i'}`;
    const suffix = idSuffix ? `_${idSuffix}` : '';
    return `${prefix}${suffix ? staticId : randomId()}${suffix}`;
  };
}

export default htmlIdGenerator;
