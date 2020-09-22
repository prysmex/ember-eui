import { helper } from '@ember/component/helper';
import { guidFor } from '@ember/object/internals';
import { isPresent } from '@ember/utils';

interface Identifiable {
  ref: number | string | Element | object;
};

function makeId (length = 8) {
  let result = '';
  const characters = 'abcdefghijklmnopqrstuvwxyz';
  const charactersLength = characters.length;

  for (let i = 0; i < length; i++) {
    result += characters.charAt(Math.floor(Math.random() * charactersLength));
  }

  return result;
}

/**
 * Returns a guid for the passed `ref`.
 * If no parameter was passed it will generate a random string and create a guid for it.
 *
 * @param { any } ref
 */
export function uniqueId ([], { ref }: { ref: Identifiable }): string {
  return isPresent(ref) ? guidFor(ref) : guidFor(makeId());
}

export default helper(uniqueId);
