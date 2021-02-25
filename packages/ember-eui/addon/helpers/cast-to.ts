import { helper } from '@ember/component/helper';

const NUMBER = 'number';
const BOOLEAN = 'boolean';
const STRING = 'string';

export function castTo(
  [that]: [string, unknown],
  { to = NUMBER }: { to: string }
): number | boolean | string {
  let toLower = to?.toLowerCase();

  switch (toLower) {
    case NUMBER:
      return Number(that);
    case STRING:
      return String(that);
    case BOOLEAN:
      return Boolean(that);
    default:
      return Number(that);
  }
}

export default helper(castTo);
