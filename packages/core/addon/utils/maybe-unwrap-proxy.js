import ArrayProxy from '@ember/array/proxy';
import ObjectProxy from '@ember/object/proxy';
import { get } from '@ember/object';

export function isProxy(o) {
  return !!(o && (o instanceof ObjectProxy || o instanceof ArrayProxy));
}

export function maybeUnwrapProxy(o) {
  const key = 'content';
  return isProxy(o) ? maybeUnwrapProxy(get(o, key)) : o;
}
