import ArrayProxy from '@ember/array/proxy';
import { get } from '@ember/object';
import ObjectProxy from '@ember/object/proxy';

export function isProxy(o) {
  return !!(o && (o instanceof ObjectProxy || o instanceof ArrayProxy));
}

export function maybeUnwrapProxy(o) {
  const key = 'content';

  return isProxy(o) ? maybeUnwrapProxy(get(o, key)) : o;
}
